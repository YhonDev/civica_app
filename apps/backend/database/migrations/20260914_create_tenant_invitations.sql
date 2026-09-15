CREATE TABLE IF NOT EXISTS tenant_invitations (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  email       VARCHAR(255) NOT NULL,
  name        VARCHAR(255) NOT NULL,
  token_hash  VARCHAR(64) NOT NULL UNIQUE,
  status      VARCHAR(32) NOT NULL DEFAULT 'PENDING'
    CHECK (status IN ('PENDING', 'ACCEPTED', 'REVOKED', 'EXPIRED')),
  expires_at  TIMESTAMPTZ NOT NULL,
  accepted_at TIMESTAMPTZ,
  created_by  VARCHAR(255) NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tenant_invitations_token
  ON tenant_invitations (token_hash)
  WHERE status = 'PENDING';

CREATE INDEX IF NOT EXISTS idx_tenant_invitations_tenant
  ON tenant_invitations (tenant_id, status, created_at DESC);
