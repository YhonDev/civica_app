-- ═══════════════════════════════════════════════════════════
-- Cívica Pago — Datos de prueba (Limpio)
-- Ejecutar DESPUÉS de schema.sql
--
-- Contraseña por defecto: civica2026!
-- Hash bcrypt: $2b$10$TUYHytv/xN6qysjxY1O4te0bIQrTyoVKUl2WrGLeDdQ2nhfqeVhPi
-- ═══════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════
-- 1. Tenant Inicial (El sistema siempre necesita un tenant por defecto)
-- ═══════════════════════════════════════════════════════════
-- (El tenant se inserta desde schema.sql si es necesario, pero asumiendo que seed.sql no lo hace, 
--  el schema.sql ya lo insertó: '00000000-0000-0000-0000-000000000001')

-- ═══════════════════════════════════════════════════════════
-- 2. Supabase Auth (auth.users) - SOLO ADMIN
-- ═══════════════════════════════════════════════════════════
DELETE FROM auth.identities WHERE user_id IN ('a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000005');
DELETE FROM auth.users WHERE id IN ('a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000005');

INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, created_at, updated_at)
VALUES
  ('a0000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'admin@civica.com', '$2b$10$TUYHytv/xN6qysjxY1O4te0bIQrTyoVKUl2WrGLeDdQ2nhfqeVhPi', NOW(), NOW(), NOW());

INSERT INTO auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
VALUES
  (gen_random_uuid(), 'a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', format('{"sub":"%s","email":"%s"}', 'a0000000-0000-0000-0000-000000000001', 'admin@civica.com')::jsonb, 'email', NOW(), NOW(), NOW());

-- ═══════════════════════════════════════════════════════════
-- 3. Usuarios (perfiles públicos) - SOLO ADMIN
-- ═══════════════════════════════════════════════════════════
INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo, created_at, updated_at)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 'admin@civica.com',     '$2b$10$TUYHytv/xN6qysjxY1O4te0bIQrTyoVKUl2WrGLeDdQ2nhfqeVhPi', 'Admin Cívica',  'ADMIN', NULL, '00000000-0000-0000-0000-000000000001', true, NOW(), NOW());
