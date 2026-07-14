-- ═══════════════════════════════════════════════════════════
-- Sprint 8 — Migración Consolidada: FKs y limpieza
-- Ejecutar DESPUÉS de 017_fix_bd_real.sql
-- 
-- Incluye: 013, 014, 015, 016 + limpieza final
-- Maneja la BD real (índices con nombres PK, no los esperados)
-- ═══════════════════════════════════════════════════════════

BEGIN;

-- ═══════════════════════════════════════════════════════════
-- 1. PAGOS: Renombrar FKs (migración 013) — idempotente
-- ═══════════════════════════════════════════════════════════
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'pagos' AND column_name = 'cuota_id'
  ) THEN
    ALTER TABLE pagos RENAME COLUMN cuota_id TO cobro_id;
  END IF;
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'pagos' AND column_name = 'propietario_id'
  ) THEN
    ALTER TABLE pagos RENAME COLUMN propietario_id TO residente_id;
  END IF;
END $$;

-- Crear índices reales (los viejos no existían)
CREATE INDEX IF NOT EXISTS idx_pagos_cobro ON pagos (cobro_id);
CREATE INDEX IF NOT EXISTS idx_pagos_residente ON pagos (residente_id);

-- ═══════════════════════════════════════════════════════════
-- 2. SOLICITUDES: Renombrar FK + nuevas columnas (migración 014)
-- ═══════════════════════════════════════════════════════════
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'solicitudes' AND column_name = 'cuota_id'
  ) THEN
    ALTER TABLE solicitudes RENAME COLUMN cuota_id TO cobro_id;
  END IF;
END $$;

-- Nuevas columnas de relación (si no existen)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'solicitudes' AND column_name = 'casa_id'
  ) THEN
    ALTER TABLE solicitudes ADD COLUMN casa_id UUID REFERENCES casas(id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'solicitudes' AND column_name = 'residente_id'
  ) THEN
    ALTER TABLE solicitudes ADD COLUMN residente_id UUID REFERENCES residentes(id);
  END IF;

  -- Agregar pago_id si no existe (entidad Solicitud lo requiere)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'solicitudes' AND column_name = 'pago_id'
  ) THEN
    ALTER TABLE solicitudes ADD COLUMN pago_id UUID REFERENCES pagos(id);
  END IF;
END $$;

-- Crear índices reales
CREATE INDEX IF NOT EXISTS idx_solicitudes_cobro ON solicitudes (cobro_id);
CREATE INDEX IF NOT EXISTS idx_solicitudes_residente ON solicitudes (residente_id);
CREATE INDEX IF NOT EXISTS idx_solicitudes_casa ON solicitudes (casa_id);

-- NOTA: enum solicitud_estado no existe en BD real, se omite

-- ═══════════════════════════════════════════════════════════
-- 3. USUARIOS: Renombrar FK (migración 015) — idempotente
-- ═══════════════════════════════════════════════════════════
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'usuarios' AND column_name = 'propietario_id'
  ) THEN
    ALTER TABLE usuarios RENAME COLUMN propietario_id TO residente_id;
  END IF;
END $$;

-- Agregar FK formal a residentes
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_name = 'usuarios' AND constraint_name = 'fk_usuarios_residente'
  ) THEN
    ALTER TABLE usuarios ADD CONSTRAINT fk_usuarios_residente
      FOREIGN KEY (residente_id) REFERENCES residentes(id) ON DELETE SET NULL;
  END IF;
END $$;

-- ═══════════════════════════════════════════════════════════
-- 4. PLANES_DE_COBRO: Eliminar columna propietario_id (ya migrada)
-- ═══════════════════════════════════════════════════════════
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'planes_de_cobro' AND column_name = 'propietario_id'
  ) THEN
    ALTER TABLE planes_de_cobro DROP COLUMN propietario_id;
  END IF;
END $$;

-- ═══════════════════════════════════════════════════════════
-- 5. HISTORIAL_RESIDENCIAS (migración 016)
-- ═══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS historial_residencias (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  residente_id    UUID NOT NULL REFERENCES residentes(id) ON DELETE CASCADE,
  casa_id         UUID NOT NULL REFERENCES casas(id) ON DELETE CASCADE,
  fecha_inicio    DATE NOT NULL,
  fecha_fin       DATE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Migrar datos desde tenencias (solo si historial_residencias está vacía)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM historial_residencias LIMIT 1) THEN
    INSERT INTO historial_residencias (residente_id, casa_id, fecha_inicio, fecha_fin, created_at)
SELECT t.propietario_id, t.casa_id, t.fecha_inicio, t.fecha_fin, t.created_at
FROM tenencias t;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_historial_residente ON historial_residencias (residente_id);
CREATE INDEX IF NOT EXISTS idx_historial_casa      ON historial_residencias (casa_id);

-- RLS
ALTER TABLE historial_residencias ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'historial_residencias' AND policyname = 'service_role_all_historial'
  ) THEN
    CREATE POLICY "service_role_all_historial" ON historial_residencias FOR ALL TO service_role USING (true);
  END IF;
END $$;

-- ═══════════════════════════════════════════════════════════
-- 6. LIMPIEZA: Tabla propietarios
-- ═══════════════════════════════════════════════════════════
-- Solo eliminar si ya no tiene dependencias
-- (Las FKs de pagos, solicitudes, usuarios ya apuntan a residentes)
-- NOTA: tenencias aún referencia propietarios, se conserva por ahora
-- DROP TABLE IF EXISTS propietarios CASCADE;

-- ═══════════════════════════════════════════════════════════
-- 7. RECREAR VISTA casa_estado_cartera
-- ═══════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW casa_estado_cartera AS
SELECT
  c.id AS casa_id,
  c.direccion_interna AS direccion,
  m.id AS manzana_id,
  m.nombre AS manzana_nombre,
  e.id AS etapa_id,
  e.nombre AS etapa_nombre,
  pj.id AS proyecto_id,
  pj.nombre AS proyecto_nombre,
  pj.tenant_id,
  r.id AS residente_actual_id,
  r.nombre AS residente_nombre,
  r.telefono AS residente_telefono,
  r.email AS residente_email,
  r.tipo AS residente_tipo,
  pc.modalidad AS modalidad,
  COUNT(co.id) AS total_cobros,
  COUNT(co.id) FILTER (WHERE co.estado = 'PAGADA') AS cobros_pagados,
  COUNT(co.id) FILTER (WHERE co.estado IN ('PENDIENTE', 'PARCIAL')) AS cobros_pendientes,
  COUNT(co.id) FILTER (WHERE co.estado = 'VENCIDA') AS cobros_vencidos,
  CASE
    WHEN COUNT(co.id) = 0 THEN 'SIN_COBROS'
    WHEN COUNT(co.id) FILTER (WHERE co.estado = 'VENCIDA') > 0 THEN 'EN_MORA'
    WHEN COUNT(co.id) FILTER (WHERE co.estado IN ('PENDIENTE', 'PARCIAL')) > 0 THEN 'PENDIENTE'
    ELSE 'AL_DIA'
  END AS estado_cartera,
  COALESCE(SUM(co.monto - co.monto_pagado) FILTER (WHERE co.estado = 'VENCIDA'), 0) AS saldo_mora_centavos
FROM casas c
JOIN manzanas m ON m.id = c.manzana_id
JOIN etapas e ON e.id = m.etapa_id
JOIN proyectos pj ON pj.id = e.proyecto_id
LEFT JOIN tenencias t ON t.casa_id = c.id AND t.fecha_fin IS NULL
LEFT JOIN residentes r ON r.id = t.propietario_id
LEFT JOIN planes_de_cobro pc ON pc.residente_id = r.id AND pc.activa = true
LEFT JOIN cobros co ON co.residente_id = r.id
GROUP BY c.id, c.direccion_interna, m.id, m.nombre, e.id, e.nombre,
         pj.id, pj.nombre, pj.tenant_id, r.id, r.nombre, r.telefono,
         r.email, r.tipo, pc.modalidad
ORDER BY e.nombre, m.nombre, c.direccion_interna;

COMMIT;
