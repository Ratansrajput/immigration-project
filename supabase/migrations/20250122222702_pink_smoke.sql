-- Drop existing messages table if it exists
DROP TABLE IF EXISTS public.messages CASCADE;

-- Create messages table with proper relationships
CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID REFERENCES public.applications(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Create messages policy
CREATE POLICY "messages_access"
  ON public.messages
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.applications
      WHERE applications.id = messages.application_id
      AND (
        applications.user_id = auth.uid() OR
        auth.jwt() ->> 'email' = 'admin@immigration-portal.com'
      )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.applications
      WHERE applications.id = messages.application_id
      AND (
        applications.user_id = auth.uid() OR
        auth.jwt() ->> 'email' = 'admin@immigration-portal.com'
      )
    )
  );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_messages_application_id ON public.messages(application_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at);