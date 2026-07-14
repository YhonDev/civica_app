-- Sprint 7 — Fix: actividad.tenant_id FK apuntaba a conjuntos(id) por error.
-- En todas las demás tablas (propietarios, usuarios, cuotas, etc.),
-- tenant_id es un UUID libre sin FK. Esta corrección alinea actividad
-- con el mismo patrón.
-- Dependencias: 005_actividad.sql

ALTER TABLE actividad DROP CONSTRAINT IF EXISTS actividad_tenant_id_fkey;
