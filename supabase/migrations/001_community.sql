-- Sprint 1 — Community BC: Conjunto, Etapas, Casas, Propietarios, Tenencias
-- Dependencias: ninguna (tablas base del sistema)

-- ── Extensions ──────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── Conjuntos ───────────────────────────────────────────
CREATE TABLE conjuntos (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre      VARCHAR(255) NOT NULL,
  tenant_id   UUID NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_conjuntos_tenant ON conjuntos (tenant_id);

-- ── Etapas ──────────────────────────────────────────────
CREATE TABLE etapas (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre      VARCHAR(255) NOT NULL,
  conjunto_id UUID NOT NULL REFERENCES conjuntos(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_etapas_conjunto ON etapas (conjunto_id);

-- ── Manzanas (Bloques) ──────────────────────────────────
CREATE TABLE manzanas (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre      VARCHAR(255) NOT NULL,
  etapa_id    UUID NOT NULL REFERENCES etapas(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_manzanas_etapa ON manzanas (etapa_id);

-- ── Casas ────────────────────────────────────────────────
CREATE TABLE casas (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  direccion_interna VARCHAR(255) NOT NULL,
  manzana_id       UUID NOT NULL REFERENCES manzanas(id) ON DELETE CASCADE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_casas_manzana ON casas (manzana_id);

-- ── Propietarios ─────────────────────────────────────────
CREATE TABLE propietarios (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre      VARCHAR(255) NOT NULL,
  telefono    VARCHAR(20)  NOT NULL,
  email       VARCHAR(255),
  tenant_id   UUID NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_propietarios_tenant ON propietarios (tenant_id);

-- ── Tenencias (relación N:M Propietario ↔ Casa) ─────────
CREATE TABLE tenencias (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  propietario_id  UUID NOT NULL REFERENCES propietarios(id) ON DELETE CASCADE,
  casa_id         UUID NOT NULL REFERENCES casas(id) ON DELETE CASCADE,
  fecha_inicio    DATE NOT NULL,
  fecha_fin       DATE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_tenencias_propietario ON tenencias (propietario_id);
CREATE INDEX idx_tenencias_casa       ON tenencias (casa_id);
CREATE INDEX idx_tenencias_activas    ON tenencias (propietario_id, casa_id) WHERE fecha_fin IS NULL;

-- ── RLS (preparación para multi-tenant) ──────────────────
ALTER TABLE conjuntos     ENABLE ROW LEVEL SECURITY;
ALTER TABLE etapas        ENABLE ROW LEVEL SECURITY;
ALTER TABLE manzanas      ENABLE ROW LEVEL SECURITY;
ALTER TABLE casas         ENABLE ROW LEVEL SECURITY;
ALTER TABLE propietarios  ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenencias     ENABLE ROW LEVEL SECURITY;

-- Políticas básicas: solo service_role puede todo por ahora
-- (se refinarán cuando integremos Auth en Sprint 2)
CREATE POLICY "service_role_all_conjuntos"    ON conjuntos    FOR ALL TO service_role USING (true);
CREATE POLICY "service_role_all_etapas"       ON etapas       FOR ALL TO service_role USING (true);
CREATE POLICY "service_role_all_manzanas"     ON manzanas     FOR ALL TO service_role USING (true);
CREATE POLICY "service_role_all_casas"        ON casas        FOR ALL TO service_role USING (true);
CREATE POLICY "service_role_all_propietarios" ON propietarios FOR ALL TO service_role USING (true);
CREATE POLICY "service_role_all_tenencias"    ON tenencias    FOR ALL TO service_role USING (true);
