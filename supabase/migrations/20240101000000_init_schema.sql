-- Create profiles table
create table public.profiles (
  id uuid not null references auth.users on delete cascade,
  calorie_target integer default 2000,
  goal_description text,
  full_name text,
  avatar_url text,
  updated_at timestamp with time zone,
  
  primary key (id),
  constraint username_length check (char_length(full_name) >= 3)
);

-- Turn on RLS
alter table public.profiles enable row level security;

-- Create profiles policies
create policy "Public profiles are viewable by everyone."
  on profiles for select
  using ( true );

create policy "Users can insert their own profile."
  on profiles for insert
  with check ( auth.uid() = id );

create policy "Users can update own profile."
  on profiles for update
  using ( auth.uid() = id );

-- Create meals table
create table public.meals (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  image_path text,
  text_content text,
  analysis jsonb, -- { items: [{name, calories, ...}], summary: {calories, protein...} }
  meal_type text check (meal_type in ('breakfast', 'lunch', 'dinner', 'snack')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Turn on RLS
alter table public.meals enable row level security;

-- Create meals policies
create policy "Users can view their own meals."
  on meals for select
  using ( auth.uid() = user_id );

create policy "Users can insert their own meals."
  on meals for insert
  with check ( auth.uid() = user_id );

create policy "Users can update their own meals."
  on meals for update
  using ( auth.uid() = user_id );

create policy "Users can delete their own meals."
  on meals for delete
  using ( auth.uid() = user_id );

-- Create food_catalog table (Shared Knowledge Base)
create table public.food_catalog (
  id uuid default gen_random_uuid() primary key,
  name text not null,
  brand text,
  nutrition jsonb not null, -- { calories, protein, carbs, fat, serving_size }
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Turn on RLS
alter table public.food_catalog enable row level security;

-- Create food_catalog policies
create policy "Food catalog is viewable by authenticated users."
  on food_catalog for select
  to authenticated
  using ( true );

-- Function to handle new user signup
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

-- Trigger to create profile
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Storage Bucket Setup (Note: This usually needs to be done in UI or via API, but here is SQL if supported)
insert into storage.buckets (id, name, public)
values ('meal_images', 'meal_images', true)
on conflict (id) do nothing;

create policy "Give users access to own folder 1u753_0" on storage.objects
  for select
  to authenticated
  using ( bucket_id = 'meal_images' and (storage.foldername(name))[1] = auth.uid()::text );

create policy "Give users access to own folder 1u753_1" on storage.objects
  for insert
  to authenticated
  with check ( bucket_id = 'meal_images' and (storage.foldername(name))[1] = auth.uid()::text );
