-- Stage 4 hardening: connection loss during a duel (CLAUDE.md §6 "Connection loss").
-- Each player sends a heartbeat (`duel_heartbeat`, also implied by `submit_duel_rep`) about every
-- second while the duel runs. If a player is silent for longer than the reconnect grace
-- (PROVISIONAL 10 s) inside the live window, the duel is `interrupted`: nobody wins and no rating
-- reps are awarded (rating only counts `completed`). No timer pause.

alter table public.duels add column host_seen_at timestamptz;
alter table public.duels add column guest_seen_at timestamptz;

alter table public.duels drop constraint duels_state_check;
alter table public.duels add constraint duels_state_check
    check (state in ('invited', 'declined', 'cancelled', 'expired', 'lobby', 'started', 'completed', 'forfeited', 'interrupted'));

create or replace function private.reconnect_grace()
returns interval
language sql
immutable
set search_path = ''
as $$ select interval '10 seconds' $$;

-- A player was silent longer than the grace somewhere between the start and now (or the end).
create or replace function private.duel_connection_lost(d public.duels)
returns boolean
language sql
stable
set search_path = ''
as $$
    select d.starts_at is not null
       and now() >= d.starts_at + private.reconnect_grace()
       and least(coalesce(d.host_seen_at, d.starts_at), coalesce(d.guest_seen_at, d.starts_at))
           < least(now(), d.ends_at) - private.reconnect_grace();
$$;

create or replace function private.duel_phase(d public.duels)
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
            when private.duel_connection_lost(d) then 'interrupted'
            when now() < d.ends_at then 'live'
            else 'finishing'
        end
        else d.state
    end;
$$;

-- "I'm still here" during the lobby, countdown and live phases. Returns the duel view.
create function public.duel_heartbeat(duel uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    me uuid := private.current_player();
    d public.duels := private.my_duel_for_update(duel, me);
begin
    if private.duel_phase(d) in ('lobby', 'countdown', 'live', 'finishing') then
        if d.host_id = me then
            update public.duels set host_seen_at = now() where id = d.id returning * into d;
        else
            update public.duels set guest_seen_at = now() where id = d.id returning * into d;
        end if;
    end if;
    return private.duel_json(d, me);
end;
$$;

revoke execute on function public.duel_heartbeat(uuid) from public, anon;
grant execute on function public.duel_heartbeat(uuid) to authenticated;

-- Reps: also a heartbeat; refused once the duel is interrupted.
create or replace function public.submit_duel_rep(duel uuid, seq int)
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
    if d.state <> 'started' or now() < d.starts_at or now() >= d.ends_at + interval '2 seconds'
       or private.duel_phase(d) = 'interrupted' then
        return private.duel_json(d, me);
    end if;
    if is_host then
        update public.duels set host_seen_at = now() where id = d.id returning * into d;
    else
        update public.duels set guest_seen_at = now() where id = d.id returning * into d;
    end if;
    if seq <= last_seq or seq <> last_seq + 1 then
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

-- Finalize: interrupted duels are stored as such (no rating), the rest as completed.
create or replace function public.finish_duel(duel uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    me uuid := private.current_player();
    d public.duels := private.my_duel_for_update(duel, me);
begin
    if d.state = 'started' and private.duel_phase(d) = 'interrupted' then
        update public.duels set state = 'interrupted', finished_at = now() where id = d.id returning * into d;
    elsif d.state = 'started' and now() >= d.ends_at + interval '2 seconds' then
        update public.duels set state = 'completed', finished_at = now() where id = d.id returning * into d;
    end if;
    return private.duel_json(d, me);
end;
$$;

-- Both players are marked present when the countdown is fixed.
create or replace function public.set_duel_ready(duel uuid)
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
        update public.duels set host_ready = true, host_seen_at = now() where id = d.id returning * into d;
    else
        update public.duels set guest_ready = true, guest_seen_at = now() where id = d.id returning * into d;
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
