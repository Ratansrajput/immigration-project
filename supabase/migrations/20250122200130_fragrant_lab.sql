/*
  # Create admin user

  1. Changes
    - Insert admin user with email admin@immigration-portal.com and password 'admin123'
    - Set role as 'admin'
*/

-- Insert admin user into auth.users
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  confirmation_token,
  email_change_token_new,
  recovery_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  'ad4f6c66-6888-4c1d-9a3d-b8b9f1c16a6c',
  'authenticated',
  'authenticated',
  'admin@immigration-portal.com',
  crypt('admin123', gen_salt('bf')),
  now(),
  now(),
  now(),
  '',
  '',
  ''
) ON CONFLICT (id) DO NOTHING;

-- Insert admin profile
INSERT INTO public.users (user_id, full_name, role)
VALUES (
  'ad4f6c66-6888-4c1d-9a3d-b8b9f1c16a6c',
  'Admin User',
  'admin'
) ON CONFLICT (user_id) DO NOTHING;