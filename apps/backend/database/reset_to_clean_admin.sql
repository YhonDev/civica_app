-- ═══════════════════════════════════════════════════════════
-- Cívica Pago — Reset Completo a Estado Cero (Solo Admin)
-- ═══════════════════════════════════════════════════════════

-- 1. Limpiar todas las transacciones, cobros, solicitudes y residentes
TRUNCATE TABLE solicitudes, tickets, pagos, cobros, periodos_cobro, planes_de_cobro, tenencias, residentes CASCADE;

-- 2. Limpiar usuarios y mantener únicamente Admin
DELETE FROM usuarios WHERE rol != 'ADMIN';

-- 3. Insertar / Actualizar cuentas de Admin (soporta 'admin@civica.com', 'admin@vigivecino.com', 'admin')
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
),
(
    'a0000000-0000-0000-0000-000000000003',
    'admin',
    '$2b$10$gsysEf3amteFZE5PMRz6BeH8LM7.AYcbXCZd0WJ5oOFs3ZHSXnx8u',
    'Admin',
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

-- 4. Estructura física base (Urbanización San Sebastián -> Etapa 1 -> Manzana A -> Casas 1, 2, 3)
INSERT INTO proyectos (id, nombre, tenant_id, recordatorios_automaticos, permite_pagos_parciales, modo_mantenimiento, created_at, updated_at)
VALUES (
    '00000000-0000-0000-0000-000000000002',
    'Urbanización San Sebastián',
    '00000000-0000-0000-0000-000000000001',
    true,
    true,
    false,
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

INSERT INTO etapas (id, nombre, proyecto_id, created_at)
VALUES (
    '00000000-0000-0000-0000-000000000003',
    'Etapa 1',
    '00000000-0000-0000-0000-000000000002',
    NOW()
) ON CONFLICT (id) DO NOTHING;

INSERT INTO manzanas (id, nombre, etapa_id, created_at)
VALUES (
    '00000000-0000-0000-0000-000000000004',
    'Manzana A',
    '00000000-0000-0000-0000-000000000003',
    NOW()
) ON CONFLICT (id) DO NOTHING;

INSERT INTO casas (id, direccion_interna, manzana_id, created_at)
VALUES
    ('49c14c63-c94f-4210-8f80-1ba3798a12b6', 'Casa 1', '00000000-0000-0000-0000-000000000004', NOW()),
    ('774de888-a210-4991-9b1a-2393326d1061', 'Casa 2', '00000000-0000-0000-0000-000000000004', NOW()),
    ('ea2ffc2d-9c2b-47d0-857d-ae1ebe654744', 'Casa 3', '00000000-0000-0000-0000-000000000004', NOW())
ON CONFLICT (id) DO NOTHING;

-- 5. Tarifa vigente oficial del conjunto ($40.000 COP)
INSERT INTO tarifas (id, tenant_id, proyecto_id, modalidad, monto, fecha_vigencia, activa, created_at, updated_at)
VALUES
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'MENSUAL', 4000000, '2026-01-01', true, NOW(), NOW()),
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'QUINCENAL', 2000000, '2026-01-01', true, NOW(), NOW()),
    (gen_random_uuid(), '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'SEMANAL', 1000000, '2026-01-01', true, NOW(), NOW())
ON CONFLICT DO NOTHING;
