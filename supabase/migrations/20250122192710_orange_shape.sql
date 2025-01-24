-- Drop existing policies
DROP POLICY IF EXISTS "Enable insert for authentication users only" ON public.users;
DROP POLICY IF EXISTS "Enable read access for users" ON public.users;

-- Create new policies without recursion
CREATE POLICY "Enable insert for authenticated users only"
  ON public.users
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Enable read access for all authenticated users"
  ON public.users
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Update other table policies to avoid recursion
ALTER POLICY "Admin can manage programs" ON public.programs
  USING ((SELECT role FROM auth.users WHERE id = auth.uid()) = 'admin');

ALTER POLICY "Users can view their applications" ON public.applications
  USING (
    user_id = auth.uid() 
    OR 
    (SELECT role FROM auth.users WHERE id = auth.uid()) = 'admin'
  );

ALTER POLICY "Users can manage their documents" ON public.documents
  USING (
    EXISTS (
      SELECT 1 FROM public.applications 
      WHERE applications.id = documents.application_id 
      AND (
        applications.user_id = auth.uid() 
        OR 
        (SELECT role FROM auth.users WHERE id = auth.uid()) = 'admin'
      )
    )
  );

ALTER POLICY "Users can view and send messages" ON public.messages
  USING (
    EXISTS (
      SELECT 1 FROM public.applications 
      WHERE applications.id = messages.application_id 
      AND (
        applications.user_id = auth.uid() 
        OR 
        (SELECT role FROM auth.users WHERE id = auth.uid()) = 'admin'
      )
    )
  );