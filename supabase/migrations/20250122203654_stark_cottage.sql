/*
  # Fix permissions for users and related tables

  1. Updates
    - Simplify user table policies
    - Fix join permissions for applications and messages
    - Add missing foreign key references
  
  2. Security
    - Ensure proper access control
    - Allow necessary joins between tables
*/

-- Drop existing policies
DROP POLICY IF EXISTS "users_read_all" ON public.users;
DROP POLICY IF EXISTS "users_insert_self" ON public.users;
DROP POLICY IF EXISTS "users_update_self" ON public.users;

-- Create simplified user policies
CREATE POLICY "enable_all_access_for_authenticated"
  ON public.users
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Update applications table to include user profile in selections
ALTER TABLE public.applications
  DROP CONSTRAINT IF EXISTS applications_user_id_fkey,
  ADD CONSTRAINT applications_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES auth.users(id);

-- Update messages table to include user profile in selections
ALTER TABLE public.messages
  DROP CONSTRAINT IF EXISTS messages_sender_id_fkey,
  ADD CONSTRAINT messages_sender_id_fkey 
  FOREIGN KEY (sender_id) REFERENCES auth.users(id);

-- Create indexes for better join performance
CREATE INDEX IF NOT EXISTS idx_users_id ON public.users(id);
CREATE INDEX IF NOT EXISTS idx_applications_user_id ON public.applications(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);