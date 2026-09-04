-- ═══════════════════════════════════════════════════════════
-- Cívica Pago — Esquema completo de base de datos
-- Generado desde las entidades TypeORM del backend (16 entidades)
-- Lenguaje Ubicuo: Proyecto, Residente, Casa, Cobro, PlanDeCobro
--
-- Uso: psql -h <host> -U <user> -d <db> -f schema.sql
-- ═══════════════════════════════════════════════════════════

-- ── 1. Proyectos ────────────────────────────────────────
CREATE TABLE proyectos (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre                   VARCHAR(255) NOT NULL,
  tenant_id                UUID NOT NULL,
  recordatorios_automaticos BOOLEAN NOT NULL DEFAULT true,
  permite_pagos_parciales   BOOLEAN NOT NULL DEFAULT false,
  modo_mantenimiento        BOOLEAN NOT NULL DEFAULT false,
  fecha_mantenimiento       TIMESTAMPTZ,
  created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_proyectos_tenant ON proyectos (tenant_id);

-- ── 2. Etapas ───────────────────────────────────────────
CREATE TABLE etapas (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre         VARCHAR(255) NOT NULL,
  proyecto_id    UUID NOT NULL REFERENCES proyectos(id) ON DELETE CASCADE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_etapas_proyecto ON etapas (proyecto_id);

-- ── 3. Manzanas ─────────────────────────────────────────
CREATE TABLE manzanas (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre         VARCHAR(255) NOT NULL,
  etapa_id       UUID NOT NULL REFERENCES etapas(id) ON DELETE CASCADE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_manzanas_etapa ON manzanas (etapa_id);

-- ── 4. Casas ────────────────────────────────────────────
CREATE TABLE casas (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  direccion_interna VARCHAR(255) NOT NULL,
  manzana_id        UUID NOT NULL REFERENCES manzanas(id) ON DELETE CASCADE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_casas_manzana ON casas (manzana_id);

-- ── 5. Residentes ───────────────────────────────────────
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
  modalidad_pago  VARCHAR(20) NOT NULL DEFAULT 'MENSUAL',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_residentes_tenant ON residentes (tenant_id);
CREATE INDEX idx_residentes_casa   ON residentes (casa_actual_id);

-- ── 6. Tenericias (Residente ↔ Casa activa) ─────────────
CREATE TABLE tenencias (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  residente_id UUID NOT NULL REFERENCES residentes(id) ON DELETE CASCADE,
  casa_id        UUID NOT NULL,
  fecha_inicio   DATE NOT NULL,
  fecha_fin      DATE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_tenencias_residente ON tenencias (residente_id);
CREATE INDEX idx_tenencias_casa      ON tenencias (casa_id);
CREATE INDEX idx_tenencias_activas   ON tenencias (residente_id, casa_id) WHERE fecha_fin IS NULL;
-- NOTA: La entidad Tenencia usa @ManyToOne con createForeignKeyConstraints: false para casa_id
-- La FK se omite a propósito para mantener consistencia con el backend.

-- ── 7. Tarifas ───────────────────────────────────────────
CREATE TABLE tarifas (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id      UUID NOT NULL,
  proyecto_id    UUID NOT NULL REFERENCES proyectos(id) ON DELETE CASCADE,
  modalidad     VARCHAR(20) NOT NULL CHECK (modalidad IN ('SEMANAL', 'QUINCENAL', 'MENSUAL')),
  monto          INTEGER NOT NULL CHECK (monto > 0),
  fecha_vigencia DATE NOT NULL,
  activa         BOOLEAN NOT NULL DEFAULT true,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_tarifas_proyecto ON tarifas (proyecto_id);
CREATE INDEX idx_tarifas_tenant   ON tarifas (tenant_id);

-- ── 8. Montos Predefinidos ──────────────────────────────
CREATE TABLE montos_predefinidos (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id      UUID NOT NULL,
  proyecto_id    UUID NOT NULL REFERENCES proyectos(id) ON DELETE CASCADE,
  monto          INTEGER NOT NULL CHECK (monto > 0),
  descripcion    VARCHAR(255) NOT NULL,
  activo         BOOLEAN NOT NULL DEFAULT true,
  orden          INTEGER NOT NULL DEFAULT 0,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_montos_proyecto ON montos_predefinidos (proyecto_id);

-- ── 9. Planes de Cobro ──────────────────────────────────
CREATE TABLE planes_de_cobro (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  casa_id          UUID,
  residente_id     UUID NOT NULL,
  tenant_id        UUID NOT NULL,
  proyecto_id      UUID NOT NULL,
  modalidad        VARCHAR(20) NOT NULL CHECK (modalidad IN ('SEMANAL', 'QUINCENAL', 'MENSUAL')),
  valor_mensual    INTEGER,
  fecha_activacion DATE NOT NULL,
  activa           BOOLEAN NOT NULL DEFAULT true,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_planes_residente ON planes_de_cobro (residente_id);
CREATE INDEX idx_planes_tenant    ON planes_de_cobro (tenant_id);
-- NOTA: Sin FK explícitas para casa_id, residente_id, proyecto_id
-- (las entidades no definen @ManyToOne con FK constraints)

-- ── 10. Periodos de Cobro ───────────────────────────────
CREATE TABLE periodos_cobro (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id        UUID NOT NULL REFERENCES planes_de_cobro(id),
  mes            INTEGER NOT NULL CHECK (mes >= 1 AND mes <= 12),
  anio           INTEGER NOT NULL,
  fecha_inicio   DATE NOT NULL,
  fecha_fin      DATE NOT NULL,
  estado         VARCHAR(20) NOT NULL DEFAULT 'ACTIVO'
                 CHECK (estado IN ('ACTIVO', 'CERRADO')),
  tenant_id      UUID NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_periodos_plan   ON periodos_cobro (plan_id);
CREATE INDEX idx_periodos_tenant ON periodos_cobro (tenant_id);
-- NOTA: La FK a planes_de_cobro se maneja desde la aplicación
-- (la entidad PeriodoCobro usa @ManyToOne con FK implícita)

-- ── 11. Cobros (antes Cuotas) ───────────────────────────
CREATE TABLE cobros (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  residente_id         UUID NOT NULL,
  periodo_id           UUID,
  tenant_id            UUID NOT NULL,
  casa_id              UUID,
  tarifa_id            UUID,
  concepto             VARCHAR(255) NOT NULL,
  monto                INTEGER NOT NULL CHECK (monto > 0),
  monto_pagado         INTEGER NOT NULL DEFAULT 0 CHECK (monto_pagado >= 0),
  periodo_inicio       DATE NOT NULL,
  periodo_fin          DATE NOT NULL,
  fecha_vencimiento    DATE NOT NULL,
  estado               VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE'
                       CHECK (estado IN ('PENDIENTE', 'PARCIAL', 'PAGADA', 'VENCIDA', 'EN_REVISION', 'ANULADO')),
  notificacion_enviada BOOLEAN NOT NULL DEFAULT false,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_cobros_residente   ON cobros (residente_id);
CREATE INDEX idx_cobros_tenant      ON cobros (tenant_id);
CREATE INDEX idx_cobros_estado      ON cobros (estado);
CREATE INDEX idx_cobros_vencimiento ON cobros (fecha_vencimiento);
CREATE INDEX idx_cobros_tenant_periodo_estado     ON cobros (tenant_id, periodo_inicio, estado);
CREATE INDEX idx_cobros_tenant_vencimiento_estado ON cobros (tenant_id, fecha_vencimiento, estado);
CREATE INDEX idx_cobros_tenant_casa               ON cobros (tenant_id, casa_id);
-- NOTA: Sin FK constraints para residente_id, periodo_id, casa_id, tarifa_id
-- (las entidades usan @ManyToOne con createForeignKeyConstraints: false)

-- ── 12. Pagos ───────────────────────────────────────────
CREATE TABLE pagos (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_payment_id VARCHAR(255) NOT NULL,
  tenant_id         UUID NOT NULL,
  cobro_id          UUID,
  monto             INTEGER NOT NULL CHECK (monto > 0),
  fecha_pago        DATE NOT NULL,
  cobrador_id       UUID NOT NULL,
  residente_id      UUID NOT NULL,
  fecha_sync        TIMESTAMPTZ,
  sync_status       VARCHAR(20) NOT NULL DEFAULT 'SYNC_OK',
  estado            VARCHAR(30) NOT NULL DEFAULT 'PENDIENTE_REVISION'
                    CHECK (estado IN ('PENDIENTE_REVISION', 'VALIDADO', 'RECHAZADO')),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, client_payment_id)
);
CREATE INDEX idx_pagos_tenant_client ON pagos (tenant_id, client_payment_id);
CREATE INDEX idx_pagos_residente     ON pagos (residente_id);
CREATE INDEX idx_pagos_cobro         ON pagos (cobro_id);
CREATE INDEX idx_pagos_cobrador      ON pagos (cobrador_id);

-- ── 12b. PagoCobros (Vínculo FIFO exacto) ────────────────
CREATE TABLE pago_cobros (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pago_id        UUID NOT NULL,
  cobro_id       UUID NOT NULL,
  monto_aplicado INTEGER NOT NULL,
  tenant_id      UUID NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_pago_cobros_pago   ON pago_cobros (pago_id);
CREATE INDEX idx_pago_cobros_cobro  ON pago_cobros (cobro_id);
CREATE INDEX idx_pago_cobros_tenant ON pago_cobros (tenant_id);

-- ── 13. Usuarios ────────────────────────────────────────
CREATE TABLE usuarios (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email          VARCHAR(255) NOT NULL UNIQUE,
  password_hash  VARCHAR(255) NOT NULL,
  nombre         VARCHAR(255) NOT NULL,
  rol            VARCHAR(20) NOT NULL DEFAULT 'COBRADOR'
                 CHECK (rol IN ('ADMIN', 'COBRADOR', 'PROPIETARIO', 'RESIDENTE')),
  residente_id   UUID REFERENCES residentes(id) ON DELETE SET NULL,
  tenant_id      UUID NOT NULL,
  activo         BOOLEAN NOT NULL DEFAULT true,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_usuarios_tenant ON usuarios (tenant_id);
CREATE INDEX idx_usuarios_email  ON usuarios (email);

-- ── 13b. Sesiones de Autenticación ───────────────────────
CREATE TABLE auth_sessions (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id          UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  refresh_token_hash  VARCHAR(255) NOT NULL,
  previous_refresh_token_hash VARCHAR(255),
  device_id           VARCHAR(255),
  device_name         VARCHAR(255),
  ip_address          VARCHAR(64),
  user_agent          VARCHAR(255),
  is_revoked          BOOLEAN NOT NULL DEFAULT false,
  expires_at          TIMESTAMPTZ NOT NULL,
  last_used_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_auth_sessions_usuario ON auth_sessions (usuario_id);
CREATE INDEX idx_auth_sessions_token_hash ON auth_sessions (refresh_token_hash);


-- ── 14. Asignaciones de Etapa (Cobrador ↔ Etapa) ────────
CREATE TABLE asignaciones_etapa (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id     UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  etapa_id       UUID NOT NULL REFERENCES etapas(id) ON DELETE CASCADE,
  tenant_id      UUID NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (usuario_id, etapa_id)
);
CREATE INDEX idx_asignaciones_usuario ON asignaciones_etapa (usuario_id);
CREATE INDEX idx_asignaciones_etapa   ON asignaciones_etapa (etapa_id);

-- ── 15. Solicitudes ─────────────────────────────────────
CREATE TABLE solicitudes (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL,
  usuario_id      UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  cobro_id        UUID NOT NULL,
  nro_recibo      VARCHAR(20) NOT NULL,
  tipo            VARCHAR(255) NOT NULL,
  descripcion     TEXT NOT NULL,
  estado          VARCHAR(20) NOT NULL DEFAULT 'EN_ESPERA'
                  CHECK (estado IN ('PENDIENTE', 'EN_ESPERA', 'EN_CAMINO', 'COBRADA', 'EN_REVISION', 'RESUELTA', 'APROBADA', 'RECHAZADA', 'VENCIDA')),
  fecha           TIMESTAMPTZ NOT NULL DEFAULT now(),
  respuesta       TEXT,
  fecha_respuesta TIMESTAMPTZ,
  casa_id         UUID,
  residente_id    UUID,
  pago_id         UUID,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX idx_solicitudes_nro_recibo ON solicitudes (nro_recibo);
CREATE INDEX idx_solicitudes_tenant    ON solicitudes (tenant_id);
CREATE INDEX idx_solicitudes_usuario   ON solicitudes (usuario_id);
CREATE INDEX idx_solicitudes_cobro     ON solicitudes (cobro_id);
CREATE INDEX idx_solicitudes_casa      ON solicitudes (casa_id);
CREATE INDEX idx_solicitudes_residente ON solicitudes (residente_id);
CREATE INDEX idx_solicitudes_tenant_estado ON solicitudes (tenant_id, estado);

-- ── 16. Actividad (auditoría) ───────────────────────────
CREATE TABLE actividad (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id      UUID NOT NULL,
  tipo           VARCHAR(50) NOT NULL,
  descripcion    TEXT NOT NULL,
  usuario_nombre VARCHAR(255) NOT NULL,
  usuario_id     UUID NOT NULL,
  metadata       JSONB DEFAULT '{}'::jsonb,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_actividad_tenant_created ON actividad (tenant_id, created_at DESC);

-- ── 17. Tickets (Comprobantes de pago) ──────────────────
CREATE TABLE tickets (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo                VARCHAR(20) NOT NULL DEFAULT 'COBRO',
  numero              VARCHAR(20) NOT NULL,
  fecha               TIMESTAMPTZ NOT NULL DEFAULT now(),
  tenant_id           UUID NOT NULL,
  residente_id        UUID NOT NULL,
  residente_nombre    VARCHAR(255) NOT NULL,
  residente_documento VARCHAR(50),
  casa_direccion      VARCHAR(255) NOT NULL,
  etapa               VARCHAR(255) NOT NULL,
  manzana             VARCHAR(255) NOT NULL,
  estado              VARCHAR(20) NOT NULL DEFAULT 'EMITIDO'
                      CHECK (estado IN ('EMITIDO', 'ANULADO')),
  -- Campos específicos de TicketCobro (nullable for STI)
  pago_id             UUID,
  cobro_id            UUID,
  cobrador_id         UUID,
  cobrador_nombre     VARCHAR(255),
  monto               INTEGER,
  metodo              VARCHAR(50) DEFAULT 'EFECTIVO',
  concepto            VARCHAR(255),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX idx_tickets_numero     ON tickets (tenant_id, numero);
CREATE INDEX idx_tickets_tenant            ON tickets (tenant_id);
CREATE INDEX idx_tickets_residente         ON tickets (residente_id);
CREATE INDEX idx_tickets_pago              ON tickets (pago_id);
CREATE INDEX idx_tickets_tipo              ON tickets (tipo);

-- ── 18. Notificaciones ──────────────────────────────────
CREATE TABLE notificaciones (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo               VARCHAR(50) NOT NULL DEFAULT 'CUOTA_VENCIDA',
  destinatario_email VARCHAR(255) NOT NULL,
  asunto             VARCHAR(255) NOT NULL,
  cuerpo             TEXT NOT NULL,
  estado             VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE'
                     CHECK (estado IN ('PENDIENTE', 'ENVIADA', 'FALLIDA')),
  intentos           INTEGER NOT NULL DEFAULT 0,
  ultimo_intento     TIMESTAMPTZ,
  cobro_id           UUID,
  tenant_id          UUID NOT NULL,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_notificaciones_tenant ON notificaciones (tenant_id);
CREATE INDEX idx_notificaciones_estado ON notificaciones (estado);
CREATE INDEX idx_notificaciones_cobro  ON notificaciones (cobro_id);

-- ═══════════════════════════════════════════════════════════
-- VISTA: Estado de Cartera por Casa
-- ═══════════════════════════════════════════════════════════
CREATE OR REPLACE VIEW casa_estado_cartera AS
SELECT
  c.id AS casa_id,
  c.direccion_interna AS direccion,
  m.id AS manzana_id,
  m.nombre AS manzana_nombre,
  e.id AS etapa_id,
  e.nombre AS etapa_nombre,
  pj.id AS proyecto_id,
  pj.nombre AS proyecto_nombre,
  pj.tenant_id,
  r.id AS residente_actual_id,
  r.nombre AS residente_nombre,
  r.telefono AS residente_telefono,
  r.email AS residente_email,
  r.tipo AS residente_tipo,
  pc.modalidad,
  COUNT(co.id) AS total_cobros,
  COUNT(co.id) FILTER (WHERE co.estado = 'PAGADA') AS cobros_pagados,
  COUNT(co.id) FILTER (WHERE (co.estado IN ('PENDIENTE', 'PARCIAL')) AND co.fecha_vencimiento >= CURRENT_DATE) AS cobros_pendientes,
  COUNT(co.id) FILTER (WHERE co.estado = 'VENCIDA' OR (co.estado IN ('PENDIENTE', 'PARCIAL') AND co.fecha_vencimiento < CURRENT_DATE)) AS cobros_vencidos,
  CASE
    WHEN COUNT(co.id) = 0 THEN 'SIN_COBROS'
    WHEN COUNT(co.id) FILTER (WHERE co.estado = 'VENCIDA' OR (co.estado IN ('PENDIENTE', 'PARCIAL') AND co.fecha_vencimiento < CURRENT_DATE)) > 0 THEN 'EN_MORA'
    WHEN COUNT(co.id) FILTER (WHERE (co.estado IN ('PENDIENTE', 'PARCIAL')) AND co.fecha_vencimiento >= CURRENT_DATE) > 0 THEN 'PENDIENTE'
    ELSE 'AL_DIA'
  END AS estado_cartera,
  COALESCE(SUM(co.monto - co.monto_pagado) FILTER (WHERE co.estado = 'VENCIDA' OR (co.estado IN ('PENDIENTE', 'PARCIAL') AND co.fecha_vencimiento < CURRENT_DATE)), 0) AS saldo_mora_centavos
FROM casas c
JOIN manzanas m ON m.id = c.manzana_id
JOIN etapas e ON e.id = m.etapa_id
JOIN proyectos pj ON pj.id = e.proyecto_id
LEFT JOIN tenencias t ON t.casa_id = c.id AND t.fecha_fin IS NULL
LEFT JOIN residentes r ON r.id = t.residente_id
LEFT JOIN planes_de_cobro pc ON pc.residente_id = r.id AND pc.activa = true
LEFT JOIN cobros co ON (co.casa_id = c.id OR (co.casa_id IS NULL AND co.residente_id = r.id))
GROUP BY c.id, c.direccion_interna, m.id, m.nombre, e.id, e.nombre,
         pj.id, pj.nombre, pj.tenant_id, r.id, r.nombre, r.telefono,
         r.email, r.tipo, pc.modalidad
ORDER BY e.nombre, m.nombre, c.direccion_interna;

-- ═══════════════════════════════════════════════════════════
-- RLS: Row Level Security (Supabase)
-- ═══════════════════════════════════════════════════════════
ALTER TABLE actividad              ENABLE ROW LEVEL SECURITY;
ALTER TABLE asignaciones_etapa     ENABLE ROW LEVEL SECURITY;
ALTER TABLE auth_sessions          ENABLE ROW LEVEL SECURITY;
ALTER TABLE casas                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE cobros                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE etapas                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE manzanas               ENABLE ROW LEVEL SECURITY;
ALTER TABLE montos_predefinidos    ENABLE ROW LEVEL SECURITY;
ALTER TABLE notificaciones         ENABLE ROW LEVEL SECURITY;
ALTER TABLE pago_cobros            ENABLE ROW LEVEL SECURITY;
ALTER TABLE pagos                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE periodos_cobro         ENABLE ROW LEVEL SECURITY;
ALTER TABLE planes_de_cobro        ENABLE ROW LEVEL SECURITY;
ALTER TABLE proyectos              ENABLE ROW LEVEL SECURITY;
ALTER TABLE residentes             ENABLE ROW LEVEL SECURITY;
ALTER TABLE solicitudes            ENABLE ROW LEVEL SECURITY;
ALTER TABLE tarifas                ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenencias              ENABLE ROW LEVEL SECURITY;
ALTER TABLE tickets                ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios               ENABLE ROW LEVEL SECURITY;

-- Policies service_role (backend)
CREATE POLICY service_role_all_actividad             ON actividad             FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all_asignaciones_etapa    ON asignaciones_etapa    FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all_auth_sessions         ON auth_sessions         FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all_casas                 ON casas                 FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all_cobros                ON cobros                FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all_etapas                ON etapas                FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all_manzanas              ON manzanas              FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all_montos_predefinidos   ON montos_predefinidos   FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all_notificaciones        ON notificaciones        FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all_pago_cobros           ON pago_cobros           FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all_pagos                 ON pagos                 FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all_periodos_cobro        ON periodos_cobro        FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all_planes_de_cobro       ON planes_de_cobro       FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all_proyectos             ON proyectos             FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all_residentes            ON residentes            FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all_solicitudes           ON solicitudes           FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all_tarifas               ON tarifas               FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all_tenencias             ON tenencias             FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all_tickets                ON tickets               FOR ALL TO service_role USING (true);
CREATE POLICY service_role_all_usuarios              ON usuarios              FOR ALL TO service_role USING (true);
