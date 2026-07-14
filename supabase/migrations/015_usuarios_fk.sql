-- Sprint 8 — Migración Lenguaje Ubicuo: Usuarios — actualizar FK
-- Renombra la columna FK de usuarios para apuntar a residentes
-- Dependencias: 010_propietarios_a_residentes.sql

ALTER TABLE usuarios RENAME COLUMN propietario_id TO residente_id;

-- Agregar FK formal a residentes (antes era un UUID libre sin constraint)
ALTER TABLE usuarios ADD CONSTRAINT fk_usuarios_residente
  FOREIGN KEY (residente_id) REFERENCES residentes(id) ON DELETE SET NULL;
