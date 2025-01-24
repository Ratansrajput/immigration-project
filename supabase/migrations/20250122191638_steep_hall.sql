/*
  # Immigration Portal Initial Schema

  1. New Tables
    - users (extends auth.users)
      - user_id (uuid, primary key)
      - full_name (text)
      - role (text)
      - created_at (timestamp)
    
    - programs
      - id (uuid, primary key)
      - name (text)
      - description (text)
      - required_documents (jsonb)
      - created_at (timestamp)
    
    - applications
      - id (uuid, primary key)
      - user_id (uuid, foreign key)
      - program_id (uuid, foreign key)
      - status (text)
      - created_at (timestamp)
    
    - documents
      - id (uuid, primary key)
      - application_id (uuid, foreign key)
      - name (text)
      - file_path (text)
      - status (text)
      - created_at (timestamp)
    
    - messages
      - id (uuid, primary key)
      - application_id (uuid, foreign key)
      - sender_id (uuid, foreign key)
      - content (text)
      - created_at (timestamp)

  2. Security
    - Enable RLS on all tables
    - Add policies for user access
*/

-- Create tables
CREATE TABLE public.users (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  full_name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'customer',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.programs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  required_documents JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(user_id),
  program_id UUID REFERENCES public.programs(id),
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID REFERENCES public.applications(id),
  name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID REFERENCES public.applications(id),
  sender_id UUID REFERENCES public.users(user_id),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own data"
  ON public.users
  FOR SELECT
  USING (auth.uid() = user_id OR EXISTS (
    SELECT 1 FROM public.users WHERE user_id = auth.uid() AND role = 'admin'
  ));

CREATE POLICY "Admin can manage programs"
  ON public.programs
  FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.users WHERE user_id = auth.uid() AND role = 'admin'
  ));

CREATE POLICY "Everyone can view programs"
  ON public.programs
  FOR SELECT
  USING (true);

CREATE POLICY "Users can view their applications"
  ON public.applications
  FOR SELECT
  USING (user_id = auth.uid() OR EXISTS (
    SELECT 1 FROM public.users WHERE user_id = auth.uid() AND role = 'admin'
  ));

CREATE POLICY "Users can create applications"
  ON public.applications
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can manage their documents"
  ON public.documents
  FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.applications 
    WHERE applications.id = documents.application_id 
    AND (applications.user_id = auth.uid() OR EXISTS (
      SELECT 1 FROM public.users WHERE user_id = auth.uid() AND role = 'admin'
    ))
  ));

CREATE POLICY "Users can view and send messages"
  ON public.messages
  FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.applications 
    WHERE applications.id = messages.application_id 
    AND (applications.user_id = auth.uid() OR EXISTS (
      SELECT 1 FROM public.users WHERE user_id = auth.uid() AND role = 'admin'
    ))
  ));