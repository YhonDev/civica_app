-- ═══════════════════════════════════════════════════════════
-- Cívica Pago — Datos de prueba
-- Ejecutar DESPUÉS de schema.sql
--
-- Contraseña por defecto: civica2026!
-- Hash bcrypt: $2b$10$TUYHytv/xN6qysjxY1O4te0bIQrTyoVKUl2WrGLeDdQ2nhfqeVhPi
-- ═══════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════
-- 1. Proyecto demo
-- ═══════════════════════════════════════════════════════════
INSERT INTO proyectos (id, nombre, tenant_id, created_at, updated_at)
VALUES (
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  'Proyecto Demo',
  '00000000-0000-0000-0000-000000000001',
  NOW(), NOW()
);

-- ═══════════════════════════════════════════════════════════
-- 2. Residentes
-- ═══════════════════════════════════════════════════════════
INSERT INTO residentes (id, tipo, nombre, telefono, email, tenant_id, created_at, updated_at)
VALUES
  ('0a3f574e-a99d-444f-a581-2ac6b8238529', 'PROPIETARIO', 'Juan Pérez',    '3001234567', 'mzA_casa101_1et@civica.com', '00000000-0000-0000-0000-000000000001', NOW(), NOW()),
  ('ba165776-b2a4-427a-8145-5c35afe679dd', 'PROPIETARIO', 'María García',  '3001234568', 'mzA_casa102_1et@civica.com', '00000000-0000-0000-0000-000000000001', NOW(), NOW()),
  ('f0ce5abc-1ff1-45d2-84b0-587370ca766a', 'PROPIETARIO', 'Carlos López', '3001234569', 'mzA_casa103_1et@civica.com', '00000000-0000-0000-0000-000000000001', NOW(), NOW());

-- ═══════════════════════════════════════════════════════════
-- 3. Usuarios (password: civica2026!)
-- ═══════════════════════════════════════════════════════════
INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo, created_at, updated_at)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 'admin@civica.com',     '$2b$10$TUYHytv/xN6qysjxY1O4te0bIQrTyoVKUl2WrGLeDdQ2nhfqeVhPi', 'Admin Cívica',  'ADMIN',     NULL, '00000000-0000-0000-0000-000000000001', true, NOW(), NOW()),
  ('a0000000-0000-0000-0000-000000000002', 'cobrador@civica.com',  '$2b$10$TUYHytv/xN6qysjxY1O4te0bIQrTyoVKUl2WrGLeDdQ2nhfqeVhPi', 'Juan Cobrador', 'COBRADOR',  NULL, '00000000-0000-0000-0000-000000000001', true, NOW(), NOW()),
  ('a0000000-0000-0000-0000-000000000003', 'mzA_casa101_1et@civica.com', '$2b$10$TUYHytv/xN6qysjxY1O4te0bIQrTyoVKUl2WrGLeDdQ2nhfqeVhPi', 'Juan Pérez',    'PROPIETARIO', '0a3f574e-a99d-444f-a581-2ac6b8238529', '00000000-0000-0000-0000-000000000001', true, NOW(), NOW()),
  ('a0000000-0000-0000-0000-000000000004', 'mzA_casa102_1et@civica.com', '$2b$10$TUYHytv/xN6qysjxY1O4te0bIQrTyoVKUl2WrGLeDdQ2nhfqeVhPi', 'María García',  'PROPIETARIO', 'ba165776-b2a4-427a-8145-5c35afe679dd', '00000000-0000-0000-0000-000000000001', true, NOW(), NOW()),
  ('a0000000-0000-0000-0000-000000000005', 'mzA_casa103_1et@civica.com', '$2b$10$TUYHytv/xN6qysjxY1O4te0bIQrTyoVKUl2WrGLeDdQ2nhfqeVhPi', 'Carlos López',  'PROPIETARIO', 'f0ce5abc-1ff1-45d2-84b0-587370ca766a', '00000000-0000-0000-0000-000000000001', true, NOW(), NOW());
