-- Stage 4: authoritative duel lifecycle on the server (CLAUDE.md §6). The server owns the
-- roster, exercise, duration, start / end timestamps and the accepted rep counts; clients poll
-- `duel_view` and submit reps one by one. Rating awards come in stage 5.
-- Stored states: invited → lobby → started → completed, plus declined / cancelled / expired /
-- forfeited. Time-derived phases (`private.duel_phase`): invited→expired after expires_at,
-- lobby→cancelled after 5 idle minutes, started→countdown / live / finishing by the clock.
-- PROVISIONAL constants (CLAUDE.md §11): 3 min invite expiry, 4 s countdown, 2 s rep grace after
-- the end, 0.4 s minimum between reps, 5 min lobby idle, 20 invitations an hour.

create table public.duels (
    id uuid primary key default gen_random_uuid(),
    host_id uuid not null references public.profiles (id) on delete cascade,
    guest_id uuid not null references public.profiles (id) on delete cascade,
    exercise text not null check (exercise in ('squats', 'push_ups')),
    duration_seconds int not null
        check (duration_seconds between 10 and 600 and duration_seconds % 10 = 0),
    state text not null default 'invited'
        check (state in ('invited', 'declined', 'cancelled', 'expired', 'lobby', 'started', 'completed', 'forfeited')),
    created_at timestamptz not null default now(),
    expires_at timestamptz not null default now() + interval '3 minutes',
    accepted_at timestamptz,
    host_ready boolean not null default false,
    guest_ready boolean not null default false,
    starts_at timestamptz,
    ends_at timestamptz,
    host_reps int not null default 0,
    guest_reps int not null default 0,
    host_last_seq int not null default 0,
    guest_last_seq int not null default 0,
    host_last_rep_at timestamptz,
    guest_last_rep_at timestamptz,
    forfeited_by uuid references public.profiles (id) on delete set null,
    finished_at timestamptz,
    constraint duels_two_players check (host_id <> guest_id)
);

create index duels_host on public.duels (host_id, created_at desc);
create index duels_guest on public.duels (guest_id, created_at desc);

alter table public.duels enable row level security;
revoke all on table public.duels from anon, authenticated;

-- ---------------------------------------------------------------------------------------------
-- Private helpers.

create function private.duel_phase(d public.duels)
returns text
language sql
stable
set search_path = ''
as $$
    select case d.state
        when 'invited' then case when now() >= d.expires_at then 'expired' else 'invited' end
        when 'lobby' then case when now() >= d.accepted_at + interval '5 minutes' then 'cancelled' else 'lobby' end
        when 'started' then case
            when now() < d.starts_at then 'countdown'
            when now() < d.ends_at then 'live'
            else 'finishing'
        end
        else d.state
    end;
$$;

-- Is the player in a duel that is still going on (invited, lobby, countdown, live, or just ended
-- and not finalized for less than 30 s)?
create function private.has_active_duel(player uuid)
returns boolean
language sql
stable
set search_path = ''
as $$
    select exists (
        select 1 from public.duels d
        where (d.host_id = player or d.guest_id = player)
          and d.state in ('invited', 'lobby', 'started')
          and (private.duel_phase(d) in ('invited', 'lobby', 'countdown', 'live')
               or (private.duel_phase(d) = 'finishing' and now() < d.ends_at + interval '30 seconds'))
    );
$$;

create function private.player_json(player uuid)
returns jsonb
language sql
stable
set search_path = ''
as $$
    select jsonb_build_object('nickname', nickname::text, 'emoji', emoji)
    from public.profiles where id = player;
$$;

-- The duel as one participant sees it. Never contains account IDs.
create function private.duel_json(d public.duels, me uuid)
returns jsonb
language sql
stable
set search_path = ''
as $$
    select jsonb_build_object(
        'id', d.id,
        'phase', private.duel_phase(d),
        'role', case when d.host_id = me then 'host' else 'guest' end,
        'opponent', private.player_json(case when d.host_id = me then d.guest_id else d.host_id end),
        'exercise', d.exercise,
        'duration_seconds', d.duration_seconds,
        'expires_at', d.expires_at,
        'my_ready', case when d.host_id = me then d.host_ready else d.guest_ready end,
        'opponent_ready', case when d.host_id = me then d.guest_ready else d.host_ready end,
        'starts_at', d.starts_at,
        'ends_at', d.ends_at,
        'my_reps', case when d.host_id = me then d.host_reps else d.guest_reps end,
        'opponent_reps', case when d.host_id = me then d.guest_reps else d.host_reps end,
        'forfeited_by_me', d.forfeited_by is not null and d.forfeited_by = me,
        'server_now', now()
    );
$$;

-- Locks the duel for a change and checks I am in it.
create function private.my_duel_for_update(duel uuid, me uuid)
returns public.duels
language plpgsql
set search_path = ''
as $$
declare
    d public.duels;
begin
    select * into d from public.duels where id = duel and (host_id = me or guest_id = me) for update;
    if not found then
        raise exception 'duel_not_found' using errcode = 'P0002';
    end if;
    return d;
end;
$$;

-- ---------------------------------------------------------------------------------------------
-- Public RPCs (authenticated players with a profile).

-- Host invites an accepted friend. Errors: player_not_found (P0002), not_friends (42501),
-- busy (55000: either player already in a duel), rate_limited (P0001).
create function public.create_duel(friend_nickname text, exercise text, duration_seconds int)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    me uuid := private.current_player();
    friend uuid := private.player_id(friend_nickname);
    d public.duels;
begin
    if friend is null or friend = me then
        raise exception 'player_not_found' using errcode = 'P0002';
    end if;
    if private.relationship(me, friend) <> 'friends' then
        raise exception 'not_friends' using errcode = '42501';
    end if;
    -- Serialize per player so two invitations can't slip through at once.
    perform pg_advisory_xact_lock(hashtextextended(least(me, friend)::text, 0));
    perform pg_advisory_xact_lock(hashtextextended(greatest(me, friend)::text, 0));
    if private.has_active_duel(me) or private.has_active_duel(friend) then
        raise exception 'busy' using errcode = '55000';
    end if;
    if (select count(*) from public.duels where host_id = me and created_at > now() - interval '1 hour') >= 20 then
        raise exception 'rate_limited' using errcode = 'P0001';
    end if;
    insert into public.duels (host_id, guest_id, exercise, duration_seconds)
    values (me, friend, create_duel.exercise, create_duel.duration_seconds)
    returning * into d;
    return private.duel_json(d, me);
end;
$$;

-- Invitations waiting for my answer (not expired), oldest first.
create function public.incoming_duel_invitations()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    me uuid := private.current_player();
begin
    return coalesce((
        select jsonb_agg(private.duel_json(d, me) order by d.created_at)
        from public.duels d
        where d.guest_id = me and d.state = 'invited' and now() < d.expires_at
    ), '[]'::jsonb);
end;
$$;

-- My duel as I see it; null if it isn't mine.
create function public.duel_view(duel uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    me uuid := private.current_player();
    d public.duels;
begin
    select * into d from public.duels where id = duel and (host_id = me or guest_id = me);
    if not found then
        return null;
    end if;
    return private.duel_json(d, me);
end;
$$;

-- Invitee answers. Errors: duel_not_found, not_invitee (42501), expired / not_pending (55000),
-- busy (55000).
create function public.respond_to_duel(duel uuid, accept boolean)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    me uuid := private.current_player();
    d public.duels := private.my_duel_for_update(duel, me);
begin
    if d.guest_id <> me then
        raise exception 'not_invitee' using errcode = '42501';
    end if;
    if private.duel_phase(d) = 'expired' then
        raise exception 'expired' using errcode = '55000';
    end if;
    if d.state <> 'invited' then
        raise exception 'not_pending' using errcode = '55000';
    end if;
    if not accept then
        update public.duels set state = 'declined', finished_at = now() where id = d.id returning * into d;
        return private.duel_json(d, me);
    end if;
    perform pg_advisory_xact_lock(hashtextextended(me::text, 0));
    if exists (select 1 from public.duels o
               where o.id <> d.id and (o.host_id = me or o.guest_id = me)
                 and o.state in ('lobby', 'started')
                 and private.duel_phase(o) in ('lobby', 'countdown', 'live')) then
        raise exception 'busy' using errcode = '55000';
    end if;
    update public.duels set state = 'lobby', accepted_at = now() where id = d.id returning * into d;
    return private.duel_json(d, me);
end;
$$;

-- "I'm Ready". When both are ready the server fixes starts_at (now + 4 s countdown) and ends_at.
create function public.set_duel_ready(duel uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    me uuid := private.current_player();
    d public.duels := private.my_duel_for_update(duel, me);
begin
    if private.duel_phase(d) <> 'lobby' then
        return private.duel_json(d, me);
    end if;
    if d.host_id = me then
        update public.duels set host_ready = true where id = d.id returning * into d;
    else
        update public.duels set guest_ready = true where id = d.id returning * into d;
    end if;
    if d.host_ready and d.guest_ready then
        update public.duels
        set state = 'started',
            starts_at = now() + interval '4 seconds',
            ends_at = now() + interval '4 seconds' + make_interval(secs => d.duration_seconds)
        where id = d.id
        returning * into d;
    end if;
    return private.duel_json(d, me);
end;
$$;

-- One completed rep, numbered 1, 2, 3… per player. Idempotent for already-seen numbers.
-- Accepted only during [starts_at, ends_at + 2 s) and at least 0.4 s after my previous rep.
-- Returns the duel view (my_reps is the authoritative count).
create function public.submit_duel_rep(duel uuid, seq int)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    me uuid := private.current_player();
    d public.duels := private.my_duel_for_update(duel, me);
    is_host boolean := d.host_id = me;
    last_seq int := case when is_host then d.host_last_seq else d.guest_last_seq end;
    last_at timestamptz := case when is_host then d.host_last_rep_at else d.guest_last_rep_at end;
begin
    if d.state <> 'started' or now() < d.starts_at or now() >= d.ends_at + interval '2 seconds' then
        return private.duel_json(d, me);
    end if;
    if seq <= last_seq or seq <> last_seq + 1 then
        -- Duplicate or out of order: ignored (the client resyncs from my_reps).
        return private.duel_json(d, me);
    end if;
    if last_at is not null and now() - last_at < interval '400 milliseconds' then
        return private.duel_json(d, me);
    end if;
    if is_host then
        update public.duels set host_reps = host_reps + 1, host_last_seq = seq, host_last_rep_at = now()
        where id = d.id returning * into d;
    else
        update public.duels set guest_reps = guest_reps + 1, guest_last_seq = seq, guest_last_rep_at = now()
        where id = d.id returning * into d;
    end if;
    return private.duel_json(d, me);
end;
$$;

-- After the end (+ 2 s grace) either player finalizes; idempotent. Returns the final view.
create function public.finish_duel(duel uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    me uuid := private.current_player();
    d public.duels := private.my_duel_for_update(duel, me);
begin
    if d.state = 'started' and now() >= d.ends_at + interval '2 seconds' then
        update public.duels set state = 'completed', finished_at = now() where id = d.id returning * into d;
    end if;
    return private.duel_json(d, me);
end;
$$;

-- Leave: host before acceptance → cancelled; invitee before acceptance → declined; lobby or
-- countdown → cancelled; live → forfeited (no rating reps for anyone, CLAUDE.md §6).
create function public.leave_duel(duel uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    me uuid := private.current_player();
    d public.duels := private.my_duel_for_update(duel, me);
    phase text := private.duel_phase(d);
begin
    if phase = 'invited' then
        update public.duels
        set state = case when d.host_id = me then 'cancelled' else 'declined' end, finished_at = now()
        where id = d.id returning * into d;
    elsif phase in ('lobby', 'countdown') then
        update public.duels set state = 'cancelled', finished_at = now() where id = d.id returning * into d;
    elsif phase = 'live' then
        update public.duels set state = 'forfeited', forfeited_by = me, finished_at = now()
        where id = d.id returning * into d;
    end if;
    return private.duel_json(d, me);
end;
$$;

do $$
declare
    fn text;
begin
    foreach fn in array array[
        'public.create_duel(text, text, int)', 'public.incoming_duel_invitations()',
        'public.duel_view(uuid)', 'public.respond_to_duel(uuid, boolean)',
        'public.set_duel_ready(uuid)', 'public.submit_duel_rep(uuid, int)',
        'public.finish_duel(uuid)', 'public.leave_duel(uuid)'
    ] loop
        execute format('revoke execute on function %s from public, anon', fn);
        execute format('grant execute on function %s to authenticated', fn);
    end loop;
end;
$$;
