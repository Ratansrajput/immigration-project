/*
  # Fix users table policies

  1. Changes
    - Remove recursive policy that was causing infinite recursion
    - Add separate policies for insert and select operations
    - Fix admin access policy
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their own data" ON public.users;

-- Create new policies
CREATE POLICY "Users can insert their own data"
  ON public.users
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own data"
  ON public.users
  FOR SELECT
  USING (
    auth.uid() = user_id 
    OR 
    role = 'admin'
  );

CREATE POLICY "Admin can view all users"
  ON public.users
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 
      FROM public.users 
      WHERE user_id = auth.uid() 
      AND role = 'admin'
    )
  );