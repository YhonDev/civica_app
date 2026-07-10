-- Sprint 2 — IAM: Usuarios, Roles, Asignación de Etapas
-- Dependencias: 001_community.sql (etapas)

-- ── Usuarios ────────────────────────────────────────────
CREATE TYPE rol_usuario AS ENUM ('ADMIN', 'COBRADOR', 'PROPIETARIO');

CREATE TABLE usuarios (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email          VARCHAR(255) NOT NULL UNIQUE,
  password_hash  VARCHAR(255) NOT NULL,
  nombre         VARCHAR(255) NOT NULL,
  rol            rol_usuario NOT NULL DEFAULT 'COBRADOR',
  propietario_id UUID REFERENCES propietarios(id) ON DELETE SET NULL,
  tenant_id      UUID NOT NULL,
  activo         BOOLEAN NOT NULL DEFAULT true,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_usuarios_tenant ON usuarios (tenant_id);
CREATE INDEX idx_usuarios_email  ON usuarios (email);

-- ── Asignaciones de Etapas (cobrador -> etapas) ─────────
CREATE TABLE asignaciones_etapa (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  etapa_id   UUID NOT NULL REFERENCES etapas(id) ON DELETE CASCADE,
  tenant_id  UUID NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (usuario_id, etapa_id)
);

CREATE INDEX idx_asignaciones_usuario ON asignaciones_etapa (usuario_id);
CREATE INDEX idx_asignaciones_etapa   ON asignaciones_etapa (etapa_id);

-- ── RLS ─────────────────────────────────────────────────
ALTER TABLE usuarios           ENABLE ROW LEVEL SECURITY;
ALTER TABLE asignaciones_etapa ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_role_all_usuarios"            ON usuarios           FOR ALL TO service_role USING (true);
CREATE POLICY "service_role_all_asignaciones_etapa"  ON asignaciones_etapa FOR ALL TO service_role USING (true);

-- ── Seed: admin inicial (password: admin123, se cambia en primer login) ──
-- La contraseña se establece desde la app, no en SQL plano
