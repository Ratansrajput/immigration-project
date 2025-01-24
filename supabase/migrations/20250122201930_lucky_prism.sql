/*
  # Fix admin permissions and program access

  1. Changes
    - Add program policies for admin access
    - Fix user table references
    - Update application policies
  
  2. Security
    - Enable RLS on programs table
    - Add policies for program management
*/

-- Update programs policies
DROP POLICY IF EXISTS "Admin can manage programs" ON public.programs;
DROP POLICY IF EXISTS "Everyone can view programs" ON public.programs;

CREATE POLICY "programs_admin_access"
  ON public.programs
  FOR ALL
  TO authenticated
  USING (
    auth.jwt() ->> 'email' = 'admin@immigration-portal.com'
  );

CREATE POLICY "programs_public_read"
  ON public.programs
  FOR SELECT
  TO authenticated
  USING (true);

-- Update applications policies
DROP POLICY IF EXISTS "applications_access" ON public.applications;

CREATE POLICY "applications_admin_access"
  ON public.applications
  FOR ALL
  TO authenticated
  USING (
    auth.jwt() ->> 'email' = 'admin@immigration-portal.com'
  );

CREATE POLICY "applications_user_access"
  ON public.applications
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Update messages policies
DROP POLICY IF EXISTS "messages_access" ON public.messages;

CREATE POLICY "messages_admin_access"
  ON public.messages
  FOR ALL
  TO authenticated
  USING (
    auth.jwt() ->> 'email' = 'admin@immigration-portal.com'
  );

CREATE POLICY "messages_user_access"
  ON public.messages
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.applications 
      WHERE applications.id = messages.application_id 
      AND applications.user_id = auth.uid()
    )
  );