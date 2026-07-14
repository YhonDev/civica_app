-- Sprint 8 — Migración Lenguaje Ubicuo: Cuentas de Cartera → Planes de Cobro
-- Renombra la tabla cuentas_cartera a planes_de_cobro, actualiza columnas
-- y agrega la FK a periodos_cobro
-- Dependencias: 008_periodos_cobro.sql, 009_conjuntos_a_proyectos.sql, 010_propietarios_a_residentes.sql

ALTER TABLE cuentas_cartera RENAME TO planes_de_cobro;

-- Nuevas columnas de relación
ALTER TABLE planes_de_cobro ADD COLUMN casa_id      UUID REFERENCES casas(id);
ALTER TABLE planes_de_cobro ADD COLUMN residente_id UUID REFERENCES residentes(id);
ALTER TABLE planes_de_cobro ADD COLUMN proyecto_id  UUID NOT NULL REFERENCES proyectos(id);

-- Agregar valor_mensual calculado/personalizado
ALTER TABLE planes_de_cobro ADD COLUMN valor_mensual INTEGER;

-- Renombrar columnas existentes
ALTER TABLE planes_de_cobro RENAME COLUMN frecuencia TO modalidad;

-- Renombrar índices ANTES de dropear columnas (si no, PG los elimina automáticamente)
ALTER INDEX idx_cuentas_propietario RENAME TO idx_planes_residente;
ALTER INDEX idx_cuentas_tenant      RENAME TO idx_planes_tenant;

-- Eliminar columnas obsoletas
ALTER TABLE planes_de_cobro DROP COLUMN propietario_id;
ALTER TABLE planes_de_cobro DROP COLUMN conjunto_id;

-- FK a periodos_cobro (se creó en 008 sin FK, se agrega ahora)
ALTER TABLE periodos_cobro ADD CONSTRAINT fk_periodos_plan
  FOREIGN KEY (plan_id) REFERENCES planes_de_cobro(id);

-- Renombrar RLS policies
ALTER POLICY "service_role_all_cuentas_cartera" ON planes_de_cobro
  RENAME TO "service_role_all_planes_de_cobro";
