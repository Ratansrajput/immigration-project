/*
  # Fix Permission Issues

  1. Changes
    - Simplify users table policies
    - Fix applications table policies
    - Add missing join permissions
    
  2. Security
    - Ensure proper access control
    - Fix recursive policy issues
*/

-- Drop existing policies
DROP POLICY IF EXISTS "users_read" ON public.users;
DROP POLICY IF EXISTS "users_insert" ON public.users;
DROP POLICY IF EXISTS "users_update" ON public.users;
DROP POLICY IF EXISTS "applications_read" ON public.applications;
DROP POLICY IF EXISTS "applications_insert" ON public.applications;
DROP POLICY IF EXISTS "applications_update" ON public.applications;
DROP POLICY IF EXISTS "applications_delete" ON public.applications;

-- Create simplified users policies
CREATE POLICY "users_read_all"
  ON public.users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "users_insert_self"
  ON public.users
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "users_update_self"
  ON public.users
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

-- Create application policies
CREATE POLICY "applications_select"
  ON public.applications
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR
    auth.jwt() ->> 'email' = 'admin@immigration-portal.com'
  );

CREATE POLICY "applications_insert"
  ON public.applications
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "applications_update"
  ON public.applications
  FOR UPDATE
  TO authenticated
  USING (
    user_id = auth.uid() OR
    auth.jwt() ->> 'email' = 'admin@immigration-portal.com'
  );

CREATE POLICY "applications_delete"
  ON public.applications
  FOR DELETE
  TO authenticated
  USING (
    auth.jwt() ->> 'email' = 'admin@immigration-portal.com'
  );

-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_applications_user_id ON public.applications(user_id);
CREATE INDEX IF NOT EXISTS idx_applications_program_id ON public.applications(program_id);