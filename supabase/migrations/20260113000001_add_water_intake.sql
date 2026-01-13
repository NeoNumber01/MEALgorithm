-- Add water intake tracking to profiles
alter table public.profiles 
add column daily_water_intake integer default 0;

-- Create water_logs table to track daily water intake
create table public.water_logs (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  amount_ml integer not null check (amount_ml > 0),
  logged_at timestamp with time zone default timezone('utc'::text, now()) not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Turn on RLS
alter table public.water_logs enable row level security;

-- Create water_logs policies
create policy "Users can view their own water logs."
  on water_logs for select
  using ( auth.uid() = user_id );

create policy "Users can insert their own water logs."
  on water_logs for insert
  with check ( auth.uid() = user_id );

create policy "Users can delete their own water logs."
  on water_logs for delete
  using ( auth.uid() = user_id );
