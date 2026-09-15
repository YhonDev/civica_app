CREATE TABLE IF NOT EXISTS tenants (
  id         UUID PRIMARY KEY,
  name       VARCHAR(255) NOT NULL,
  status     VARCHAR(32) NOT NULL DEFAULT 'ACTIVE'
    CHECK (status IN ('ACTIVE', 'SUSPENDED', 'MAINTENANCE', 'ARCHIVED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tenants_status_created
  ON tenants (status, created_at DESC);

INSERT INTO tenants (id, name)
SELECT tenant_id, 'Tenant ' || LEFT(tenant_id::text, 8)
FROM (
  SELECT DISTINCT tenant_id FROM usuarios
  UNION
  SELECT DISTINCT tenant_id FROM proyectos
) existing_tenants
ON CONFLICT (id) DO NOTHING;
