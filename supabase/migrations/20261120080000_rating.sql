-- Stage 5: weekly rating, duel history and profile numbers (CLAUDE.md §2, §7).
-- Everything is derived from completed duels (the immutable audit source), so a result can never
-- be awarded twice. Forfeited / cancelled / unfinished duels never count.
-- The rating week starts Monday 00:00 UTC for everyone. Players with 0 reps this week have no place.
-- Equal totals share the displayed rank; ordering inside a rank is by nickname (not a tiebreak).

create function private.week_start()
returns timestamptz
language sql
stable
set search_path = ''
as $$
    select date_trunc('week', now() at time zone 'utc') at time zone 'utc';
$$;

-- This week's accepted duel reps per player (only players with > 0).
create function private.weekly_totals()
returns table (player uuid, total bigint)
language sql
stable
set search_path = ''
as $$
    select player, sum(reps) as total
    from (
        select host_id as player, host_reps as reps from public.duels
        where state = 'completed' and finished_at >= private.week_start()
        union all
        select guest_id, guest_reps from public.duels
        where state = 'completed' and finished_at >= private.week_start()
    ) rows
    group by player
    having sum(reps) > 0;
$$;

-- { week_start, entries: [{nickname, emoji, total, rank, is_me}] (top `max_entries`),
--   me: {total, rank} | null }. scope: 'global' | 'friends' (me + my accepted friends).
create function public.weekly_leaderboard(scope text, max_entries int default 100)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    me uuid := private.current_player();
    result jsonb;
begin
    if scope not in ('global', 'friends') then
        raise exception 'invalid_scope' using errcode = '22023';
    end if;
    with board as (
        select t.player, t.total
        from private.weekly_totals() t
        where scope = 'global'
           or t.player = me
           or t.player in (select friend_id from private.friends_of(me))
    ),
    ranked as (
        select b.player, b.total, p.nickname::text as nickname, p.emoji,
               rank() over (order by b.total desc) as place,
               row_number() over (order by b.total desc, lower(p.nickname::text), p.id) as position
        from board b
        join public.profiles p on p.id = b.player
    )
    select jsonb_build_object(
        'week_start', private.week_start(),
        'entries', coalesce((
            select jsonb_agg(jsonb_build_object(
                'nickname', r.nickname, 'emoji', r.emoji, 'total', r.total, 'rank', r.place,
                'is_me', r.player = me) order by r.position)
            from ranked r where r.position <= greatest(1, least(max_entries, 500))
        ), '[]'::jsonb),
        'me', (select jsonb_build_object('total', r.total, 'rank', r.place) from ranked r where r.player = me)
    ) into result;
    return result;
end;
$$;

-- My completed duels since `since`, newest first (Home chart, last duel, history).
create function public.my_duel_history(since timestamptz, max_entries int default 50)
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
        select jsonb_agg(item order by finished desc)
        from (
            select d.finished_at as finished, jsonb_build_object(
                'id', d.id,
                'opponent', private.player_json(case when d.host_id = me then d.guest_id else d.host_id end),
                'exercise', d.exercise,
                'duration_seconds', d.duration_seconds,
                'my_reps', case when d.host_id = me then d.host_reps else d.guest_reps end,
                'opponent_reps', case when d.host_id = me then d.guest_reps else d.host_reps end,
                'finished_at', d.finished_at
            ) as item
            from public.duels d
            where (d.host_id = me or d.guest_id = me) and d.state = 'completed' and d.finished_at >= since
            order by d.finished_at desc
            limit greatest(1, least(max_entries, 200))
        ) rows
    ), '[]'::jsonb);
end;
$$;

-- All-time numbers for my Profile: {duels_won, duels_lost, duels_tied, total_duel_reps, training_record}.
create function public.my_stats()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    me uuid := private.current_player();
begin
    return private.player_stats(me, 'squats');
end;
$$;

-- Profile "Top Friends": my 3 friends with the most duel reps this week, with their own
-- all-time win rate ("joint reps" = the friend's combined push-ups + squats this week).
-- [{nickname, emoji, weekly_total, duels_won, duels_lost, duels_tied}]
create function public.top_friends_this_week()
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
        select jsonb_agg(item order by weekly desc, name)
        from (
            select coalesce(t.total, 0) as weekly, lower(p.nickname::text) as name,
                   jsonb_build_object('nickname', p.nickname::text, 'emoji', p.emoji, 'weekly_total', coalesce(t.total, 0))
                   || (private.player_stats(f.friend_id, 'squats') - 'training_record' - 'total_duel_reps') as item
            from private.friends_of(me) f
            join public.profiles p on p.id = f.friend_id
            left join private.weekly_totals() t on t.player = f.friend_id
            order by coalesce(t.total, 0) desc, lower(p.nickname::text)
            limit 3
        ) rows
    ), '[]'::jsonb);
end;
$$;

do $$
declare
    fn text;
begin
    foreach fn in array array[
        'public.weekly_leaderboard(text, int)', 'public.my_duel_history(timestamptz, int)',
        'public.my_stats()', 'public.top_friends_this_week()'
    ] loop
        execute format('revoke execute on function %s from public, anon', fn);
        execute format('grant execute on function %s to authenticated', fn);
    end loop;
end;
$$;
