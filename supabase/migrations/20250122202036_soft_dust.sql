/*
  # Fix program policies for admin access

  1. Changes
    - Update program policies to properly handle admin access
    - Add insert policy for admin users
    - Simplify policy conditions
  
  2. Security
    - Maintain RLS on programs table
    - Ensure proper admin access control
*/

-- Drop existing program policies
DROP POLICY IF EXISTS "programs_admin_access" ON public.programs;
DROP POLICY IF EXISTS "programs_public_read" ON public.programs;

-- Create new program policies
CREATE POLICY "programs_read"
  ON public.programs
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "programs_admin_write"
  ON public.programs
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

CREATE POLICY "programs_admin_modify"
  ON public.programs
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );

CREATE POLICY "programs_admin_delete"
  ON public.programs
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE users.id = auth.uid()
      AND users.role = 'admin'
    )
  );