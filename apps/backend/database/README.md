# Base de Datos — Cívica Pago

Esquema y datos de prueba para la base de datos PostgreSQL del backend.

## Requisitos

- PostgreSQL 14+
- Acceso a la base de datos (local o Supabase)
- Variables de entorno configuradas en `.env`:
  ```
  DATABASE_HOST=
  DATABASE_PORT=
  DATABASE_USER=
  DATABASE_PASSWORD=
  DATABASE_NAME=
  ```

## Uso

### 1. Crear schema (estructura completa)

```bash
# Desde la raíz del backend (apps/backend/)
psql -h $DATABASE_HOST -p $DATABASE_PORT \
  -U $DATABASE_USER -d $DATABASE_NAME \
  -f database/schema.sql
```

Esto crea las 16 tablas, índices, vista `casa_estado_cartera` y políticas RLS.

### 2. Insertar datos de prueba

```bash
# Ejecutar DESPUÉS de schema.sql
psql -h $DATABASE_HOST -p $DATABASE_PORT \
  -U $DATABASE_USER -d $DATABASE_NAME \
  -f database/seed.sql
```

Inserta:
- 1 proyecto demo
- 3 residentes (Juan Pérez, María García, Carlos López)
- 5 usuarios con contraseña `civica2026!`

### 3. Reiniciar desde cero

```sql
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;
```

Luego repetir pasos 1 y 2.

## Usuarios de prueba

| Email | Contraseña | Rol |
|-------|-----------|-----|
| admin@civica.com | civica2026! | ADMIN |
| cobrador@civica.com | civica2026! | COBRADOR |
| mzA_casa101_1et@civica.com | civica2026! | PROPIETARIO |
| mzA_casa102_1et@civica.com | civica2026! | PROPIETARIO |
| mzA_casa103_1et@civica.com | civica2026! | PROPIETARIO |

## Arquitectura

- **16 entidades TypeORM** en `src/**/domain/` — fuente de verdad
- **`database/schema.sql`** — refleja exactamente las entidades
- **`docs/schema.md`** — documentación detallada de tablas, columnas y relaciones
- La base de datos se construye a partir del backend, no al revés.

## Notas

- Todas las columnas monetarias (`monto`) están en **centavos COP**
- Los timestamps usan `TIMESTAMPTZ` con `now()` por defecto
- Las políticas RLS permiten acceso total a `service_role` (backend)
- Ver `docs/schema.md` para documentación completa de cada tabla
