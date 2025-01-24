/*
  # Fix users table RLS policies

  1. Changes
    - Drop existing policies that cause recursion
    - Create new simplified policies that avoid circular dependencies
    - Add basic security policies for CRUD operations
  
  2. Security
    - Enable RLS
    - Add policies for:
      - Reading own profile
      - Updating own profile
      - Inserting during signup
      - Admin access
*/

-- Drop existing policies to start fresh
DROP POLICY IF EXISTS "Users can read their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
DROP POLICY IF EXISTS "Allow insert during signup" ON public.users;
DROP POLICY IF EXISTS "Admins can read all profiles" ON public.users;

-- Create new simplified policies
CREATE POLICY "Enable read access for own profile"
  ON public.users
  FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Enable update access for own profile"
  ON public.users
  FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Enable insert for authentication"
  ON public.users
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Create a separate admin policy that doesn't cause recursion
CREATE POLICY "Admin full access"
  ON public.users
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 
      FROM auth.users
      WHERE auth.uid() = auth.users.id 
      AND auth.users.email = 'admin@immigration-portal.com'
    )
  );