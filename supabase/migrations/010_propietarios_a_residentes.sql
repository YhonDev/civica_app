-- Sprint 8 — Migración Lenguaje Ubicuo: Propietarios → Residentes
-- Crea la tabla residentes con tipo (PROPIETARIO / INQUILINO),
-- migra los datos existentes desde propietarios y tenencias
-- Dependencias: 001_community.sql (propietarios, tenencias, casas)

-- ── Crear nueva tabla ───────────────────────────────────
CREATE TABLE residentes (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo            VARCHAR(20) NOT NULL DEFAULT 'PROPIETARIO'
                  CHECK (tipo IN ('PROPIETARIO', 'INQUILINO')),
  nombre          VARCHAR(255) NOT NULL,
  telefono        VARCHAR(20) NOT NULL,
  email           VARCHAR(255),
  documento       VARCHAR(50),
  casa_actual_id  UUID REFERENCES casas(id) ON DELETE SET NULL,
  tenant_id       UUID NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_residentes_tenant ON residentes (tenant_id);
CREATE INDEX idx_residentes_casa   ON residentes (casa_actual_id);

-- ── Migrar datos existentes ─────────────────────────────
-- Todos los propietarios actuales se migran como PROPIETARIO
INSERT INTO residentes (id, tipo, nombre, telefono, email, tenant_id, created_at, updated_at)
SELECT id, 'PROPIETARIO', nombre, telefono, email, tenant_id, created_at, updated_at
FROM propietarios;

-- Poblar casa_actual_id desde tenencias activas
UPDATE residentes r
SET casa_actual_id = t.casa_id
FROM tenencias t
WHERE t.propietario_id = r.id AND t.fecha_fin IS NULL;

-- ── RLS ─────────────────────────────────────────────────
ALTER TABLE residentes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_role_all_residentes" ON residentes FOR ALL TO service_role USING (true);
