-- Stage 1: player profiles (CLAUDE.md §3, §13).
-- One row per anonymous auth user: unique case-insensitive nickname + emoji icon.
-- Profiles are private by default: a player reads and edits only their own row.
-- Other players are found later (stage 2) through narrow RPCs that return nickname/emoji only,
-- so account IDs are never exposed.

create extension if not exists citext with schema extensions;

create table public.profiles (
    id uuid primary key references auth.users (id) on delete cascade,
    nickname extensions.citext not null,
    emoji text not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint profiles_nickname_key unique (nickname),
    -- Decided 2026-11-20: 3–20 Latin letters, digits, underscore or dot.
    constraint profiles_nickname_format check (nickname::text ~ '^[A-Za-z0-9_.]{3,20}$'),
    constraint profiles_emoji_length check (char_length(emoji) between 1 and 16)
);

comment on table public.profiles is 'Public player identity: unique nickname (case-insensitive) and emoji icon, linked to the anonymous auth user.';

alter table public.profiles enable row level security;

revoke all on table public.profiles from anon;

create policy "players read their own profile"
    on public.profiles for select to authenticated
    using ((select auth.uid()) = id);

create policy "players create their own profile"
    on public.profiles for insert to authenticated
    with check ((select auth.uid()) = id);

-- Nickname changes are allowed (CLAUDE.md §8.1); the unique constraint re-checks them.
create policy "players update their own profile"
    on public.profiles for update to authenticated
    using ((select auth.uid()) = id)
    with check ((select auth.uid()) = id);

-- No delete policy: there is no in-app account deletion (product decision 2026-11-19).

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

create trigger profiles_set_updated_at
    before update on public.profiles
    for each row execute function public.set_updated_at();

-- Availability check for onboarding / rename: answers yes or no only, never row data.
create function public.is_nickname_available(candidate text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select not exists (
        select 1 from public.profiles
        where nickname = candidate::extensions.citext
          and id is distinct from (select auth.uid())
    );
$$;

revoke execute on function public.is_nickname_available(text) from public, anon;
grant execute on function public.is_nickname_available(text) to authenticated;
