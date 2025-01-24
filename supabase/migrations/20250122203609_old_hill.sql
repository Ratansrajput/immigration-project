/*
  # Create storage bucket for documents

  1. New Storage
    - Create 'documents' bucket for storing application documents
  
  2. Security
    - Enable RLS on the bucket
    - Add policies for authenticated users to read/write their own documents
    - Add policies for admins to access all documents
*/

-- Create storage bucket for documents
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', false);

-- Enable RLS
CREATE POLICY "Documents are accessible by application owner"
  ON storage.objects
  FOR ALL
  TO authenticated
  USING (
    bucket_id = 'documents'
    AND (
      -- Extract user_id from path (format: user_id/application_id/filename)
      (storage.foldername(name))[1] = auth.uid()::text
      OR
      -- Allow admin access
      auth.jwt() ->> 'email' = 'admin@immigration-portal.com'
    )
  );

-- Create policy for inserting objects
CREATE POLICY "Users can upload their own documents"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'documents'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );