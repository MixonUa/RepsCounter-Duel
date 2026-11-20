-- With `search_path = ''` the bare `=` resolved to the text operator, so the availability check
-- was case-sensitive (the unique index itself was fine). Use citext's operator explicitly.
create or replace function public.is_nickname_available(candidate text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select not exists (
        select 1 from public.profiles
        where nickname operator(extensions.=) candidate::extensions.citext
          and id is distinct from (select auth.uid())
    );
$$;

revoke execute on function public.is_nickname_available(text) from public, anon;
grant execute on function public.is_nickname_available(text) to authenticated;
