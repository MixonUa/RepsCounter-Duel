-- `on conflict (player_id, exercise)` was ambiguous with the `exercise` parameter: name the
-- primary key constraint instead.
create or replace function public.save_training_record(exercise text, reps int)
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
    insert into public.training_records as r (player_id, exercise, best_reps)
    values (me, save_training_record.exercise, reps)
    on conflict on constraint training_records_pkey do update
        set best_reps = greatest(r.best_reps, excluded.best_reps),
            updated_at = case when excluded.best_reps > r.best_reps then now() else r.updated_at end
    returning r.best_reps into stored;
    return stored;
end;
$$;
