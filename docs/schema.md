# Esquema de Base de Datos — Cívica Pago

> **Documentación generada desde las entidades TypeORM del backend.**
> La base de datos se construye a partir del backend, no al revés.
> Archivo de referencia: `backend/database/schema.sql`

---

## Convenciones de nomenclatura

- **Tablas**: plural en español (`proyectos`, `residentes`, `cobros`)
- **Columnas**: snake_case (`fecha_vencimiento`, `casa_actual_id`)
- **FKs**: `{tabla_origen}_id` (`residente_id`, `proyecto_id`)
- **Timestamps**: `created_at`, `updated_at`
- **Moneda**: enteros en centavos COP (`monto INTEGER`)

---

## Entidades del dominio

### Módulo Community (16 tablas)

#### 1. `proyectos` — Proyectos residenciales (antes Conjuntos)

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | UUID | PK, `gen_random_uuid()` | ID único |
| `nombre` | VARCHAR(255) | NOT NULL | Nombre del proyecto |
| `tenant_id` | UUID | NOT NULL | ID del tenant (Supabase) |
| `created_at` | TIMESTAMPTZ | NOT NULL, `now()` | Fecha de creación |
| `updated_at` | TIMESTAMPTZ | NOT NULL, `now()` | Fecha de actualización |

**Relaciones:**
- `1:N` → `etapas` (via `proyecto_id`)

---

#### 2. `etapas` — Etapas de un proyecto

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | UUID | PK | ID único |
| `nombre` | VARCHAR(255) | NOT NULL | Nombre de la etapa |
| `proyecto_id` | UUID | NOT NULL, FK → `proyectos(id)` ON DELETE CASCADE | Proyecto al que pertenece |
| `created_at` | TIMESTAMPTZ | NOT NULL, `now()` | Fecha de creación |

**Relaciones:**
- `N:1` → `proyectos`
- `1:N` → `manzanas`
- `N:M` → `usuarios` (via `asignaciones_etapa`)

---

#### 3. `manzanas` — Manzanas dentro de una etapa

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | UUID | PK | ID único |
| `nombre` | VARCHAR(255) | NOT NULL | Nombre de la manzana |
| `etapa_id` | UUID | NOT NULL, FK → `etapas(id)` ON DELETE CASCADE | Etapa a la que pertenece |
| `created_at` | TIMESTAMPTZ | NOT NULL, `now()` | Fecha de creación |

**Relaciones:**
- `N:1` → `etapas`
- `1:N` → `casas`

---

#### 4. `casas` — Unidades de vivienda (antes Viviendas)

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | UUID | PK | ID único |
| `direccion_interna` | VARCHAR(255) | NOT NULL | Dirección interna (ej: "Casa 101") |
| `manzana_id` | UUID | NOT NULL, FK → `manzanas(id)` ON DELETE CASCADE | Manzana a la que pertenece |
| `created_at` | TIMESTAMPTZ | NOT NULL, `now()` | Fecha de creación |

**Relaciones:**
- `N:1` → `manzanas`
- `1:N` → `tenencias`
- `1:N` → `historial_residencias`

---

#### 5. `residentes` — Personas residentes (antes Propietarios)

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | UUID | PK | ID único |
| `tipo` | VARCHAR(20) | NOT NULL, DEFAULT 'PROPIETARIO', CHECK(`PROPIETARIO`, `INQUILINO`) | Tipo de residente |
| `nombre` | VARCHAR(255) | NOT NULL | Nombre completo |
| `telefono` | VARCHAR(20) | NOT NULL | Teléfono de contacto |
| `email` | VARCHAR(255) | NULLABLE | Correo electrónico |
| `documento` | VARCHAR(50) | NULLABLE | Número de documento |
| `casa_actual_id` | UUID | NULLABLE, FK → `casas(id)` ON DELETE SET NULL | Casa actual (si aplica) |
| `tenant_id` | UUID | NOT NULL | ID del tenant |
| `modalidad_pago` | VARCHAR(20) | NOT NULL, DEFAULT 'MENSUAL' | Frecuencia de pago preferida |
| `created_at` | TIMESTAMPTZ | NOT NULL, `now()` | |
| `updated_at` | TIMESTAMPTZ | NOT NULL, `now()` | |

**Relaciones:**
- `N:1` → `casas` (via `casa_actual_id`)
- `1:N` → `tenencias`
- `1:N` → `cobros`
- `1:N` → `usuarios` (via `residente_id`)

---

#### 6. `tenencias` — Relación activa Residente ↔ Casa

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | UUID | PK | ID único |
| `propietario_id` | UUID | NOT NULL, FK → `residentes(id)` ON DELETE CASCADE | ⚠️ Nombre de columna NO actualizado (deuda técnica) |
| `casa_id` | UUID | NOT NULL | Casa (sin FK explícito) |
| `fecha_inicio` | DATE | NOT NULL | Fecha de inicio de la tenencia |
| `fecha_fin` | DATE | NULLABLE | Fecha de fin (NULL = activa) |
| `created_at` | TIMESTAMPTZ | NOT NULL, `now()` | |

**⚠️ Deuda técnica:** La columna `propietario_id` debería llamarse `residente_id`. La entidad `Tenencia` tiene `@Column({ name: 'propietario_id' })` pero la propiedad ya se llama `residenteId`.

**Relaciones:**
- `N:1` → `residentes`
- `1:1` → `casas` (a través de aplicación)

---

#### 7. `tarifas` — Tarifas de cobro

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | UUID | PK | ID único |
| `tenant_id` | UUID | NOT NULL | ID del tenant |
| `conjunto_id` | UUID | NOT NULL, FK → `proyectos(id)` ON DELETE CASCADE | ⚠️ Columna NO renombrada |
| `frecuencia` | VARCHAR(20) | NOT NULL, CHECK(`SEMANAL`, `QUINCENAL`, `MENSUAL`) | Frecuencia de cobro |
| `monto` | INTEGER | NOT NULL, CHECK(`> 0`) | Monto en centavos COP |
| `fecha_vigencia` | DATE | NOT NULL | Desde cuándo aplica |
| `activa` | BOOLEAN | NOT NULL, DEFAULT `true` | Está activa |
| `created_at` | TIMESTAMPTZ | NOT NULL, `now()` | |
| `updated_at` | TIMESTAMPTZ | NOT NULL, `now()` | |

**⚠️ Deuda técnica:** La columna `conjunto_id` debería llamarse `proyecto_id`. La entidad `Tarifa` no fue actualizada en la Fase 2.

---

#### 8. `montos_predefinidos` — Montos de pago rápidos

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | UUID | PK | ID único |
| `tenant_id` | UUID | NOT NULL | ID del tenant |
| `conjunto_id` | UUID | NOT NULL, FK → `proyectos(id)` ON DELETE CASCADE | ⚠️ Columna NO renombrada |
| `monto` | INTEGER | NOT NULL, CHECK(`> 0`) | Monto en centavos COP |
| `descripcion` | VARCHAR(255) | NOT NULL | Descripción del monto |
| `activo` | BOOLEAN | NOT NULL, DEFAULT `true` | Está activo |
| `orden` | INTEGER | NOT NULL, DEFAULT `0` | Orden de visualización |
| `created_at` | TIMESTAMPTZ | NOT NULL, `now()` | |
| `updated_at` | TIMESTAMPTZ | NOT NULL, `now()` | |

**⚠️ Deuda técnica:** Misma situación que `tarifas` — `conjunto_id` debería ser `proyecto_id`.

---

### Módulo Ledger

#### 9. `planes_de_cobro` — Planes de recaudo (antes Cuentas de Cartera)

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | UUID | PK | ID único |
| `casa_id` | UUID | NULLABLE | Casa asociada |
| `residente_id` | UUID | NOT NULL | Residente responsable |
| `tenant_id` | UUID | NOT NULL | ID del tenant |
| `proyecto_id` | UUID | NOT NULL | Proyecto al que pertenece |
| `modalidad` | VARCHAR(20) | NOT NULL, CHECK(`SEMANAL`, `QUINCENAL`, `MENSUAL`) | Modalidad de recaudo |
| `valor_mensual` | INTEGER | NULLABLE | Valor si es personalizado |
| `fecha_activacion` | DATE | NOT NULL | Desde cuándo está activo |
| `activa` | BOOLEAN | NOT NULL, DEFAULT `true` | Está activo |
| `created_at` | TIMESTAMPTZ | NOT NULL, `now()` | |
| `updated_at` | TIMESTAMPTZ | NOT NULL, `now()` | |

**Relaciones:**
- `1:N` → `periodos_cobro`

---

#### 10. `periodos_cobro` — Períodos mensuales de un plan

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | UUID | PK | ID único |
| `plan_id` | UUID | NOT NULL | Plan al que pertenece |
| `mes` | INTEGER | NOT NULL, CHECK(`1-12`) | Mes del período |
| `anio` | INTEGER | NOT NULL | Año del período |
| `fecha_inicio` | DATE | NOT NULL | Inicio del período |
| `fecha_fin` | DATE | NOT NULL | Fin del período |
| `estado` | VARCHAR(20) | NOT NULL, DEFAULT 'ACTIVO', CHECK(`ACTIVO`, `CERRADO`) | Estado del período |
| `tenant_id` | UUID | NOT NULL | ID del tenant |
| `created_at` | TIMESTAMPTZ | NOT NULL, `now()` | |

**Relaciones:**
- `N:1` → `planes_de_cobro`
- `1:N` → `cobros`

---

#### 11. `cobros` — Cobros individuales (antes Cuotas)

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | UUID | PK | ID único |
| `residente_id` | UUID | NOT NULL | Residente (sin FK) |
| `periodo_id` | UUID | NULLABLE | Período al que pertenece |
| `tenant_id` | UUID | NOT NULL | ID del tenant |
| `casa_id` | UUID | NULLABLE | Casa asociada |
| `tarifa_id` | UUID | NULLABLE | Tarifa origen |
| `concepto` | VARCHAR(255) | NOT NULL | Concepto del cobro |
| `monto` | INTEGER | NOT NULL, CHECK(`> 0`) | Monto en centavos COP |
| `monto_pagado` | INTEGER | NOT NULL, DEFAULT `0`, CHECK(`>= 0`) | Monto ya pagado |
| `periodo_inicio` | DATE | NOT NULL | Inicio del período del cobro |
| `periodo_fin` | DATE | NOT NULL | Fin del período del cobro |
| `fecha_vencimiento` | DATE | NOT NULL | Fecha de vencimiento |
| `estado` | VARCHAR(20) | NOT NULL, DEFAULT 'PENDIENTE', CHECK(`PENDIENTE`, `PARCIAL`, `PAGADA`, `VENCIDA`, `EN_REVISION`, `ANULADO`) | Estado del cobro |
| `notificacion_enviada` | BOOLEAN | NOT NULL, DEFAULT `false` | Ya se notificó al residente |
| `created_at` | TIMESTAMPTZ | NOT NULL, `now()` | |
| `updated_at` | TIMESTAMPTZ | NOT NULL, `now()` | |

**Nota:** Las entidades usan `@ManyToOne` con `{ createForeignKeyConstraints: false }`, por lo que no hay FK constraints en BD para `residente_id`, `periodo_id`, `casa_id`, `tarifa_id`.

**Relaciones:**
- `N:1` → `residentes` (sin FK en BD)
- `N:1` → `periodos_cobro` (sin FK en BD)
- `1:N` → `pagos`
- `1:N` → `solicitudes`

---

#### 12. `pagos` — Pagos realizados

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | UUID | PK | ID único |
| `client_payment_id` | VARCHAR(255) | NOT NULL | ID único del cliente (idempotencia) |
| `tenant_id` | UUID | NOT NULL | ID del tenant |
| `cobro_id` | UUID | NULLABLE | Cobro asociado |
| `monto` | INTEGER | NOT NULL, CHECK(`> 0`) | Monto en centavos COP |
| `fecha_pago` | DATE | NOT NULL | Fecha del pago |
| `cobrador_id` | UUID | NOT NULL | Usuario que registró el pago |
| `residente_id` | UUID | NOT NULL | Residente que pagó |
| `fecha_sync` | TIMESTAMPTZ | NULLABLE | Última sincronización |
| `sync_status` | VARCHAR(20) | NOT NULL, DEFAULT 'SYNC_OK' | Estado de sincronización |
| `created_at` | TIMESTAMPTZ | NOT NULL, `now()` | |
| `updated_at` | TIMESTAMPTZ | NOT NULL, `now()` | |
| UNIQUE | (`tenant_id`, `client_payment_id`) | | Idempotencia |

**Nota:** No hay FK constraints para `cobrador_id`, `residente_id` (se manejan desde la aplicación).

---

#### 13. `solicitudes` — Solicitudes de los residentes

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | UUID | PK | ID único |
| `tenant_id` | UUID | NOT NULL | ID del tenant |
| `usuario_id` | UUID | NOT NULL, FK → `usuarios(id)` ON DELETE CASCADE | Usuario que creó la solicitud |
| `cobro_id` | UUID | NOT NULL | Cobro relacionado |
| `nro_recibo` | VARCHAR(20) | NOT NULL, UNIQUE | Número de recibo |
| `tipo` | VARCHAR(255) | NOT NULL | Tipo de solicitud |
| `descripcion` | TEXT | NOT NULL | Descripción/detalle |
| `estado` | VARCHAR(20) | NOT NULL, DEFAULT 'EN_REVISION', CHECK(`PENDIENTE`, `EN_REVISION`, `RESUELTA`, `RECHAZADA`, `APROBADA`) | Estado de la solicitud |
| `fecha` | TIMESTAMPTZ | NOT NULL, `now()` | Fecha de creación |
| `respuesta` | TEXT | NULLABLE | Respuesta del admin |
| `fecha_respuesta` | TIMESTAMPTZ | NULLABLE | Cuándo se respondió |
| `casa_id` | UUID | NULLABLE | Casa relacionada |
| `residente_id` | UUID | NULLABLE | Residente relacionado |
| `pago_id` | UUID | NULLABLE | Pago relacionado |
| `created_at` | TIMESTAMPTZ | NOT NULL, `now()` | |
| `updated_at` | TIMESTAMPTZ | NOT NULL, `now()` | |

**Nota:** `cobro_id` no tiene FK constraint en BD (la entidad usa `@ManyToOne` sin restricción explícita).

---

### Módulo IAM

#### 14. `usuarios` — Usuarios del sistema

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | UUID | PK | ID único |
| `email` | VARCHAR(255) | NOT NULL, UNIQUE | Email de login |
| `password_hash` | VARCHAR(255) | NOT NULL | Hash bcrypt de la contraseña |
| `nombre` | VARCHAR(255) | NOT NULL | Nombre completo |
| `rol` | VARCHAR(20) | NOT NULL, DEFAULT 'COBRADOR', CHECK(`ADMIN`, `COBRADOR`, `PROPIETARIO`, `RESIDENTE`) | Rol del usuario |
| `residente_id` | UUID | NULLABLE, FK → `residentes(id)` ON DELETE SET NULL | Residente asociado (solo PROPIETARIO) |
| `tenant_id` | UUID | NOT NULL | ID del tenant |
| `activo` | BOOLEAN | NOT NULL, DEFAULT `true` | Usuario activo |
| `created_at` | TIMESTAMPTZ | NOT NULL, `now()` | |
| `updated_at` | TIMESTAMPTZ | NOT NULL, `now()` | |

**Relaciones:**
- `1:N` → `asignaciones_etapa`
- `1:1` → `residentes` (opcional)

---

#### 15. `asignaciones_etapa` — Etapas asignadas a cobradores

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | UUID | PK | ID único |
| `usuario_id` | UUID | NOT NULL, FK → `usuarios(id)` ON DELETE CASCADE | Cobrador |
| `etapa_id` | UUID | NOT NULL, FK → `etapas(id)` ON DELETE CASCADE | Etapa asignada |
| `tenant_id` | UUID | NOT NULL | ID del tenant |
| `created_at` | TIMESTAMPTZ | NOT NULL, `now()` | |
| UNIQUE | (`usuario_id`, `etapa_id`) | | No duplicar asignaciones |

---

### Módulo Notifications

#### 16. `actividad` — Registro de actividad / auditoría

| Columna | Tipo | Constraints | Descripción |
|---------|------|-------------|-------------|
| `id` | UUID | PK | ID único |
| `tenant_id` | UUID | NOT NULL | ID del tenant |
| `tipo` | VARCHAR(50) | NOT NULL | Tipo de actividad |
| `descripcion` | TEXT | NOT NULL | Descripción del evento |
| `usuario_nombre` | VARCHAR(255) | NOT NULL | Nombre del usuario |
| `usuario_id` | UUID | NOT NULL | ID del usuario |
| `metadata` | JSONB | NOT NULL, DEFAULT `'{}'` | Datos adicionales |
| `created_at` | TIMESTAMPTZ | NOT NULL, `now()` | |

---

### Vista

#### `casa_estado_cartera` — Estado de cartera por casa

Vista materializada que consolida:

- Datos de la casa, manzana, etapa y proyecto
- Residente actual (via tenencias activas)
- Plan de cobro activo
- Estadísticas de cobros (total, pagados, pendientes, vencidos)
- Estado de cartera calculado (`SIN_COBROS`, `EN_MORA`, `PENDIENTE`, `AL_DIA`)
- Saldo en mora en centavos

---

## Diagrama de relaciones

```
proyectos ──1:N── etapas ──1:N── manzanas ──1:N── casas
  │                                                   │
  │                                                   │
  ├──1:N── tarifas                  tenencias ──N:1───┘
  │                                  │    │
  ├──1:N── montos_predefinidos       │    └──1:N── residentes
  │                                  │             │
  └──1:N── planes_de_cobro ──1:N── periodos_cobro  │
              │                          │          │
              └──1:N── cobros ────────N:1───────────┘
                          │
                          ├──1:N── pagos
                          └──1:N── solicitudes ──N:1── usuarios ──1:N── asignaciones_etapa
                                                                       │
                                                                       └──N:1── etapas
```

---

## Deuda técnica

| # | Entidad | Descripción | Impacto |
|---|---------|-------------|---------|
| 1 | `Tarifa` | No tiene FK a `periodos_cobro` | Bajo impacto |
| 2 | `Pago` | No tiene FK a `usuarios` (columna `cobrador_id`) | Bajo impacto |

> ✅ Las columnas `conjunto_id` (Tarifa, MontoPagoPredefinido) y `propietario_id` (Tenencias) fueron actualizadas a `proyecto_id` y `residente_id` respectivamente.
