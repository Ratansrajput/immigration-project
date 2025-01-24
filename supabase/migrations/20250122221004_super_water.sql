/*
  # Fix final database permissions

  1. Changes
    - Simplify all policies further
    - Fix permission denied errors for users table
    - Fix permission denied errors for application documents
    - Ensure proper access for all related tables
    
  2. Security
    - Enable RLS on all tables
    - Set up proper policies for each table
    - Ensure proper access control while allowing necessary joins
*/

-- Reset all existing policies
DROP POLICY IF EXISTS "allow_public_read" ON public.users;
DROP POLICY IF EXISTS "allow_self_insert" ON public.users;
DROP POLICY IF EXISTS "allow_self_update" ON public.users;
DROP POLICY IF EXISTS "allow_user_read" ON public.applications;
DROP POLICY IF EXISTS "allow_admin_read" ON public.applications;
DROP POLICY IF EXISTS "allow_user_insert" ON public.applications;
DROP POLICY IF EXISTS "allow_user_update" ON public.applications;
DROP POLICY IF EXISTS "allow_admin_update" ON public.applications;
DROP POLICY IF EXISTS "allow_user_documents" ON public.application_documents;
DROP POLICY IF EXISTS "allow_admin_documents" ON public.application_documents;

-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.application_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.application_questionnaire ENABLE ROW LEVEL SECURITY;

-- Users table policies (simplified to allow necessary joins)
CREATE POLICY "users_access"
  ON public.users
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (auth.uid() = id);

-- Applications table policies
CREATE POLICY "applications_access"
  ON public.applications
  FOR ALL
  TO authenticated
  USING (
    user_id = auth.uid() OR
    auth.jwt() ->> 'email' = 'admin@immigration-portal.com'
  )
  WITH CHECK (
    user_id = auth.uid() OR
    auth.jwt() ->> 'email' = 'admin@immigration-portal.com'
  );

-- Application documents policies
CREATE POLICY "application_documents_access"
  ON public.application_documents
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.applications
      WHERE applications.id = application_documents.application_id
      AND (
        applications.user_id = auth.uid() OR
        auth.jwt() ->> 'email' = 'admin@immigration-portal.com'
      )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.applications
      WHERE applications.id = application_documents.application_id
      AND (
        applications.user_id = auth.uid() OR
        auth.jwt() ->> 'email' = 'admin@immigration-portal.com'
      )
    )
  );

-- Application questionnaire policies
CREATE POLICY "application_questionnaire_access"
  ON public.application_questionnaire
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.applications
      WHERE applications.id = application_questionnaire.application_id
      AND (
        applications.user_id = auth.uid() OR
        auth.jwt() ->> 'email' = 'admin@immigration-portal.com'
      )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.applications
      WHERE applications.id = application_questionnaire.application_id
      AND (
        applications.user_id = auth.uid() OR
        auth.jwt() ->> 'email' = 'admin@immigration-portal.com'
      )
    )
  );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_applications_user_id ON public.applications(user_id);
CREATE INDEX IF NOT EXISTS idx_application_documents_application_id ON public.application_documents(application_id);
CREATE INDEX IF NOT EXISTS idx_application_questionnaire_application_id ON public.application_questionnaire(application_id);
CREATE INDEX IF NOT EXISTS idx_users_id ON public.users(id);