-- Sprint 8 — Migración Lenguaje Ubicuo: Conjuntos → Proyectos
-- Renombra la tabla conjuntos a proyectos y actualiza todas las FKs
-- Dependencias: 001_community.sql (conjuntos)

ALTER TABLE conjuntos RENAME TO proyectos;

-- Actualizar columnas FK en tablas hijas
ALTER TABLE etapas           RENAME COLUMN conjunto_id TO proyecto_id;
ALTER TABLE tarifas          RENAME COLUMN conjunto_id TO proyecto_id;
ALTER TABLE montos_predefinidos RENAME COLUMN conjunto_id TO proyecto_id;

-- NOTA: No se renombra sequence porque la PK usa gen_random_uuid(),
-- que no crea sequences automáticas.

-- Renombrar índices
ALTER INDEX idx_conjuntos_tenant  RENAME TO idx_proyectos_tenant;
ALTER INDEX idx_etapas_conjunto   RENAME TO idx_etapas_proyecto;
ALTER INDEX idx_tarifas_conjunto  RENAME TO idx_tarifas_proyecto;
ALTER INDEX idx_montos_conjunto   RENAME TO idx_montos_proyecto;

-- Renombrar RLS policies
ALTER POLICY "service_role_all_conjuntos" ON proyectos RENAME TO "service_role_all_proyectos";
