/*
  # Fix application permissions

  1. Changes
    - Update policies to ensure users can only see their own applications
    - Add strict RLS policies for application-related tables
    
  2. Security
    - Enforce user-specific access control
    - Maintain admin access for oversight
*/

-- Drop existing policies
DROP POLICY IF EXISTS "applications_read" ON public.applications;
DROP POLICY IF EXISTS "applications_insert" ON public.applications;
DROP POLICY IF EXISTS "applications_update" ON public.applications;

-- Create strict application policies
CREATE POLICY "applications_user_read"
  ON public.applications
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "applications_admin_read"
  ON public.applications
  FOR SELECT
  TO authenticated
  USING (auth.jwt() ->> 'email' = 'admin@immigration-portal.com');

CREATE POLICY "applications_user_insert"
  ON public.applications
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "applications_user_update"
  ON public.applications
  FOR UPDATE
  TO authenticated
  USING (
    user_id = auth.uid() OR
    auth.jwt() ->> 'email' = 'admin@immigration-portal.com'
  );

-- Update application documents policies
DROP POLICY IF EXISTS "documents_read" ON public.application_documents;

CREATE POLICY "documents_user_access"
  ON public.application_documents
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.applications
      WHERE applications.id = application_documents.application_id
      AND applications.user_id = auth.uid()
    )
  );

CREATE POLICY "documents_admin_access"
  ON public.application_documents
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE auth.users.id = auth.uid()
      AND auth.users.email = 'admin@immigration-portal.com'
    )
  );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_applications_user_status ON public.applications(user_id, status);