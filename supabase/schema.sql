-- HabitBank schema
-- Run this in the Supabase SQL editor.
-- All times are stored as `timestamptz`. Week boundaries are computed in UTC.

create extension if not exists "pgcrypto";

-- =========================================================================
-- profiles (mirrors auth.users)
-- =========================================================================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null default '',
  email text,
  photo_url text,
  created_at timestamptz not null default now()
);

-- =========================================================================
-- groups
-- =========================================================================
create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_id uuid not null references public.profiles(id) on delete cascade,
  invite_code text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists public.group_members (
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

create index if not exists group_members_user_idx on public.group_members(user_id);

-- =========================================================================
-- challenges (one per group; the same goal applies to every member)
-- =========================================================================
create table if not exists public.challenges (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null unique references public.groups(id) on delete cascade,
  goal_type text not null check (goal_type in ('workouts', 'minutes')),
  goal_target int not null check (goal_target > 0),
  -- Per-user weekly stake, stored in cents (e.g. 100 = $1.00).
  stake_cents int not null default 100 check (stake_cents > 0),
  created_at timestamptz not null default now()
);

-- Idempotent migration block: drops the legacy per-user column and renames
-- `deduction_x` (units) to `stake_cents` (money). No-op on fresh installs.
do $$
begin
  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'challenges'
       and column_name = 'user_id'
  ) then
    alter table public.challenges drop constraint if exists challenges_group_id_user_id_key;
    alter table public.challenges drop column user_id;
    alter table public.challenges add constraint challenges_group_id_key unique (group_id);
  end if;

  if exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'challenges'
       and column_name = 'deduction_x'
  ) and not exists (
    select 1 from information_schema.columns
     where table_schema = 'public' and table_name = 'challenges'
       and column_name = 'stake_cents'
  ) then
    alter table public.challenges rename column deduction_x to stake_cents;
    -- Old deduction_x was a small-integer "unit" count; rescale to cents
    -- by treating each unit as one cent. Adjust manually if your data was
    -- already in dollars.
    alter table public.challenges
      alter column stake_cents set default 100;
  end if;
end $$;

-- =========================================================================
-- workout_logs
-- =========================================================================
create table if not exists public.workout_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  group_id uuid not null references public.groups(id) on delete cascade,
  duration_minutes int not null check (duration_minutes >= 0),
  workout_type text not null default 'general',
  photo_url text,
  logged_at timestamptz not null default now()
);

create index if not exists workout_logs_group_idx on public.workout_logs(group_id, logged_at desc);
create index if not exists workout_logs_user_idx on public.workout_logs(user_id, logged_at desc);

-- =========================================================================
-- balances
-- =========================================================================
create table if not exists public.balances (
  group_id uuid not null references public.groups(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  balance int not null default 0,
  updated_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

-- =========================================================================
-- weekly_results
-- =========================================================================
create table if not exists public.weekly_results (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  week_start date not null,
  week_end date not null,
  winners uuid[] not null default '{}',
  losers uuid[] not null default '{}',
  pool_amount int not null default 0,
  per_winner int not null default 0,
  created_at timestamptz not null default now(),
  unique (group_id, week_start)
);

-- =========================================================================
-- storage buckets (run in dashboard or via API)
-- =========================================================================
-- insert into storage.buckets (id, name, public) values
--   ('workout-photos', 'workout-photos', true),
--   ('profile-photos', 'profile-photos', true)
--   on conflict (id) do nothing;

-- =========================================================================
-- helpers
-- =========================================================================
create or replace function public.is_group_member(p_group uuid, p_user uuid)
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.group_members
    where group_id = p_group and user_id = p_user
  );
$$;

-- generate a 6-char invite code
create or replace function public.generate_invite_code()
returns text
language plpgsql
as $$
declare
  code text;
begin
  loop
    code := upper(substr(md5(random()::text), 1, 6));
    exit when not exists (select 1 from public.groups where invite_code = code);
  end loop;
  return code;
end;
$$;

-- Look up a group by its invite code and add the caller as a member.
-- Runs as SECURITY DEFINER so the caller can find a group they're not yet
-- a member of (the groups_select RLS policy hides those). Returns 0 rows
-- when the code is unknown so the client can show a friendly error.
create or replace function public.join_group_by_invite(p_code text)
returns setof public.groups
language plpgsql security definer
set search_path = public
as $$
declare
  g           public.groups%rowtype;
  member_cnt  integer;
  already     boolean;
begin
  select * into g from public.groups
   where invite_code = upper(p_code)
   limit 1;
  if not found then
    return;
  end if;
  -- Already a member? Treat as a no-op success (idempotent).
  select exists (
    select 1 from public.group_members
     where group_id = g.id and user_id = auth.uid()
  ) into already;
  if not already then
    select count(*) into member_cnt
      from public.group_members
     where group_id = g.id;
    if member_cnt >= 7 then
      raise exception 'GROUP_FULL' using errcode = 'P0001';
    end if;
    insert into public.group_members (group_id, user_id)
         values (g.id, auth.uid())
    on conflict do nothing;
  end if;
  return next g;
end;
$$;

revoke all on function public.join_group_by_invite(text) from public;
grant execute on function public.join_group_by_invite(text) to authenticated;

-- auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'name', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- =========================================================================
-- Row Level Security
-- =========================================================================
alter table public.profiles enable row level security;
alter table public.groups enable row level security;
alter table public.group_members enable row level security;
alter table public.challenges enable row level security;
alter table public.workout_logs enable row level security;
alter table public.balances enable row level security;
alter table public.weekly_results enable row level security;

-- profiles: anyone authenticated can read; users can only modify themselves
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
  for select using (auth.role() = 'authenticated');

drop policy if exists profiles_update on public.profiles;
create policy profiles_update on public.profiles
  for update using (id = auth.uid());

-- The handle_new_user trigger creates the row at signup, but the supabase
-- client also performs upserts when the user edits their profile — so we
-- need an INSERT policy that lets a user write their own row.
drop policy if exists profiles_insert on public.profiles;
create policy profiles_insert on public.profiles
  for insert with check (id = auth.uid());

-- groups: members can read; anyone authenticated can create; owner can update
drop policy if exists groups_select on public.groups;
create policy groups_select on public.groups
  for select using (
    public.is_group_member(id, auth.uid()) or owner_id = auth.uid()
  );

drop policy if exists groups_insert on public.groups;
create policy groups_insert on public.groups
  for insert with check (owner_id = auth.uid());

drop policy if exists groups_update on public.groups;
create policy groups_update on public.groups
  for update using (owner_id = auth.uid());

-- group_members: a user sees members of groups they are in; can insert self
drop policy if exists group_members_select on public.group_members;
create policy group_members_select on public.group_members
  for select using (public.is_group_member(group_id, auth.uid()));

drop policy if exists group_members_insert on public.group_members;
create policy group_members_insert on public.group_members
  for insert with check (user_id = auth.uid());

drop policy if exists group_members_delete on public.group_members;
create policy group_members_delete on public.group_members
  for delete using (user_id = auth.uid());

-- challenges: members read; only the group owner writes.
drop policy if exists challenges_select on public.challenges;
create policy challenges_select on public.challenges
  for select using (public.is_group_member(group_id, auth.uid()));

drop policy if exists challenges_insert on public.challenges;
create policy challenges_insert on public.challenges
  for insert with check (
    exists (select 1 from public.groups
             where id = group_id and owner_id = auth.uid())
  );

drop policy if exists challenges_update on public.challenges;
create policy challenges_update on public.challenges
  for update using (
    exists (select 1 from public.groups
             where id = group_id and owner_id = auth.uid())
  );

-- workout_logs
drop policy if exists workout_logs_select on public.workout_logs;
create policy workout_logs_select on public.workout_logs
  for select using (public.is_group_member(group_id, auth.uid()));

drop policy if exists workout_logs_insert on public.workout_logs;
create policy workout_logs_insert on public.workout_logs
  for insert with check (
    user_id = auth.uid() and public.is_group_member(group_id, auth.uid())
  );

-- balances: read-only for members; written by service-role cron
drop policy if exists balances_select on public.balances;
create policy balances_select on public.balances
  for select using (public.is_group_member(group_id, auth.uid()));

-- weekly_results: read-only for members; written by service-role cron
drop policy if exists weekly_results_select on public.weekly_results;
create policy weekly_results_select on public.weekly_results
  for select using (public.is_group_member(group_id, auth.uid()));

-- =========================================================================
-- Storage policies
--
-- Both buckets are public-read; writes require a signed-in user, and the
-- caller may only write to a folder named after their own auth uid (we use
-- "<uid>/<uuid>.jpg" as the key in the app).
-- =========================================================================
drop policy if exists "profile_photos_public_read" on storage.objects;
create policy "profile_photos_public_read" on storage.objects
  for select to public
  using (bucket_id = 'profile-photos');

drop policy if exists "profile_photos_owner_insert" on storage.objects;
create policy "profile_photos_owner_insert" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "profile_photos_owner_update" on storage.objects;
create policy "profile_photos_owner_update" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "profile_photos_owner_delete" on storage.objects;
create policy "profile_photos_owner_delete" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "workout_photos_public_read" on storage.objects;
create policy "workout_photos_public_read" on storage.objects
  for select to public
  using (bucket_id = 'workout-photos');

drop policy if exists "workout_photos_owner_insert" on storage.objects;
create policy "workout_photos_owner_insert" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'workout-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
