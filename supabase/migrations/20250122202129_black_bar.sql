/*
  # Fix applications table policies

  1. Changes
    - Update applications policies to allow proper user access
    - Add policy for users to create their own applications
    - Ensure admin access is properly handled
  
  2. Security
    - Maintain RLS on applications table
    - Ensure users can only access their own applications
    - Allow admins full access
*/

-- Drop existing application policies
DROP POLICY IF EXISTS "applications_admin_access" ON public.applications;
DROP POLICY IF EXISTS "applications_user_access" ON public.applications;

-- Create new application policies
CREATE POLICY "applications_read"
  ON public.applications
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

CREATE POLICY "applications_insert"
  ON public.applications
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = user_id
  );

CREATE POLICY "applications_update"
  ON public.applications
  FOR UPDATE
  TO authenticated
  USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

CREATE POLICY "applications_delete"
  ON public.applications
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );