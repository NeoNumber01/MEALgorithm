-- ==========================================
-- MEALgorithm Supabase Setup Script
-- ==========================================
-- Run this script in the Supabase SQL Editor to fix 'public.profiles' errors and setup the database.

-- 1. Create profiles table
create table if not exists public.profiles (
  id uuid not null references auth.users on delete cascade,
  calorie_target integer,
  goal_description text,
  full_name text,
  avatar_url text,
  updated_at timestamp with time zone,
  
  -- Physical Stats
  height_cm integer,
  weight_kg numeric(5,2),
  age integer,
  gender text CHECK (gender IN ('male', 'female', 'other')),
  activity_level text CHECK (activity_level IN ('sedentary', 'light', 'moderate', 'active', 'very_active')) DEFAULT 'moderate',
  
  -- Calculated Targets
  protein_target integer,
  carbs_target integer,
  fat_target integer,
  
  -- AI Caching
  cached_feedback text,
  feedback_updated_at timestamp with time zone,
  last_meal_at timestamp with time zone,

  -- Preferences
  food_preferences text,
  food_dislikes text,
  dietary_restrictions text,
  custom_notes text,
  
  primary key (id),
  constraint username_length check (char_length(full_name) >= 3)
);

-- 2. Enable RLS
alter table public.profiles enable row level security;

-- 3. Create policies (Use DO block to avoid errors if policies exist)
do $$
begin
    if not exists (select 1 from pg_policies where policyname = 'Public profiles are viewable by everyone.') then
        create policy "Public profiles are viewable by everyone." on profiles for select using ( true );
    end if;

    if not exists (select 1 from pg_policies where policyname = 'Users can insert their own profile.') then
        create policy "Users can insert their own profile." on profiles for insert with check ( auth.uid() = id );
    end if;

    if not exists (select 1 from pg_policies where policyname = 'Users can update own profile.') then
        create policy "Users can update own profile." on profiles for update using ( auth.uid() = id );
    end if;
end
$$;

-- 4. Create trigger for new users
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url');
  return new;
end;
$$;

-- Drop trigger if exists to ensure clean slate
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 5. Create meals table if not exists
create table if not exists public.meals (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  image_path text,
  text_content text,
  analysis jsonb, 
  meal_type text check (meal_type in ('breakfast', 'lunch', 'dinner', 'snack')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.meals enable row level security;

do $$
begin
    if not exists (select 1 from pg_policies where policyname = 'Users can view their own meals.') then
        create policy "Users can view their own meals." on meals for select using ( auth.uid() = user_id );
    end if;

    if not exists (select 1 from pg_policies where policyname = 'Users can insert their own meals.') then
        create policy "Users can insert their own meals." on meals for insert with check ( auth.uid() = user_id );
    end if;

    if not exists (select 1 from pg_policies where policyname = 'Users can update their own meals.') then
        create policy "Users can update their own meals." on meals for update using ( auth.uid() = user_id );
    end if;

    if not exists (select 1 from pg_policies where policyname = 'Users can delete their own meals.') then
        create policy "Users can delete their own meals." on meals for delete using ( auth.uid() = user_id );
    end if;
end
$$;
