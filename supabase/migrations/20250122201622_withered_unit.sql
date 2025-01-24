/*
  # Fix users table permissions

  1. Changes
    - Drop existing policies
    - Create new simplified policies for basic CRUD operations
    - Add admin access policy
    - Fix foreign key references
  
  2. Security
    - Enable RLS
    - Add policies for:
      - Reading user profiles
      - Updating own profile
      - Inserting during signup
      - Admin access
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Enable read access for own profile" ON public.users;
DROP POLICY IF EXISTS "Enable update access for own profile" ON public.users;
DROP POLICY IF EXISTS "Enable insert for authentication" ON public.users;
DROP POLICY IF EXISTS "Admin full access" ON public.users;

-- Create new policies
CREATE POLICY "Public read access"
  ON public.users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can update own profile"
  ON public.users
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Enable insert during signup"
  ON public.users
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Admin full access"
  ON public.users
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM auth.users
      WHERE auth.uid() = auth.users.id 
      AND auth.users.email = 'admin@immigration-portal.com'
    )
  );

-- Update foreign key references
ALTER TABLE public.applications
  DROP CONSTRAINT IF EXISTS applications_user_id_fkey,
  ADD CONSTRAINT applications_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES public.users(id);

ALTER TABLE public.messages
  DROP CONSTRAINT IF EXISTS messages_sender_id_fkey,
  ADD CONSTRAINT messages_sender_id_fkey 
  FOREIGN KEY (sender_id) REFERENCES public.users(id);