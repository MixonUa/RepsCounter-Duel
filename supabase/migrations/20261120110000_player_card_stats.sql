-- Player card and friends lists show real numbers (they were empty since stage 2):
-- * find_player → + stats {duels_won, duels_lost, duels_tied, total_duel_reps} (all-time,
--   completed duels) + weekly_rank (global place this week; null without reps this week)
-- * my_friends / player_friends rows → + weekly_rank ("Top 120").

create or replace function private.weekly_rank(player uuid)
returns int
language sql
stable
set search_path = ''
as $$
    select place::int from (
        select t.player, rank() over (order by t.total desc) as place
        from private.weekly_totals() t
    ) ranked
    where ranked.player = weekly_rank.player;
$$;

create or replace function private.public_stats(player uuid)
returns jsonb
language sql
stable
set search_path = ''
as $$
    select private.player_stats(player, 'squats') - 'training_record';
$$;

create or replace function public.find_player(player_nickname text)
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
        'stats', private.public_stats(target.id),
        'weekly_rank', private.weekly_rank(target.id),
        'recent_friends', coalesce((
            select jsonb_agg(jsonb_build_object('nickname', p.nickname::text, 'emoji', p.emoji) order by f.since desc)
            from (select * from private.friends_of(target.id) order by since desc limit 3) f
            join public.profiles p on p.id = f.friend_id
        ), '[]'::jsonb)
    );
end;
$$;

create or replace function public.player_friends(player_nickname text)
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
        select jsonb_agg(jsonb_build_object('nickname', p.nickname::text, 'emoji', p.emoji,
                                            'weekly_rank', private.weekly_rank(p.id)) order by f.since desc)
        from private.friends_of(target) f
        join public.profiles p on p.id = f.friend_id
    ), '[]'::jsonb);
end;
$$;

create or replace function public.my_friends()
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
            select jsonb_build_object('nickname', p.nickname::text, 'emoji', p.emoji, 'status', 'friend',
                                      'weekly_rank', private.weekly_rank(p.id)) as item,
                   0 as sort_group, f.since as sort_time
            from private.friends_of(me) f
            join public.profiles p on p.id = f.friend_id
            union all
            select jsonb_build_object('nickname', p.nickname::text, 'emoji', p.emoji, 'status', 'request_sent',
                                      'weekly_rank', private.weekly_rank(p.id)),
                   1, r.created_at
            from public.friend_requests r
            join public.profiles p on p.id = r.receiver_id
            where r.sender_id = me and r.status = 'pending'
        ) rows
    ), '[]'::jsonb);
end;
$$;
