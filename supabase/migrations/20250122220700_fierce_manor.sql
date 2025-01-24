/*
  # Fix database permissions

  1. Changes
    - Simplify all policies
    - Fix permission denied errors
    - Ensure proper access control
    
  2. Security
    - Enable RLS on all tables
    - Set up proper policies for each table
*/

-- Reset all existing policies
DROP POLICY IF EXISTS "users_select" ON public.users;
DROP POLICY IF EXISTS "users_insert" ON public.users;
DROP POLICY IF EXISTS "users_update" ON public.users;
DROP POLICY IF EXISTS "applications_user_read" ON public.applications;
DROP POLICY IF EXISTS "applications_admin_read" ON public.applications;
DROP POLICY IF EXISTS "applications_user_insert" ON public.applications;
DROP POLICY IF EXISTS "applications_user_update" ON public.applications;

-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.application_documents ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY "allow_public_read"
  ON public.users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "allow_self_insert"
  ON public.users
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "allow_self_update"
  ON public.users
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

-- Applications table policies
CREATE POLICY "allow_user_read"
  ON public.applications
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "allow_admin_read"
  ON public.applications
  FOR SELECT
  TO authenticated
  USING (auth.jwt() ->> 'email' = 'admin@immigration-portal.com');

CREATE POLICY "allow_user_insert"
  ON public.applications
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "allow_user_update"
  ON public.applications
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "allow_admin_update"
  ON public.applications
  FOR UPDATE
  TO authenticated
  USING (auth.jwt() ->> 'email' = 'admin@immigration-portal.com');

-- Application documents policies
CREATE POLICY "allow_user_documents"
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

CREATE POLICY "allow_admin_documents"
  ON public.application_documents
  FOR ALL
  TO authenticated
  USING (auth.jwt() ->> 'email' = 'admin@immigration-portal.com');

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_applications_user_id ON public.applications(user_id);
CREATE INDEX IF NOT EXISTS idx_application_documents_application_id ON public.application_documents(application_id);
CREATE INDEX IF NOT EXISTS idx_users_id ON public.users(id);