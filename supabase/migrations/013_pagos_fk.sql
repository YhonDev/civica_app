-- Sprint 8 — Migración Lenguaje Ubicuo: Pagos — actualizar FKs
-- Renombra las columnas FK de pagos para alinearse con el nuevo lenguaje
-- Dependencias: 010_propietarios_a_residentes.sql, 012_cuotas_a_cobros.sql

ALTER TABLE pagos RENAME COLUMN cuota_id       TO cobro_id;
ALTER TABLE pagos RENAME COLUMN propietario_id TO residente_id;

-- Renombrar índices
ALTER INDEX idx_pagos_cuota       RENAME TO idx_pagos_cobro;
ALTER INDEX idx_pagos_propietario RENAME TO idx_pagos_residente;
