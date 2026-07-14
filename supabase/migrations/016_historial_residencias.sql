-- Sprint 8 — Migración Lenguaje Ubicuo: Historial de Residencias
-- Nueva tabla que reemplaza tenencias como registro histórico de
-- la relación Residente ↔ Casa
-- Dependencias: 010_propietarios_a_residentes.sql

CREATE TABLE historial_residencias (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  residente_id    UUID NOT NULL REFERENCES residentes(id) ON DELETE CASCADE,
  casa_id         UUID NOT NULL REFERENCES casas(id) ON DELETE CASCADE,
  fecha_inicio    DATE NOT NULL,
  fecha_fin       DATE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Migrar datos desde tenencias
INSERT INTO historial_residencias (residente_id, casa_id, fecha_inicio, fecha_fin, created_at)
SELECT propietario_id, casa_id, fecha_inicio, fecha_fin, created_at
FROM tenencias;

CREATE INDEX idx_historial_residente ON historial_residencias (residente_id);
CREATE INDEX idx_historial_casa      ON historial_residencias (casa_id);

-- ── RLS ─────────────────────────────────────────────────
ALTER TABLE historial_residencias ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_role_all_historial" ON historial_residencias FOR ALL TO service_role USING (true);

-- NOTA: La tabla tenencias se eliminará en la Fase 5 (cleanup)
-- después de validar que los datos migraron correctamente.
