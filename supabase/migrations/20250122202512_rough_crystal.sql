/*
  # Application Process Enhancement

  1. New Tables
    - application_documents: Store uploaded documents for applications
    - application_questionnaire: Store applicant responses
  
  2. Changes
    - Add document status tracking
    - Add questionnaire responses
    - Add application status workflow
    
  3. Security
    - Enable RLS
    - Add appropriate policies
*/

-- Create application documents table
CREATE TABLE IF NOT EXISTS public.application_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID REFERENCES public.applications(id),
  document_type TEXT NOT NULL,
  file_path TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  admin_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Create application questionnaire table
CREATE TABLE IF NOT EXISTS public.application_questionnaire (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID REFERENCES public.applications(id),
  questions JSONB NOT NULL,
  answers JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Add new columns to applications table
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS questionnaire_completed BOOLEAN DEFAULT false;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS documents_completed BOOLEAN DEFAULT false;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS admin_notes TEXT;
ALTER TABLE public.applications ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- Enable RLS
ALTER TABLE public.application_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.application_questionnaire ENABLE ROW LEVEL SECURITY;

-- Create policies for application documents
CREATE POLICY "documents_read"
  ON public.application_documents
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.applications
      WHERE applications.id = application_documents.application_id
      AND (
        applications.user_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM auth.users
          WHERE auth.users.id = auth.uid()
          AND auth.users.email = 'admin@immigration-portal.com'
        )
      )
    )
  );

CREATE POLICY "documents_insert"
  ON public.application_documents
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.applications
      WHERE applications.id = application_documents.application_id
      AND applications.user_id = auth.uid()
    )
  );

-- Create policies for application questionnaire
CREATE POLICY "questionnaire_read"
  ON public.application_questionnaire
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.applications
      WHERE applications.id = application_questionnaire.application_id
      AND (
        applications.user_id = auth.uid()
        OR EXISTS (
          SELECT 1 FROM auth.users
          WHERE auth.users.id = auth.uid()
          AND auth.users.email = 'admin@immigration-portal.com'
        )
      )
    )
  );

CREATE POLICY "questionnaire_insert"
  ON public.application_questionnaire
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.applications
      WHERE applications.id = application_questionnaire.application_id
      AND applications.user_id = auth.uid()
    )
  );

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_application_documents_application_id 
  ON public.application_documents(application_id);
CREATE INDEX IF NOT EXISTS idx_application_questionnaire_application_id 
  ON public.application_questionnaire(application_id);