-- Create goal enum type
create type public.goal_type as enum ('maintenance', 'weight-loss', 'muscle-gain');

-- Add goal column to profiles table
alter table public.profiles
add column goal public.goal_type default 'maintenance';

-- Keep goal_description for backwards compatibility, but it won't be used going forward
-- Migrations handled at app level if needed
