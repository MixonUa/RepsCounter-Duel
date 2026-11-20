-- Stage 2: friend requests and friendships (CLAUDE.md §6 "Friends and invitations", §13).
-- Clients never touch these tables directly (no grants, RLS on without policies): everything goes
-- through SECURITY DEFINER RPCs below that identify players by nickname and return only public
-- data (nickname, emoji, relationship) — account IDs never leave the database.

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table public.friend_requests (
    id uuid primary key default gen_random_uuid(),
    sender_id uuid not null references public.profiles (id) on delete cascade,
    receiver_id uuid not null references public.profiles (id) on delete cascade,
    status text not null default 'pending'
        check (status in ('pending', 'accepted', 'declined', 'cancelled')),
    created_at timestamptz not null default now(),
    responded_at timestamptz,
    constraint friend_requests_not_self check (sender_id <> receiver_id)
);

-- At most one pending request per pair, whichever direction.
create unique index friend_requests_one_pending_per_pair
    on public.friend_requests (least(sender_id, receiver_id), greatest(sender_id, receiver_id))
    where status = 'pending';
create index friend_requests_receiver_pending on public.friend_requests (receiver_id) where status = 'pending';
create index friend_requests_sender_created on public.friend_requests (sender_id, created_at);

create table public.friendships (
    user_a uuid not null references public.profiles (id) on delete cascade,
    user_b uuid not null references public.profiles (id) on delete cascade,
    created_at timestamptz not null default now(),
    primary key (user_a, user_b),
    constraint friendships_ordered check (user_a < user_b)
);
create index friendships_user_b on public.friendships (user_b);

alter table public.friend_requests enable row level security;
alter table public.friendships enable row level security;
revoke all on table public.friend_requests from anon, authenticated;
revoke all on table public.friendships from anon, authenticated;

-- ---------------------------------------------------------------------------------------------
-- Private helpers (not exposed through the API).

create function private.current_player()
returns uuid
language plpgsql
stable
set search_path = ''
as $$
declare
    me uuid := (select auth.uid());
begin
    if me is null or not exists (select 1 from public.profiles where id = me) then
        raise exception 'not_registered' using errcode = '42501';
    end if;
    return me;
end;
$$;

create function private.player_id(player_nickname text)
returns uuid
language sql
stable
set search_path = ''
as $$
    select id from public.profiles
    where nickname operator(extensions.=) player_nickname::extensions.citext;
$$;

create function private.relationship(me uuid, other uuid)
returns text
language sql
stable
set search_path = ''
as $$
    select case
        when me = other then 'self'
        when exists (select 1 from public.friendships
                     where user_a = least(me, other) and user_b = greatest(me, other)) then 'friends'
        when exists (select 1 from public.friend_requests
                     where sender_id = me and receiver_id = other and status = 'pending') then 'request_sent'
        when exists (select 1 from public.friend_requests
                     where sender_id = other and receiver_id = me and status = 'pending') then 'request_received'
        else 'none'
    end;
$$;

-- Friends of a player with the time the friendship started.
create function private.friends_of(player uuid)
returns table (friend_id uuid, since timestamptz)
language sql
stable
set search_path = ''
as $$
    select case when user_a = player then user_b else user_a end, created_at
    from public.friendships
    where user_a = player or user_b = player;
$$;

-- Accepts a pending request (inside the caller's transaction).
create function private.accept_request(request_id uuid, sender uuid, receiver uuid)
returns void
language sql
set search_path = ''
as $$
    update public.friend_requests set status = 'accepted', responded_at = now() where id = request_id;
    insert into public.friendships (user_a, user_b)
    values (least(sender, receiver), greatest(sender, receiver))
    on conflict do nothing;
$$;

-- PROVISIONAL anti-abuse limit (CLAUDE.md §6: rate-limit friend requests).
create function private.friend_request_daily_limit()
returns int
language sql
immutable
as $$ select 50 $$;

-- ---------------------------------------------------------------------------------------------
-- Public RPCs (authenticated players only).

-- Exact, case-insensitive lookup. Returns null when nobody has the nickname.
-- { nickname, emoji, relationship: self|friends|request_sent|request_received|none,
--   recent_friends: [{nickname, emoji}] (3 newest; public by product decision) }
create function public.find_player(player_nickname text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    me uuid := private.current_player();
    target public.profiles;
begin
    select * into target from public.profiles
    where nickname operator(extensions.=) player_nickname::extensions.citext;
    if not found then
        return null;
    end if;
    return jsonb_build_object(
        'nickname', target.nickname::text,
        'emoji', target.emoji,
        'relationship', private.relationship(me, target.id),
        'recent_friends', coalesce((
            select jsonb_agg(jsonb_build_object('nickname', p.nickname::text, 'emoji', p.emoji) order by f.since desc)
            from (select * from private.friends_of(target.id) order by since desc limit 3) f
            join public.profiles p on p.id = f.friend_id
        ), '[]'::jsonb)
    );
end;
$$;

-- All friends of a player (player card → see all), newest first.
create function public.player_friends(player_nickname text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    me uuid := private.current_player();
    target uuid := private.player_id(player_nickname);
begin
    if target is null then
        return '[]'::jsonb;
    end if;
    return coalesce((
        select jsonb_agg(jsonb_build_object('nickname', p.nickname::text, 'emoji', p.emoji) order by f.since desc)
        from private.friends_of(target) f
        join public.profiles p on p.id = f.friend_id
    ), '[]'::jsonb);
end;
$$;

-- My list: accepted friends (newest first), then my pending sent requests.
-- [{ nickname, emoji, status: friend|request_sent }]
create function public.my_friends()
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
        select jsonb_agg(item order by sort_group, sort_time desc)
        from (
            select jsonb_build_object('nickname', p.nickname::text, 'emoji', p.emoji, 'status', 'friend') as item,
                   0 as sort_group, f.since as sort_time
            from private.friends_of(me) f
            join public.profiles p on p.id = f.friend_id
            union all
            select jsonb_build_object('nickname', p.nickname::text, 'emoji', p.emoji, 'status', 'request_sent'),
                   1, r.created_at
            from public.friend_requests r
            join public.profiles p on p.id = r.receiver_id
            where r.sender_id = me and r.status = 'pending'
        ) rows
    ), '[]'::jsonb);
end;
$$;

-- Requests waiting for my answer, oldest first. [{ nickname, emoji }]
create function public.incoming_friend_requests()
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
        select jsonb_agg(jsonb_build_object('nickname', p.nickname::text, 'emoji', p.emoji) order by r.created_at)
        from public.friend_requests r
        join public.profiles p on p.id = r.sender_id
        where r.receiver_id = me and r.status = 'pending'
    ), '[]'::jsonb);
end;
$$;

-- Result: sent | already_sent | already_friends | accepted (they had already asked me).
-- Errors: player_not_found (P0002), cannot_add_self (22023), rate_limited (P0001).
create function public.send_friend_request(player_nickname text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
    me uuid := private.current_player();
    target uuid := private.player_id(player_nickname);
    incoming public.friend_requests;
begin
    if target is null then
        raise exception 'player_not_found' using errcode = 'P0002';
    end if;
    if target = me then
        raise exception 'cannot_add_self' using errcode = '22023';
    end if;
    case private.relationship(me, target)
        when 'friends' then return 'already_friends';
        when 'request_sent' then return 'already_sent';
        when 'request_received' then
            select * into incoming from public.friend_requests
            where sender_id = target and receiver_id = me and status = 'pending'
            for update;
            perform private.accept_request(incoming.id, target, me);
            return 'accepted';
        else null;
    end case;
    if (select count(*) from public.friend_requests
        where sender_id = me and created_at > now() - interval '1 day') >= private.friend_request_daily_limit() then
        raise exception 'rate_limited' using errcode = 'P0001';
    end if;
    begin
        insert into public.friend_requests (sender_id, receiver_id) values (me, target);
    exception when unique_violation then
        return 'already_sent';
    end;
    return 'sent';
end;
$$;

-- Result: accepted | declined | not_found (no pending request from that player).
create function public.respond_to_friend_request(player_nickname text, accept boolean)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
    me uuid := private.current_player();
    sender uuid := private.player_id(player_nickname);
    request public.friend_requests;
begin
    select * into request from public.friend_requests
    where sender_id = sender and receiver_id = me and status = 'pending'
    for update;
    if not found then
        return 'not_found';
    end if;
    if accept then
        perform private.accept_request(request.id, sender, me);
        return 'accepted';
    end if;
    update public.friend_requests set status = 'declined', responded_at = now() where id = request.id;
    return 'declined';
end;
$$;

-- Result: cancelled | not_found.
create function public.cancel_friend_request(player_nickname text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
    me uuid := private.current_player();
    receiver uuid := private.player_id(player_nickname);
begin
    update public.friend_requests set status = 'cancelled', responded_at = now()
    where sender_id = me and receiver_id = receiver and status = 'pending';
    return case when found then 'cancelled' else 'not_found' end;
end;
$$;

-- Unfriend. Result: removed | not_found.
create function public.remove_friend(player_nickname text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
    me uuid := private.current_player();
    other uuid := private.player_id(player_nickname);
begin
    delete from public.friendships where user_a = least(me, other) and user_b = greatest(me, other);
    return case when found then 'removed' else 'not_found' end;
end;
$$;

do $$
declare
    fn text;
begin
    foreach fn in array array[
        'public.find_player(text)', 'public.player_friends(text)', 'public.my_friends()',
        'public.incoming_friend_requests()', 'public.send_friend_request(text)',
        'public.respond_to_friend_request(text, boolean)', 'public.cancel_friend_request(text)',
        'public.remove_friend(text)'
    ] loop
        execute format('revoke execute on function %s from public, anon', fn);
        execute format('grant execute on function %s to authenticated', fn);
    end loop;
end;
$$;
