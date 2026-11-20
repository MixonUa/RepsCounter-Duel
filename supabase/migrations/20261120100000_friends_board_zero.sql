-- Friends board shows me and every accepted friend, with 0 when there are no reps this week
-- (decided 2026-11-20). The global board still lists only players with reps this week.
create or replace function public.weekly_leaderboard(scope text, max_entries int default 100)
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
        union all
        select f.player, coalesce(t.total, 0)
        from (select me as player union select friend_id from private.friends_of(me)) f
        left join private.weekly_totals() t on t.player = f.player
        where scope = 'friends'
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
