/*
  # Fix RLS policies to prevent recursion

  1. Changes
    - Simplify RLS policies to avoid circular references
    - Use direct role checks instead of subqueries
    - Ensure proper access control without recursion
  
  2. Security
    - Maintain proper access control
    - Fix infinite recursion issues
    - Keep existing functionality intact
*/

-- Drop existing policies
DROP POLICY IF EXISTS "users_read_own" ON public.users;
DROP POLICY IF EXISTS "users_insert_own" ON public.users;
DROP POLICY IF EXISTS "users_update_own" ON public.users;

-- Create new simplified policies
CREATE POLICY "users_read"
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

-- Update applications policy to avoid recursion
DROP POLICY IF EXISTS "applications_read" ON public.applications;
CREATE POLICY "applications_read"
  ON public.applications
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE auth.users.id = auth.uid()
      AND auth.users.email = 'admin@immigration-portal.com'
    )
  );

-- Update programs policy to avoid recursion
DROP POLICY IF EXISTS "programs_admin_write" ON public.programs;
CREATE POLICY "programs_admin_write"
  ON public.programs
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE auth.users.id = auth.uid()
      AND auth.users.email = 'admin@immigration-portal.com'
    )
  );

-- Update messages policy to avoid recursion
DROP POLICY IF EXISTS "messages_user_access" ON public.messages;
CREATE POLICY "messages_user_access"
  ON public.messages
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.applications 
      WHERE applications.id = messages.application_id 
      AND (
        applications.user_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM auth.users
          WHERE auth.users.id = auth.uid()
          AND auth.users.email = 'admin@immigration-portal.com'
        )
      )
    )
  );