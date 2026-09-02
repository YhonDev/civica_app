-- ═══════════════════════════════════════════════════════════
-- Cívica Pago — Reset Oficial de Base de Datos (Solo Admin)
-- Limpia todos los datos simulados/mock y deja la base de datos limpia
-- lista para cargar proyectos, casas, cobradores y residentes reales.
-- ═══════════════════════════════════════════════════════════

BEGIN;

-- 1. Limpiar todas las transacciones, operaciones y registros
TRUNCATE TABLE 
  solicitudes, 
  tickets, 
  pagos, 
  cobros, 
  periodos_cobro, 
  planes_de_cobro, 
  montos_predefinidos,
  tarifas,
  asignaciones_etapa,
  tenencias, 
  residentes,
  casas, 
  manzanas, 
  etapas, 
  proyectos, 
  notificaciones,
  actividad 
CASCADE;

-- 2. Eliminar usuarios que no sean ADMIN
DELETE FROM usuarios WHERE rol != 'ADMIN';

-- 3. Asegurar cuenta Admin Cívica principal
INSERT INTO usuarios (id, email, password_hash, nombre, rol, residente_id, tenant_id, activo, created_at, updated_at)
VALUES 
(
  'f6000000-0000-0000-0000-000000000001',
  'admin',
  '$2b$10$xT9obvJfjrh3W/9VMO88q.oJR.alFFm0fZ2.ifv2Q47pKiWJAPYie',
  'Admin Cívica',
  'ADMIN',
  NULL,
  '00000000-0000-0000-0000-000000000001',
  true,
  NOW(),
  NOW()
)
ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email,
  password_hash = EXCLUDED.password_hash,
  activo = true;

COMMIT;
