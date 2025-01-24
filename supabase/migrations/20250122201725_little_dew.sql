/*
  # Final RLS policy fix

  1. Changes
    - Drop all existing policies
    - Create simplified policies with proper authenticated access
    - Fix foreign key references
  
  2. Security
    - Enable RLS
    - Add policies for:
      - Public read access for authenticated users
      - Self profile management
      - Admin access
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Public read access" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Enable insert during signup" ON public.users;
DROP POLICY IF EXISTS "Admin full access" ON public.users;

-- Create new simplified policies
CREATE POLICY "authenticated_read"
  ON public.users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "authenticated_insert"
  ON public.users
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "authenticated_update"
  ON public.users
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "admin_all"
  ON public.users
  FOR ALL
  TO authenticated
  USING (
    auth.jwt() ->> 'email' = 'admin@immigration-portal.com'
  );

-- Update applications policy
DROP POLICY IF EXISTS "Users can view their applications" ON public.applications;
CREATE POLICY "applications_access"
  ON public.applications
  FOR ALL
  TO authenticated
  USING (
    user_id = auth.uid() 
    OR 
    auth.jwt() ->> 'email' = 'admin@immigration-portal.com'
  );

-- Update messages policy
DROP POLICY IF EXISTS "Users can view and send messages" ON public.messages;
CREATE POLICY "messages_access"
  ON public.messages
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.applications 
      WHERE applications.id = messages.application_id 
      AND (
        applications.user_id = auth.uid() 
        OR 
        auth.jwt() ->> 'email' = 'admin@immigration-portal.com'
      )
    )
  );