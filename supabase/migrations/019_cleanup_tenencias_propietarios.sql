-- Sprint 8 — Migración Lenguaje Ubicuo: Cleanup final
-- Migrar tenencias.propietario_id → residente_id y eliminar tabla propietarios
-- Dependencias: 018_consolidado_fks.sql

BEGIN;

-- 1. Renombrar columna FK en tenencias
ALTER TABLE tenencias RENAME COLUMN propietario_id TO residente_id;

-- 2. Eliminar FK antigua (si existe)
ALTER TABLE tenencias DROP CONSTRAINT IF EXISTS tenencias_propietario_id_fkey;
ALTER TABLE tenencias DROP CONSTRAINT IF EXISTS fk_tenencias_propietario;

-- 3. Agregar FK nueva a residentes
ALTER TABLE tenencias ADD CONSTRAINT fk_tenencias_residente
  FOREIGN KEY (residente_id) REFERENCES residentes(id) ON DELETE CASCADE;

-- 4. Eliminar tabla propietarios (ya migrada a residentes)
DROP TABLE IF EXISTS propietarios CASCADE;

COMMIT;
