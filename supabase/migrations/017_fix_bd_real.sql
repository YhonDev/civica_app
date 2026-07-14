-- Fix: Correcciones para alinear la BD real con el Lenguaje Ubicuo
-- Ejecutar DESPUÉS de las migraciones 008-016
-- 
-- Problemas resueltos:
--   1. Vista casa_estado_cartera bloqueaba DROP de propietario_id
--   2. proyecto_id NOT NULL fallaba por filas existentes con NULL
--   3. ALTER INDEX fallaban porque los índices no existen con esos nombres
--   4. Se requiere recrear la vista con los nuevos nombres

-- ═══════════════════════════════════════════════════════════
-- 1. ELIMINAR VISTA que bloquea las columnas antiguas
-- ═══════════════════════════════════════════════════════════

DROP VIEW IF EXISTS casa_estado_cartera CASCADE;

-- ═══════════════════════════════════════════════════════════
-- 2. CORREGIR MIGRACIÓN 011 — planes_de_cobro
-- ═══════════════════════════════════════════════════════════

-- 2a. Agregar proyecto_id como nullable, poblar desde conjunto_id, luego NOT NULL
-- (Si conjunto_id ya no existe porque fue renombrado, usar una subconsulta)
DO $$
BEGIN
  -- Verificar si proyecto_id ya fue agregado
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'planes_de_cobro' AND column_name = 'proyecto_id'
  ) THEN
    ALTER TABLE planes_de_cobro ADD COLUMN proyecto_id UUID REFERENCES proyectos(id);
  END IF;
END $$;

-- Poblar proyecto_id desde el tenant (búsqueda por defecto)
UPDATE planes_de_cobro pc
SET proyecto_id = (
  SELECT id FROM proyectos WHERE tenant_id = pc.tenant_id LIMIT 1
)
WHERE proyecto_id IS NULL;

-- Si aún hay NULLs, usar un proyecto por defecto
UPDATE planes_de_cobro pc
SET proyecto_id = (SELECT id FROM proyectos LIMIT 1)
WHERE proyecto_id IS NULL;

-- Agregar NOT NULL
ALTER TABLE planes_de_cobro ALTER COLUMN proyecto_id SET NOT NULL;

-- 2b. Agregar valor_mensual si no existe
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'planes_de_cobro' AND column_name = 'valor_mensual'
  ) THEN
    ALTER TABLE planes_de_cobro ADD COLUMN valor_mensual INTEGER;
  END IF;
END $$;

-- 2c. Renombrar frecuencia → modalidad si no se renombró
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'planes_de_cobro' AND column_name = 'frecuencia'
  ) THEN
    ALTER TABLE planes_de_cobro RENAME COLUMN frecuencia TO modalidad;
  END IF;
END $$;

-- 2d. Eliminar columnas obsoletas (ahora que la vista ya no depende de ellas)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'planes_de_cobro' AND column_name = 'conjunto_id'
  ) THEN
    ALTER TABLE planes_de_cobro DROP COLUMN IF EXISTS conjunto_id;
  END IF;
END $$;

-- ═══════════════════════════════════════════════════════════
-- 3. CORREGIR MIGRACIÓN 009 — Crear índices de proyectos
-- ═══════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_proyectos_tenant ON proyectos (tenant_id);
CREATE INDEX IF NOT EXISTS idx_etapas_proyecto ON etapas (proyecto_id);
CREATE INDEX IF NOT EXISTS idx_tarifas_proyecto ON tarifas (proyecto_id);
CREATE INDEX IF NOT EXISTS idx_montos_proyecto ON montos_predefinidos (proyecto_id);

-- ═══════════════════════════════════════════════════════════
-- 4. CORREGIR MIGRACIÓN 012 — Crear índices de cobros
-- ═══════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_cobros_residente ON cobros (residente_id);
CREATE INDEX IF NOT EXISTS idx_cobros_tenant ON cobros (tenant_id);
CREATE INDEX IF NOT EXISTS idx_cobros_estado ON cobros (estado);
CREATE INDEX IF NOT EXISTS idx_cobros_vencimiento ON cobros (fecha_vencimiento);

-- ═══════════════════════════════════════════════════════════
-- 5. CORREGIR MIGRACIÓN 011 — Índices de planes_de_cobro
-- ═══════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_planes_residente ON planes_de_cobro (residente_id);
CREATE INDEX IF NOT EXISTS idx_planes_tenant ON planes_de_cobro (tenant_id);

-- ═══════════════════════════════════════════════════════════
-- 6. CORREGIR MIGRACIÓN 013 — Índices de pagos
-- ═══════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_pagos_cobro ON pagos (cobro_id);
CREATE INDEX IF NOT EXISTS idx_pagos_residente ON pagos (residente_id);

-- ═══════════════════════════════════════════════════════════
-- 7. CORREGIR MIGRACIÓN 014 — Índices de solicitudes
-- ═══════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_solicitudes_cobro ON solicitudes (cobro_id);

-- ═══════════════════════════════════════════════════════════
-- 8. RECREAR VISTA casa_estado_cartera con nuevos nombres
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

COMMENT ON VIEW casa_estado_cartera IS 'Vista consolidada del estado de cartera por casa, usando nomenclatura del Lenguaje Ubicuo (Residente, Cobro, Proyecto, PlanDeCobro)';
