/*
  # Fix Messages Permissions

  1. Changes
    - Add proper RLS policies for messages table
    - Fix join permissions with users table
    
  2. Security
    - Ensure proper access control for chat messages
    - Allow users to view and send messages for their applications
    - Allow admins full access
*/

-- Drop existing message policies
DROP POLICY IF EXISTS "messages_admin_access" ON public.messages;
DROP POLICY IF EXISTS "messages_user_access" ON public.messages;

-- Create new message policies
CREATE POLICY "messages_access"
  ON public.messages
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM public.applications
      WHERE applications.id = messages.application_id
      AND (
        applications.user_id = auth.uid()
        OR auth.jwt() ->> 'email' = 'admin@immigration-portal.com'
      )
    )
  );

-- Enable RLS
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_messages_application_id 
  ON public.messages(application_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id 
  ON public.messages(sender_id);