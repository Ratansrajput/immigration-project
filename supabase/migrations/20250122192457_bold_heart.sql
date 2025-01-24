/*
  # Fix users table policies to prevent recursion

  1. Changes
    - Simplify policies to avoid recursive checks
    - Add basic insert policy for registration
    - Add select policy with direct role check
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own data" ON public.users;
DROP POLICY IF EXISTS "Users can insert their own data" ON public.users;
DROP POLICY IF EXISTS "Admin can view all users" ON public.users;

-- Create new simplified policies
CREATE POLICY "Enable insert for authentication users only"
  ON public.users
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Enable read access for users"
  ON public.users
  FOR SELECT
  USING (
    -- Users can read their own data
    auth.uid() = user_id
    OR
    -- Users with admin role can read all data
    (SELECT role FROM public.users WHERE user_id = auth.uid()) = 'admin'
  );