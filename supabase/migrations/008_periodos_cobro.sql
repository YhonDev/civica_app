-- Sprint 8 — Migración Lenguaje Ubicuo: Periodos de Cobro
-- Nueva tabla que organiza los cobros en períodos mensuales
-- Dependencias: 011_cuentas_cartera_a_planes_de_cobro.sql (planes_de_cobro)
-- La FK a planes_de_cobro se agrega en la migración 011

CREATE TABLE periodos_cobro (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id        UUID NOT NULL,
  mes            INTEGER NOT NULL CHECK (mes BETWEEN 1 AND 12),
  anio           INTEGER NOT NULL,
  fecha_inicio   DATE NOT NULL,
  fecha_fin      DATE NOT NULL,
  estado         VARCHAR(20) NOT NULL DEFAULT 'ACTIVO'
                 CHECK (estado IN ('ACTIVO', 'CERRADO')),
  tenant_id      UUID NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (plan_id, mes, anio)
);

CREATE INDEX idx_periodos_plan   ON periodos_cobro (plan_id);
CREATE INDEX idx_periodos_tenant ON periodos_cobro (tenant_id);

-- ── RLS ─────────────────────────────────────────────────
ALTER TABLE periodos_cobro ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_role_all_periodos_cobro" ON periodos_cobro FOR ALL TO service_role USING (true);
