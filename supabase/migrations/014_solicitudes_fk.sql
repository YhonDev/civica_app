-- Sprint 8 — Migración Lenguaje Ubicuo: Solicitudes — actualizar FKs
-- Renombra columnas FK de solicitudes y agrega nuevas relaciones
-- Dependencias: 010_propietarios_a_residentes.sql, 012_cuotas_a_cobros.sql

ALTER TABLE solicitudes RENAME COLUMN cuota_id TO cobro_id;

-- Nuevas columnas de relación
ALTER TABLE solicitudes ADD COLUMN casa_id      UUID REFERENCES casas(id);
ALTER TABLE solicitudes ADD COLUMN residente_id UUID REFERENCES residentes(id);

-- Renombrar índices
ALTER INDEX idx_solicitudes_cuota RENAME TO idx_solicitudes_cobro;

-- Agregar nuevo estado al enum
ALTER TYPE solicitud_estado ADD VALUE 'APROBADA';
