-- Remove image storage from Supabase
-- Images are now only used temporarily for AI analysis and discarded

-- Remove image_path column from meals table
ALTER TABLE public.meals DROP COLUMN IF EXISTS image_path;

-- Drop storage bucket policies
DROP POLICY IF EXISTS "Give users access to own folder 1u753_0" ON storage.objects;
DROP POLICY IF EXISTS "Give users access to own folder 1u753_1" ON storage.objects;

-- Remove storage bucket (this will fail if there are still files in the bucket)
-- You may need to delete existing files first via Supabase Dashboard
DELETE FROM storage.buckets WHERE id = 'meal_images';
