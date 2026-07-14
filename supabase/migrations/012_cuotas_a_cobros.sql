-- Sprint 8 — Migración Lenguaje Ubicuo: Cuotas → Cobros
-- Renombra la tabla cuotas a cobros y actualiza su estructura
-- Dependencias: 008_periodos_cobro.sql, 010_propietarios_a_residentes.sql, 011_planes_de_cobro.sql

ALTER TABLE cuotas RENAME TO cobros;

-- NOTA: No se renombra sequence porque la PK usa gen_random_uuid(),
-- que no crea sequences automáticas.

-- Actualizar columnas
ALTER TABLE cobros RENAME COLUMN propietario_id TO residente_id;
ALTER TABLE cobros ADD COLUMN periodo_id UUID REFERENCES periodos_cobro(id);
ALTER TABLE cobros ADD COLUMN casa_id     UUID REFERENCES casas(id);

-- Actualizar CHECK constraint de estado para incluir nuevos valores
ALTER TABLE cobros DROP CONSTRAINT IF EXISTS cuotas_estado_check;
ALTER TABLE cobros ADD CONSTRAINT cobros_estado_check
  CHECK (estado IN ('PENDIENTE', 'PARCIAL', 'PAGADA', 'VENCIDA', 'EN_REVISION', 'ANULADO'));

-- Renombrar índices
ALTER INDEX idx_cuotas_propietario RENAME TO idx_cobros_residente;
ALTER INDEX idx_cuotas_tenant      RENAME TO idx_cobros_tenant;
ALTER INDEX idx_cuotas_estado      RENAME TO idx_cobros_estado;
ALTER INDEX idx_cuotas_vencimiento RENAME TO idx_cobros_vencimiento;

-- Renombrar RLS policies
ALTER POLICY "service_role_all_cuotas" ON cobros RENAME TO "service_role_all_cobros";
