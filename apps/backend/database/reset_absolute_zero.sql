-- ═══════════════════════════════════════════════════════════
-- Cívica Pago — Reset Absoluto a Cero Total (Solo Admin y Tenant)
-- ═══════════════════════════════════════════════════════════

-- 1. Limpieza absoluta de todas las tablas de dominio y estructura física
TRUNCATE TABLE 
    solicitudes, 
    tickets, 
    pagos, 
    cobros, 
    periodos_cobro, 
    planes_de_cobro, 
    tenencias, 
    residentes,
    montos_predefinidos,
    tarifas,
    casas,
    manzanas,
    etapas,
    proyectos
CASCADE;

-- 2. Limpiar usuarios y mantener únicamente Admin
DELETE FROM usuarios WHERE rol != 'ADMIN';

-- Si existe el esquema auth (Supabase / Local)
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'auth' AND tablename = 'users') THEN
        DELETE FROM auth.identities WHERE user_id::text NOT IN (SELECT id::text FROM usuarios WHERE rol = 'ADMIN');
        DELETE FROM auth.users WHERE email NOT IN ('admin@civica.com', 'admin@vigivecino.com', 'admin');
    END IF;
END $$;

-- 3. Asegurar cuenta Admin activa
INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo, created_at, updated_at)
VALUES 
(
    'a0000000-0000-0000-0000-000000000001',
    'admin@civica.com',
    '$2b$10$gsysEf3amteFZE5PMRz6BeH8LM7.AYcbXCZd0WJ5oOFs3ZHSXnx8u',
    'Admin Cívica',
    'ADMIN',
    NULL,
    '00000000-0000-0000-0000-000000000001',
    true,
    NOW(),
    NOW()
),
(
    'a0000000-0000-0000-0000-000000000002',
    'admin@vigivecino.com',
    '$2b$10$gsysEf3amteFZE5PMRz6BeH8LM7.AYcbXCZd0WJ5oOFs3ZHSXnx8u',
    'Admin VigiVecino',
    'ADMIN',
    NULL,
    '00000000-0000-0000-0000-000000000001',
    true,
    NOW(),
    NOW()
)
ON CONFLICT (id) DO UPDATE SET
    password_hash = EXCLUDED.password_hash,
    activo = true;
