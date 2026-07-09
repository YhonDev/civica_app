# 11 — Architecture Decision Records (ADRs)

> **Propósito:** Registro formal de las decisiones arquitectónicas clave. Cada ADR describe el contexto, la decisión tomada, y las consecuencias.

---

## ADR-001: Hexagonal + DDD sobre MVC tradicional

| Campo | Valor |
|---|---|
| **ID** | ADR-001 |
| **Fecha** | 2026-07-10 |
| **Estado** | Aceptado |
| **Decisión** | Usar arquitectura hexagonal con DDD y Bounded Contexts |

**Contexto:** Necesitamos que el dominio sobreviva a cambios de framework y a la evolución multi-tenant. Un CRUD MVC tradicional pondría la lógica de negocio mezclada con los controllers.

**Decisión:** Arquitectura hexagonal con 4 Bounded Contexts (Community, IAM, Ledger, Notifications). El dominio es puro, sin dependencias externas. Los casos de uso (application) orquestan el dominio a través de puertos. La infraestructura implementa adaptadores.

**Consecuencias:**
- **+** El dominio es testeable en aislamiento.
- **+** Cambiar de base de datos o framework no toca reglas de negocio.
- **+** Eventos de dominio desacoplan los BCs.
- **-** Más código boilerplate inicial (interfaces, mappers, DI).
- **-** Curva de aprendizaje para developers no familiarizados con DDD/hexagonal.

---

## ADR-002: Offline-first en móvil con SQLite local

| Campo | Valor |
|---|---|
| **ID** | ADR-002 |
| **Fecha** | 2026-07-10 |
| **Estado** | Aceptado |
| **Decisión** | SQLite local como fuente de verdad inmediata; sincronización asíncrona al backend |

**Contexto:** Los cobradores trabajan en zonas con conectividad intermitente. Perder un cobro por falta de señal no es aceptable.

**Decisión:** La app móvil guarda el pago primero en SQLite local (estado `PENDIENTE_SYNC`), actualiza la cuota inmediatamente, y sincroniza al backend cuando detecta conexión. Usa `clientPaymentId` para idempotencia.

**Consecuencias:**
- **+** Cero pérdida de cobros por falta de conectividad.
- **+** Experiencia de usuario fluida (sin esperar a "enviando...").
- **+** El cobrador ve la cartera actualizada inmediatamente.
- **-** Complejidad añadida: cola de sincronización, detección de conectividad, manejo de conflictos.
- **-** Lógica de distribución FIFO de pagos duplicada (local y backend).

---

## ADR-003: Montos Predefinidos (hasta 5) en lugar de monto libre

| Campo | Valor |
|---|---|
| **ID** | ADR-003 |
| **Fecha** | 2026-07-10 |
| **Estado** | Aceptado |
| **Decisión** | El cobrador selecciona uno de hasta 5 montos configurados por el Admin |

**Contexto:** Se requiere control financiero, transparencia y evitar errores de digitación. Un cobrador que digita montos libremente puede equivocarse o defraudar.

**Decisión:** El Admin configura hasta 5 montos activos por conjunto. El cobrador solo puede seleccionar de esa lista. No hay entrada manual de montos.

**Consecuencias:**
- **+** Control total del Admin sobre los montos cobrados.
- **+** Elimina errores de digitación y fraudes por monto incorrecto.
- **+** Auditoría clara: cada pago se asocia a un monto predefinido.
- **-** Menos flexibilidad para el cobrador (no puede cobrar montos exactos no listados).
- **-** Si el propietario debe $37.500 y los montos son $10k, $20k, $30k, no puede pagar exacto.

---

## ADR-004: Multi-tenant por columna `tenant_id` + RLS

| Campo | Valor |
|---|---|
| **ID** | ADR-004 |
| **Fecha** | 2026-07-10 |
| **Estado** | Aceptado |
| **Decisión** | Esquema compartido con columna `tenant_id` y RLS en Supabase |

**Contexto:** MVP es single-tenant pero con evolución multi-tenant planeada. No queremos reescribir el modelo de datos ni el dominio cuando llegue el segundo conjunto.

**Decisión:** Todas las tablas tienen `tenant_id UUID NOT NULL`. RLS en Supabase filtra automáticamente por `current_setting('app.tenant_id')`. El dominio recibe `tenantId` explícito en cada comando.

**Consecuencias:**
- **+** Bajo costo inicial (una DB para todos los tenants).
- **+** Migrar a "database-per-tenant" no toca el dominio (solo el adaptador Repository).
- **+** RLS da seguridad a nivel de fila sin código extra.
- **-** Query performance puede degradarse con muchos tenants (mitigado con índices compuestos).
- **-** Riesgo de fuga de datos si RLS se configura mal.

---

## ADR-005: Money en centavos (integer)

| Campo | Valor |
|---|---|
| **ID** | ADR-005 |
| **Fecha** | 2026-07-10 |
| **Estado** | Aceptado |
| **Decisión** | `Money` VO almacena centavos como `integer` (no `float`) |

**Contexto:** Errores de punto flotante en cálculos financieros pueden causar discrepancias de centavos que se acumulan.

**Decisión:** El Value Object `Money` almacena el monto en centavos (enteros). La conversión a pesos se hace solo en la capa de presentación (UI).

**Consecuencias:**
- **+** Cero errores de redondeo en operaciones financieras.
- **+** Compare exacta (dos montos de $10 son idénticos).
- **-** Toda conversión a pesos humanos debe dividir entre 100 en la UI.
- **-** El JSON de la API usa centavos (requiere documentación para integradores).

---

## ADR-006: Eventos de dominio para desacoplar BCs

| Campo | Valor |
|---|---|
| **ID** | ADR-006 |
| **Fecha** | 2026-07-10 |
| **Estado** | Aceptado |
| **Decisión** | Bus de eventos interno (síncrono en MVP, migrable a Redis Streams) |

**Contexto:** Notificaciones, auditoría y caché deben reaccionar a cambios de cartera sin acoplarse al BC Ledger.

**Decisión:** Cuando un agregado completa una operación, emite un evento de dominio. Los handlers suscritos ejecutan lógica en otros BCs. En MVP el bus es síncrono (event emitter de NestJS). En fase 2 migra a Redis Streams para entrega garantizada.

**Consecuencias:**
- **+** BC Ledger no conoce detalles de notificaciones ni auditoría.
- **+** Fácil añadir nuevos handlers sin modificar el emisor.
- **+** En fase 2, Redis Streams da persistencia y entrega garantizada.
- **-** Síncrono en MVP significa que un handler lento bloquea la respuesta.
- **-** Mayor complejidad de debugging (flujo no lineal).

---

## ADR-007: Flutter + BLoC para estado predecible

| Campo | Valor |
|---|---|
| **ID** | ADR-007 |
| **Fecha** | 2026-07-10 |
| **Estado** | Aceptado |
| **Decisión** | BLoC pattern con `flutter_bloc` para manejo de estado |

**Contexto:** La UI tiene lógica de sincronización compleja (offline → online), estados de carga, error y datos. Necesitamos un patrón de estado predecible y testeable.

**Decisión:** Usar BLoC (Business Logic Component) con la librería `flutter_bloc`. Cada feature tiene su propio BLoC que maneja eventos de UI y emite estados.

**Consecuencias:**
- **+** Estado explícito y predecible (cada estado es una clase).
- **+** Fácil de testear (el BLoC es puro, sin dependencias de UI).
- **+** Separa cláramente UI de lógica de negocio.
- **+** Buena integración con Streams para sync service.
- **-** Más boilerplate que setState o Provider.
- **-** Curva de aprendizaje para developers nuevos en Flutter.

---

## Resumen de ADRs

| ID | Decisión | Status |
|---|---|---|
| ADR-001 | Hexagonal + DDD sobre MVC | ✅ Aceptado |
| ADR-002 | Offline-first con SQLite local | ✅ Aceptado |
| ADR-003 | Montos predefinidos (≤5) en lugar de monto libre | ✅ Aceptado |
| ADR-004 | Multi-tenant por columna `tenant_id` + RLS | ✅ Aceptado |
| ADR-005 | Money en centavos (integer) | ✅ Aceptado |
| ADR-006 | Eventos de dominio para desacoplar BCs | ✅ Aceptado |
| ADR-007 | Flutter + BLoC para estado predecible | ✅ Aceptado |
