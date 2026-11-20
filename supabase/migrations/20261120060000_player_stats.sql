-- Real numbers for the "Ready to duel?" HEAD TO HEAD and the results card.
-- * training_records: best single training session per exercise, synced from the phone (the
--   phone keeps the source of truth offline; the server keeps the greatest value it has seen).
--   CLAUDE.md §2: training never affects ratings — this is only shown as "PR".
-- * Duel statistics are derived from completed duels (wins / losses / draws / total reps).
--   Forfeited, cancelled and unfinished duels don't count (rating policy is stage 5).

create table public.training_records (
    player_id uuid not null references public.profiles (id) on delete cascade,
    exercise text not null check (exercise in ('squats', 'push_ups')),
    best_reps int not null check (best_reps between 0 and 10000),
    updated_at timestamptz not null default now(),
    primary key (player_id, exercise)
);

alter table public.training_records enable row level security;
revoke all on table public.training_records from anon, authenticated;

create function private.player_stats(player uuid, exercise text)
returns jsonb
language sql
stable
set search_path = ''
as $$
    with mine as (
        select
            case when d.host_id = player then d.host_reps else d.guest_reps end as my_reps,
            case when d.host_id = player then d.guest_reps else d.host_reps end as their_reps
        from public.duels d
        where (d.host_id = player or d.guest_id = player) and d.state = 'completed'
    )
    select jsonb_build_object(
        'duels_won', (select count(*) from mine where my_reps > their_reps),
        'duels_lost', (select count(*) from mine where my_reps < their_reps),
        'duels_tied', (select count(*) from mine where my_reps = their_reps),
        'total_duel_reps', coalesce((select sum(my_reps) from mine), 0),
        'training_record', coalesce((
            select best_reps from public.training_records r
            where r.player_id = player and r.exercise = player_stats.exercise
        ), 0)
    );
$$;

-- Keeps the greatest record (a stale phone can't lower it). Returns the stored value.
create function public.save_training_record(exercise text, reps int)
returns int
language plpgsql
security definer
set search_path = ''
as $$
declare
    me uuid := private.current_player();
    stored int;
begin
    if exercise not in ('squats', 'push_ups') or reps < 0 or reps > 10000 then
        raise exception 'invalid_record' using errcode = '22023';
    end if;
    insert into public.training_records (player_id, exercise, best_reps)
    values (me, save_training_record.exercise, reps)
    on conflict (player_id, exercise) do update
        set best_reps = greatest(public.training_records.best_reps, excluded.best_reps),
            updated_at = case when excluded.best_reps > public.training_records.best_reps then now()
                              else public.training_records.updated_at end
    returning best_reps into stored;
    return stored;
end;
$$;

-- Both participants' stats for the duel's exercise: { me: {...}, opponent: {...} }; null if the
-- duel isn't mine.
create function public.duel_head_to_head(duel uuid)
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
    return jsonb_build_object(
        'me', private.player_stats(me, d.exercise),
        'opponent', private.player_stats(case when d.host_id = me then d.guest_id else d.host_id end, d.exercise)
    );
end;
$$;

revoke execute on function public.save_training_record(text, int) from public, anon;
grant execute on function public.save_training_record(text, int) to authenticated;
revoke execute on function public.duel_head_to_head(uuid) from public, anon;
grant execute on function public.duel_head_to_head(uuid) to authenticated;
