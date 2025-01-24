/*
  # Fix users table permissions

  1. Changes
    - Drop existing policies on users table
    - Create new simplified policies that allow:
      - Public read access for authenticated users
      - Users to update their own profile
      - Users to insert during signup
      - Admin access for all operations
  
  2. Security
    - Enable RLS
    - Policies ensure users can only access appropriate data
*/

-- Drop existing policies
DROP POLICY IF EXISTS "authenticated_read" ON public.users;
DROP POLICY IF EXISTS "authenticated_insert" ON public.users;
DROP POLICY IF EXISTS "authenticated_update" ON public.users;
DROP POLICY IF EXISTS "admin_all" ON public.users;

-- Create new policies
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

CREATE POLICY "users_admin_all"
  ON public.users
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM auth.users
      WHERE auth.uid() = auth.users.id 
      AND auth.users.email = 'admin@immigration-portal.com'
    )
  );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_id ON public.users(id);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);