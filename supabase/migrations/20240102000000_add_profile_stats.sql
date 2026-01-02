-- Add physical stats columns to profiles for calorie calculation
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS height_cm integer,
ADD COLUMN IF NOT EXISTS weight_kg numeric(5,2),
ADD COLUMN IF NOT EXISTS age integer,
ADD COLUMN IF NOT EXISTS gender text CHECK (gender IN ('male', 'female', 'other')),
ADD COLUMN IF NOT EXISTS activity_level text CHECK (activity_level IN ('sedentary', 'light', 'moderate', 'active', 'very_active')) DEFAULT 'moderate',
ADD COLUMN IF NOT EXISTS protein_target integer,
ADD COLUMN IF NOT EXISTS carbs_target integer,
ADD COLUMN IF NOT EXISTS fat_target integer,
ADD COLUMN IF NOT EXISTS cached_feedback text,
ADD COLUMN IF NOT EXISTS feedback_updated_at timestamp with time zone,
ADD COLUMN IF NOT EXISTS last_meal_at timestamp with time zone;

-- Update the default calorie_target to be nullable (will be calculated)
ALTER TABLE public.profiles ALTER COLUMN calorie_target DROP DEFAULT;
