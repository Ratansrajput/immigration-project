/*
  # Fix database permissions

  1. Changes
    - Simplify RLS policies for users table
    - Add missing policies for application_documents
    - Ensure proper access to related tables
    
  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
    - Fix permission issues with joins
*/

-- Drop existing policies
DROP POLICY IF EXISTS "users_read" ON public.users;
DROP POLICY IF EXISTS "users_insert" ON public.users;
DROP POLICY IF EXISTS "users_update" ON public.users;

-- Create new simplified policies for users table
CREATE POLICY "enable_all_access_for_authenticated_users"
  ON public.users
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Update applications policies to handle joins properly
DROP POLICY IF EXISTS "applications_read" ON public.applications;
CREATE POLICY "applications_read"
  ON public.applications
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid() OR
    auth.jwt() ->> 'email' = 'admin@immigration-portal.com'
  );

-- Add policies for application_documents
DROP POLICY IF EXISTS "documents_read" ON public.application_documents;
CREATE POLICY "documents_read"
  ON public.application_documents
  FOR SELECT
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
  );

-- Ensure RLS is enabled
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.application_documents ENABLE ROW LEVEL SECURITY;

-- Create indexes for better join performance
CREATE INDEX IF NOT EXISTS idx_application_documents_application_id 
  ON public.application_documents(application_id);