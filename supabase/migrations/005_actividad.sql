-- Sprint 5 — Admin Dashboard: actividad table for event feed
-- Dependencias: 001_community.sql (conjuntos), 002_iam.sql (usuarios)

CREATE TABLE actividad (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL,
  tipo            VARCHAR(50) NOT NULL,
  descripcion     TEXT NOT NULL,
  usuario_nombre  VARCHAR(255) NOT NULL,
  usuario_id      UUID NOT NULL,
  metadata        JSONB DEFAULT '{}',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_actividad_tenant_created
  ON actividad(tenant_id, created_at DESC);

-- ── RLS ─────────────────────────────────────────────────
ALTER TABLE actividad ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_role_all_actividad" ON actividad FOR ALL TO service_role USING (true);
