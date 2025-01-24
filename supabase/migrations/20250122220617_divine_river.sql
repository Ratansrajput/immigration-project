/*
  # Fix users table permissions

  1. Changes
    - Simplify users table policies
    - Ensure proper access for authenticated users
    - Fix permission denied errors
    
  2. Security
    - Maintain data access control
    - Allow necessary operations for authenticated users
*/

-- Drop existing policies
DROP POLICY IF EXISTS "enable_all_access_for_authenticated_users" ON public.users;
DROP POLICY IF EXISTS "authenticated_read" ON public.users;
DROP POLICY IF EXISTS "authenticated_insert" ON public.users;
DROP POLICY IF EXISTS "authenticated_update" ON public.users;

-- Create new simplified policies
CREATE POLICY "users_select"
  ON public.users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "users_insert"
  ON public.users
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "users_update"
  ON public.users
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

-- Ensure RLS is enabled
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_users_id ON public.users(id);