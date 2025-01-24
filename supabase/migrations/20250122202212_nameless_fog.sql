/*
  # Fix users table and policies

  1. Changes
    - Update users table structure
    - Add proper RLS policies for user access
    - Fix foreign key references
  
  2. Security
    - Enable RLS on users table
    - Ensure users can access their own data
    - Allow proper admin access
*/

-- Drop existing policies
DROP POLICY IF EXISTS "authenticated_read" ON public.users;
DROP POLICY IF EXISTS "authenticated_insert" ON public.users;
DROP POLICY IF EXISTS "authenticated_update" ON public.users;
DROP POLICY IF EXISTS "admin_all" ON public.users;

-- Create new policies
CREATE POLICY "users_read_own"
  ON public.users
  FOR SELECT
  TO authenticated
  USING (
    id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

CREATE POLICY "users_insert_own"
  ON public.users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    id = auth.uid()
  );

CREATE POLICY "users_update_own"
  ON public.users
  FOR UPDATE
  TO authenticated
  USING (
    id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Update foreign key references
ALTER TABLE public.applications
  DROP CONSTRAINT IF EXISTS applications_user_id_fkey,
  ADD CONSTRAINT applications_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES public.users(id);

ALTER TABLE public.messages
  DROP CONSTRAINT IF EXISTS messages_sender_id_fkey,
  ADD CONSTRAINT messages_sender_id_fkey 
  FOREIGN KEY (sender_id) REFERENCES public.users(id);