-- In the WHERE clause `d` resolved to the (empty) PL/pgSQL variable, not the row: use an alias.
create or replace function public.my_active_duel()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    me uuid := private.current_player();
    found_duel public.duels;
begin
    select x.* into found_duel from public.duels x
    where (x.host_id = me or x.guest_id = me)
      and x.state in ('invited', 'lobby', 'started')
      and (private.duel_phase(x) in ('lobby', 'countdown', 'live')
           or (private.duel_phase(x) = 'invited' and x.host_id = me)
           or (private.duel_phase(x) = 'finishing' and now() < x.ends_at + interval '30 seconds'))
    order by x.created_at desc
    limit 1;
    if not found then
        return null;
    end if;
    return private.duel_json(found_duel, me);
end;
$$;
