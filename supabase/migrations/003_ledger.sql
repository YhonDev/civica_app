-- Sprint 3 — Ledger: Tarifas, Montos Predefinidos, Cuotas, Cuentas de Cartera
-- Dependencias: 001_community.sql (conjuntos, propietarios)

-- ── Tarifas ────────────────────────────────────────────
CREATE TABLE tarifas (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id      UUID NOT NULL,
  conjunto_id    UUID NOT NULL REFERENCES conjuntos(id) ON DELETE CASCADE,
  frecuencia     VARCHAR(20) NOT NULL CHECK (frecuencia IN ('SEMANAL', 'QUINCENAL', 'MENSUAL')),
  monto          INTEGER NOT NULL CHECK (monto > 0),
  fecha_vigencia DATE NOT NULL,
  activa         BOOLEAN NOT NULL DEFAULT true,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_tarifas_conjunto ON tarifas (conjunto_id);
CREATE INDEX idx_tarifas_tenant   ON tarifas (tenant_id);

-- ── Montos Predefinidos ────────────────────────────────
CREATE TABLE montos_predefinidos (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id      UUID NOT NULL,
  conjunto_id    UUID NOT NULL REFERENCES conjuntos(id) ON DELETE CASCADE,
  monto          INTEGER NOT NULL CHECK (monto > 0),
  descripcion    VARCHAR(255) NOT NULL,
  activo         BOOLEAN NOT NULL DEFAULT true,
  orden          INTEGER NOT NULL DEFAULT 0,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_montos_conjunto ON montos_predefinidos (conjunto_id);

-- ── Cuentas de Cartera ─────────────────────────────────
CREATE TABLE cuentas_cartera (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  propietario_id   UUID NOT NULL UNIQUE REFERENCES propietarios(id) ON DELETE CASCADE,
  tenant_id        UUID NOT NULL,
  conjunto_id      UUID NOT NULL REFERENCES conjuntos(id) ON DELETE CASCADE,
  frecuencia       VARCHAR(20) NOT NULL CHECK (frecuencia IN ('SEMANAL', 'QUINCENAL', 'MENSUAL')),
  fecha_activacion DATE NOT NULL,
  activa           BOOLEAN NOT NULL DEFAULT true,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_cuentas_propietario ON cuentas_cartera (propietario_id);
CREATE INDEX idx_cuentas_tenant      ON cuentas_cartera (tenant_id);

-- ── Cuotas ─────────────────────────────────────────────
CREATE TABLE cuotas (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  propietario_id       UUID NOT NULL,
  tenant_id            UUID NOT NULL,
  tarifa_id            UUID REFERENCES tarifas(id) ON DELETE SET NULL,
  concepto             VARCHAR(255) NOT NULL,
  monto                INTEGER NOT NULL CHECK (monto > 0),
  monto_pagado         INTEGER NOT NULL DEFAULT 0 CHECK (monto_pagado >= 0),
  periodo_inicio       DATE NOT NULL,
  periodo_fin          DATE NOT NULL,
  fecha_vencimiento    DATE NOT NULL,
  estado               VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE'
                       CHECK (estado IN ('PENDIENTE', 'PARCIAL', 'PAGADA', 'VENCIDA')),
  notificacion_enviada BOOLEAN NOT NULL DEFAULT false,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_cuotas_propietario ON cuotas (propietario_id);
CREATE INDEX idx_cuotas_tenant      ON cuotas (tenant_id);
CREATE INDEX idx_cuotas_estado      ON cuotas (estado);
CREATE INDEX idx_cuotas_vencimiento ON cuotas (fecha_vencimiento);

-- ── RLS ─────────────────────────────────────────────────
ALTER TABLE tarifas              ENABLE ROW LEVEL SECURITY;
ALTER TABLE montos_predefinidos  ENABLE ROW LEVEL SECURITY;
ALTER TABLE cuentas_cartera      ENABLE ROW LEVEL SECURITY;
ALTER TABLE cuotas               ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_role_all_tarifas"             ON tarifas             FOR ALL TO service_role USING (true);
CREATE POLICY "service_role_all_montos_predefinidos" ON montos_predefinidos FOR ALL TO service_role USING (true);
CREATE POLICY "service_role_all_cuentas_cartera"     ON cuentas_cartera     FOR ALL TO service_role USING (true);
CREATE POLICY "service_role_all_cuotas"              ON cuotas              FOR ALL TO service_role USING (true);
