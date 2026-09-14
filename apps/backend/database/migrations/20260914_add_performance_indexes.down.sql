-- Migración DOWN: Reversión de índices compuestos de rendimiento
-- Ciclo 5: Calidad Operativa y Migraciones Reversibles

DROP INDEX IF EXISTS idx_pagos_cobrador_fecha;
DROP INDEX IF EXISTS idx_pagos_residente_fecha;
DROP INDEX IF EXISTS idx_cobros_tenant_residente_estado;
DROP INDEX IF EXISTS idx_cobros_casa_estado;
DROP INDEX IF EXISTS idx_tenencias_casa_activa;
