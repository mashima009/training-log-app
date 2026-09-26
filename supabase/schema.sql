-- Supabase schema for Training Log personal app
-- Run this in Supabase SQL editor.

create extension if not exists pgcrypto;

create table if not exists public.workouts (
  id text primary key,
  user_id text not null default 'personal-user',
  date date not null,
  workout_name text not null,
  categories text[] not null default '{}',
  intensity text not null default '普通',
  set_count integer not null default 0,
  total_weight numeric(10,2) not null default 0,
  notes text default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.workout_sets (
  id text primary key,
  workout_id text not null references public.workouts(id) on delete cascade,
  user_id text not null default 'personal-user',
  set_index integer not null default 1,
  weight numeric(10,2) not null default 0,
  weight_type text not null default 'kg' check (weight_type in ('kg', 'bodyweight')),
  reps integer not null default 0,
  rest_seconds integer not null default 60,
  created_at timestamptz not null default now()
);

create table if not exists public.body_metrics (
  id text primary key,
  user_id text not null default 'personal-user',
  date date not null,
  metric_values jsonb not null default '{}',
  image_url text default null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.workout_sets
  add column if not exists weight_type text not null default 'kg';

alter table public.workouts alter column user_id drop default;
alter table public.workout_sets alter column user_id drop default;
alter table public.body_metrics alter column user_id drop default;

alter table public.workout_sets
  drop constraint if exists workout_sets_weight_type_check;

alter table public.workout_sets
  add constraint workout_sets_weight_type_check
  check (weight_type in ('kg', 'bodyweight'));

create unique index if not exists workouts_user_date_workout_idx
  on public.workouts (user_id, date, workout_name);

create index if not exists workout_sets_workout_id_idx
  on public.workout_sets (workout_id);

create index if not exists body_metrics_user_date_idx
  on public.body_metrics (user_id, date);

create or replace function public.update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists workouts_set_updated_at on public.workouts;
drop trigger if exists body_metrics_set_updated_at on public.body_metrics;

create trigger workouts_set_updated_at
before update on public.workouts
for each row
execute function public.update_updated_at_column();

create trigger body_metrics_set_updated_at
before update on public.body_metrics
for each row
execute function public.update_updated_at_column();

alter table public.workouts enable row level security;
alter table public.workout_sets enable row level security;
alter table public.body_metrics enable row level security;

drop policy if exists "Allow all access for personal app" on public.workouts;
drop policy if exists "Allow all access for personal app" on public.workout_sets;
drop policy if exists "Allow all access for personal app" on public.body_metrics;
drop policy if exists "Users can access their own workouts" on public.workouts;
drop policy if exists "Users can access their own workout sets" on public.workout_sets;
drop policy if exists "Users can access their own metrics" on public.body_metrics;

create policy "Users can access their own workouts"
on public.workouts
for all
using (auth.uid()::text = user_id)
with check (auth.uid()::text = user_id);

create policy "Users can access their own workout sets"
on public.workout_sets
for all
using (
  auth.uid()::text = user_id
  and exists (
    select 1 from public.workouts
    where workouts.id = workout_sets.workout_id
      and workouts.user_id = auth.uid()::text
  )
)
with check (
  auth.uid()::text = user_id
  and exists (
    select 1 from public.workouts
    where workouts.id = workout_sets.workout_id
      and workouts.user_id = auth.uid()::text
  )
);

create policy "Users can access their own metrics"
on public.body_metrics
for all
using (auth.uid()::text = user_id)
with check (auth.uid()::text = user_id);

