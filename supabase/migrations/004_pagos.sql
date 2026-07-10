-- Sprint 4 — Pagos: FIFO distribution, idempotencia, sync status
-- Dependencias: 003_ledger.sql (cuotas)

CREATE TYPE sync_status AS ENUM ('PENDIENTE_SYNC', 'SYNC_OK', 'CONFLICTO');

CREATE TABLE pagos (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_payment_id  VARCHAR(255) NOT NULL,
  tenant_id          UUID NOT NULL,
  cuota_id           UUID REFERENCES cuotas(id) ON DELETE SET NULL,
  monto              INTEGER NOT NULL CHECK (monto > 0),
  fecha_pago         DATE NOT NULL,
  cobrador_id        UUID NOT NULL,
  propietario_id     UUID NOT NULL,
  fecha_sync         TIMESTAMPTZ,
  sync_status        sync_status NOT NULL DEFAULT 'SYNC_OK',
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, client_payment_id)
);

CREATE INDEX idx_pagos_tenant_client  ON pagos (tenant_id, client_payment_id);
CREATE INDEX idx_pagos_propietario   ON pagos (propietario_id);
CREATE INDEX idx_pagos_cuota         ON pagos (cuota_id);
CREATE INDEX idx_pagos_cobrador      ON pagos (cobrador_id);

-- ── RLS ─────────────────────────────────────────────────
ALTER TABLE pagos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_role_all_pagos" ON pagos FOR ALL TO service_role USING (true);
