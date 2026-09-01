-- ═══════════════════════════════════════════════════════════
-- Cívica Pago — Reset Oficial de Base de Datos (Estado Cero Pre-Producción)
-- ═══════════════════════════════════════════════════════════

-- 1. Limpiar todas las transacciones, cobros, solicitudes y registros operativos
TRUNCATE TABLE solicitudes, tickets, pagos, cobros, periodos_cobro, planes_de_cobro, tenencias, actividad CASCADE;

-- 2. Mantener únicamente usuarios administradores principales
DELETE FROM usuarios WHERE rol NOT IN ('ADMIN', 'COBRADOR', 'RESIDENTE') AND email NOT LIKE '%admin%';

-- 3. Asegurar cuenta Admin VigiVecino
INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo, created_at, updated_at)
VALUES 
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
