-- Sprint 4 — Solicitudes de Revisión
-- Dependencias: 002_iam.sql (usuarios), 003_ledger.sql (cuotas)

CREATE TYPE solicitud_estado AS ENUM ('PENDIENTE', 'EN_REVISION', 'RESUELTA', 'RECHAZADA');

CREATE TABLE solicitudes (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id        UUID NOT NULL,
  usuario_id       UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  cuota_id         UUID NOT NULL REFERENCES cuotas(id) ON DELETE CASCADE,
  nro_recibo       VARCHAR(20) NOT NULL,
  tipo             VARCHAR(255) NOT NULL,
  descripcion      TEXT NOT NULL,
  estado           solicitud_estado NOT NULL DEFAULT 'EN_REVISION',
  fecha            TIMESTAMPTZ NOT NULL DEFAULT now(),
  respuesta        TEXT,
  fecha_respuesta  TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_solicitudes_tenant ON solicitudes (tenant_id);
CREATE INDEX idx_solicitudes_usuario ON solicitudes (usuario_id);
CREATE INDEX idx_solicitudes_cuota ON solicitudes (cuota_id);
CREATE UNIQUE INDEX idx_solicitudes_nro_recibo ON solicitudes (nro_recibo);

-- ── RLS ─────────────────────────────────────────────────
ALTER TABLE solicitudes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_role_all_solicitudes" ON solicitudes FOR ALL TO service_role USING (true);
