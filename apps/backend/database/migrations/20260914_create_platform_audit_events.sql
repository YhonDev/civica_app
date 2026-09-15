CREATE TABLE IF NOT EXISTS platform_audit_events (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id    VARCHAR(255) NOT NULL,
  action      VARCHAR(100) NOT NULL,
  resource    VARCHAR(100) NOT NULL,
  resource_id UUID,
  result      VARCHAR(16) NOT NULL DEFAULT 'SUCCESS'
    CHECK (result IN ('SUCCESS', 'FAILURE')),
  request_id  VARCHAR(100),
  ip_address  INET,
  metadata    JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_platform_audit_created
  ON platform_audit_events (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_platform_audit_action_resource
  ON platform_audit_events (action, resource, created_at DESC);
