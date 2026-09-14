-- Migración: Índices compuestos estratégicos para optimización de consultas de alto volumen
-- Ciclo 3: Rendimiento de Backend y Base de Datos
--
-- UP:
-- 1. Pagos por cobrador y fecha (usado en findByCobrador y findByCobradorToday)
CREATE INDEX IF NOT EXISTS idx_pagos_cobrador_fecha
  ON pagos (tenant_id, cobrador_id, fecha_pago DESC);

-- 2. Pagos por residente y fecha (usado en findByPropietario e historial)
CREATE INDEX IF NOT EXISTS idx_pagos_residente_fecha
  ON pagos (tenant_id, residente_id, fecha_pago DESC);

-- 3. Cobros por residente y estado (usado en listado de cuotas y cálculo de mora)
CREATE INDEX IF NOT EXISTS idx_cobros_tenant_residente_estado
  ON cobros (tenant_id, residente_id, estado);

-- 4. Cobros por casa y estado (usado en CarteraViviendaResumenQuery y filtros por vivienda)
CREATE INDEX IF NOT EXISTS idx_cobros_casa_estado
  ON cobros (casa_id, estado);

-- 5. Tenencias activas por casa (usado en JOINs para vincular residente actual con vivienda)
CREATE INDEX IF NOT EXISTS idx_tenencias_casa_activa
  ON tenencias (casa_id) WHERE fecha_fin IS NULL;

-- DOWN (Reversible):
-- DROP INDEX IF EXISTS idx_pagos_cobrador_fecha;
-- DROP INDEX IF EXISTS idx_pagos_residente_fecha;
-- DROP INDEX IF EXISTS idx_cobros_tenant_residente_estado;
-- DROP INDEX IF EXISTS idx_cobros_casa_estado;
-- DROP INDEX IF EXISTS idx_tenencias_casa_activa;
