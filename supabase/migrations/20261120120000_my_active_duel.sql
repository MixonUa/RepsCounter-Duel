-- Recovery after the app was closed mid-flow: the client asks for my unfinished duel on launch
-- and offers Resume / Leave, so a stuck duel no longer blocks new challenges ("busy").
-- Active = invited (not expired), lobby, countdown, live, or ended but not finalized (< 30 s).
create function public.my_active_duel()
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
    select * into d from public.duels
    where (host_id = me or guest_id = me)
      and state in ('invited', 'lobby', 'started')
      and (private.duel_phase(d) in ('lobby', 'countdown', 'live')
           or (private.duel_phase(d) = 'invited' and host_id = me)
           or (private.duel_phase(d) = 'finishing' and now() < d.ends_at + interval '30 seconds'))
    order by created_at desc
    limit 1;
    if not found then
        return null;
    end if;
    return private.duel_json(d, me);
end;
$$;

revoke execute on function public.my_active_duel() from public, anon;
grant execute on function public.my_active_duel() to authenticated;
