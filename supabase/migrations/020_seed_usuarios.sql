-- Sprint 8 — Seed: Usuarios y Residentes para login
-- Ejecutar DESPUÉS de 019_cleanup_tenencias_propietarios.sql
--
-- Contraseña por defecto para todos los usuarios: civica2026!
-- Los usuarios ADMIN y COBRADOR pueden cambiar contraseñas desde el panel.
--
-- NOTA: Las contraseñas se almacenan como hash bcrypt.
-- Para regenerar: node -e "const bcrypt = require('bcrypt'); console.log(bcrypt.hashSync('civica2026!', bcrypt.genSaltSync(10)));"

-- ═══════════════════════════════════════════════════════════
-- 1. Crear Tenant por defecto
-- ═══════════════════════════════════════════════════════════
-- NOTA: El tenant se maneja a nivel de aplicación (Supabase).
-- Se usa un UUID fijo para desarrollo.
INSERT INTO proyectos (id, nombre, tenant_id, created_at, updated_at)
VALUES (
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
  'Proyecto Demo',
  '00000000-0000-0000-0000-000000000001',
  NOW(),
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- ═══════════════════════════════════════════════════════════
-- 2. Crear Residentes (para usuarios PROPIETARIO/RESIDENTE)
-- ═══════════════════════════════════════════════════════════
INSERT INTO residentes (id, tipo, nombre, telefono, email, tenant_id, created_at, updated_at)
VALUES
  ('0a3f574e-a99d-444f-a581-2ac6b8238529', 'PROPIETARIO', 'Juan Pérez', '3001234567', 'mzA_casa101_1et@civica.com', '00000000-0000-0000-0000-000000000001', NOW(), NOW()),
  ('ba165776-b2a4-427a-8145-5c35afe679dd', 'PROPIETARIO', 'María García', '3001234568', 'mzA_casa102_1et@civica.com', '00000000-0000-0000-0000-000000000001', NOW(), NOW()),
  ('f0ce5abc-1ff1-45d2-84b0-587370ca766a', 'PROPIETARIO', 'Carlos López', '3001234569', 'mzA_casa103_1et@civica.com', '00000000-0000-0000-0000-000000000001', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- ═══════════════════════════════════════════════════════════
-- 3. Crear Usuarios con login
-- ═══════════════════════════════════════════════════════════
-- Password hash para 'civica2026!' (bcrypt, salt rounds=10)
-- Generado con: require('bcrypt').hashSync('civica2026!', 10)

INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo, created_at, updated_at)
VALUES
  -- Admin
  (
    'a0000000-0000-0000-0000-000000000001',
    'admin@civica.com',
    '$2b$10$TUYHytv/xN6qysjxY1O4te0bIQrTyoVKUl2WrGLeDdQ2nhfqeVhPi',
    'Admin Cívica',
    'ADMIN',
    NULL,
    '00000000-0000-0000-0000-000000000001',
    true,
    NOW(),
    NOW()
  ),
  -- Cobrador
  (
    'a0000000-0000-0000-0000-000000000002',
    'cobrador@civica.com',
    '$2b$10$TUYHytv/xN6qysjxY1O4te0bIQrTyoVKUl2WrGLeDdQ2nhfqeVhPi',
    'Juan Cobrador',
    'COBRADOR',
    NULL,
    '00000000-0000-0000-0000-000000000001',
    true,
    NOW(),
    NOW()
  ),
  -- Propietarios (con residente_id)
  (
    'a0000000-0000-0000-0000-000000000003',
    'mzA_casa101_1et@civica.com',
    '$2b$10$TUYHytv/xN6qysjxY1O4te0bIQrTyoVKUl2WrGLeDdQ2nhfqeVhPi',
    'Juan Pérez',
    'PROPIETARIO',
    '0a3f574e-a99d-444f-a581-2ac6b8238529',
    '00000000-0000-0000-0000-000000000001',
    true,
    NOW(),
    NOW()
  ),
  (
    'a0000000-0000-0000-0000-000000000004',
    'mzA_casa102_1et@civica.com',
    '$2b$10$TUYHytv/xN6qysjxY1O4te0bIQrTyoVKUl2WrGLeDdQ2nhfqeVhPi',
    'María García',
    'PROPIETARIO',
    'ba165776-b2a4-427a-8145-5c35afe679dd',
    '00000000-0000-0000-0000-000000000001',
    true,
    NOW(),
    NOW()
  ),
  (
    'a0000000-0000-0000-0000-000000000005',
    'mzA_casa103_1et@civica.com',
    '$2b$10$TUYHytv/xN6qysjxY1O4te0bIQrTyoVKUl2WrGLeDdQ2nhfqeVhPi',
    'Carlos López',
    'PROPIETARIO',
    'f0ce5abc-1ff1-45d2-84b0-587370ca766a',
    '00000000-0000-0000-0000-000000000001',
    true,
    NOW(),
    NOW()
  )
ON CONFLICT (email) DO NOTHING;
