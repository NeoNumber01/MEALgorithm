-- Add goal enum type and goal column to profiles table
create type public.goal_enum as enum ('maintenance', 'weight-loss', 'muscle-gain');

alter table public.profiles 
add column goal public.goal_enum default 'maintenance';

-- Drop the old goal_description column since we're replacing it with goal
alter table public.profiles 
drop column if exists goal_description;
