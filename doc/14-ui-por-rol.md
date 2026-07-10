# 14 — Análisis UI por Rol · HU · CA · Métodos

> **Propósito:** Inventario consolidado de qué pantallas, funcionalidades, HU, CA y
> métodos de la app (frontend + backend) debe tener cada rol. Sirve como contrato
> funcional para desarrollo, QA y diseño UI.
>
> **Roles definidos (doc/01-vision.md):** Admin, Cobrador, Propietario, Sistema.
> **Sprints actuales:** S0–S5 (Mobile scaffold listo en S5; pagos FIFO en S4).

---

## Leyenda

- **HU** → Historia de Usuario (doc/03)
- **CA**  → Caso de Uso (doc/04)
- **RF**  → Requisito Funcional (doc/01 §88)
- **UI**  → Pantalla/componente que el usuario ve
- **BE**  → Endpoint REST backend (NestJS)
- **Local** → Operación sobre SQLite del móvil

---

## 1. ADMIN — Administrador del conjunto

### 1.1 Perfil funcional
Dueño/administrador del conjunto. Configura la estructura, los usuarios, las
tarifas, y supervisa la operación. **No realiza cobros en el día a día**,
pero sí puede hacerlo puntualmente.

### 1.2 Pantallas (UI) que debe tener

| # | Pantalla | Propósito | HU |
|---|---|---|---|
| A01 | **Login** | Acceso al sistema | — |
| A02 | **Dashboard ejecutivo** | KPIs del mes, evolución, actividad reciente | — |
| A03 | **Conjuntos** (lista) | Ver el/los conjuntos | HU-01 |
| A04 | **Conjunto — Detalle/Editar** | Editar nombre/datos básicos | HU-01 |
| A05 | **Etapas — Lista del conjunto** | Listar etapas | HU-02 |
| A06 | **Etapa — Crear/Editar** | Formulario de etapa | HU-02 |
| A07 | **Casas — Lista de la etapa** | Listar casas de la etapa | HU-03 |
| A08 | **Casa — Crear/Editar** | Formulario de casa (dirección interna) | HU-03 |
| A09 | **Propietarios — Lista global** | Buscar/filtrar todos los propietarios | HU-06, HU-07 |
| A10 | **Propietario — Crear/Editar** | Form con nombre, tel, email, asignación etapa+casa | HU-06, HU-07, HU-17b |
| A11 | **Propietario — Detalle** | Tenencias (casas asignadas), historial de pagos | HU-17 |
| A12 | **Usuarios — Lista** | Lista de usuarios del sistema | HU-08 |
| A13 | **Usuario — Crear** (rol Admin/Cobrador/Propietario) | Form + asignación a propietario/cobrador | HU-08, HU-09, HU-10 |
| A14 | **Asignación de Etapas a Cobrador** | Multi-select etapas por cobrador | HU-10 |
| A15 | **Tarifas — Configuración** | Semanal / Quincenal / Mensual | HU-04, HU-05 |
| A16 | **Montos Predefinidos** | Hasta 5 valores configurables | HU-05b |
| A17 | **Cartera consolidada** | Vista semáforo por propietario y etapa | HU-19 |
| A18 | **Reporte de Recaudo** | Filtros por período, exportable PDF/CSV | HU-20 |
| A19 | **Auditoría / Trazabilidad de pagos** | Quién cobró, cuándo, desde dónde | HU-17 |
| A20 | **Notificaciones — Cola fallida** | Correos que no se pudieron enviar (revisión manual) | HU-22 |
| A21 | **Más / Configuración** | Logout, perfil, about | — |

### 1.3 Historias de Usuario asignadas
- **Sprint 1:** HU-01, HU-02, HU-03, HU-06, HU-07
- **Sprint 2:** HU-08, HU-09, HU-10
- **Sprint 3:** HU-04, HU-05, HU-05b
- **Sprint 4/5:** HU-17 (auditoría)
- **Sprint 5:** HU-19 (cartera consolidada)
- **Sprint 7:** HU-20 (reporte)

### 1.4 Casos de Uso que ejecuta
CU-01 (puede cobrar puntualmente), CU-02 (configurar tarifas y montos).

### 1.5 Métodos / Endpoints backend que consume

| Verbo | Endpoint | HU/RF | Sprint |
|---|---|---|---|
| POST | `/auth/login` | — | S2 |
| GET/POST/PATCH | `/conjuntos` | HU-01 | S1 |
| GET/POST/PATCH/DELETE | `/conjuntos/:id/etapas` | HU-02 | S1 |
| GET/POST/PATCH | `/etapas/:id/casas` | HU-03 | S1 |
| GET/POST/PATCH/DELETE | `/propietarios` | HU-06, HU-07 | S1 |
| POST | `/propietarios/buscar?etapa=&casa=` | HU-13, HU-17b | S1/S2 |
| GET/POST/PATCH | `/usuarios` | HU-08 | S2 |
| POST | `/usuarios/:id/vincular-propietario` | HU-09 | S2 |
| PUT | `/usuarios/:cobradorId/etapas` | HU-10 | S2 |
| GET/PUT | `/tarifas` | HU-04, HU-05 | S3 |
| GET/POST/PATCH/DELETE | `/montos-predefinidos` (max 5) | HU-05b | S3 |
| GET | `/cartera?etapa=&estado=&periodo=` | HU-19 | S6 |
| GET | `/pagos?from=&to=&cobradorId=` | HU-17, HU-20 | S7 |
| GET | `/reportes/recaudo?from=&to=&formato=` | HU-20 | S7 |
| GET | `/notifications/fallidas` | HU-22 | S6 |

### 1.6 Reglas de negocio críticas (VOs/invariantes)
- Tarifas: monto > 0, COP sin decimales, `fechaVigencia` por versión.
- Montos predefinidos: **máximo 5 activos**; 6to → 400.
- Cobrador solo ve sus etapas (filtro obligatorio en queries de cartera/pagos).
- Toda edición de tarifa NO afecta cuotas ya generadas (snapshot en cuota).

---

## 2. COBRADOR — Operador de campo

### 2.1 Perfil funcional
Recorre las casas del conjunto. Es el usuario más activo en la app y **debe
poder trabajar sin conexión**. Solo ve las etapas que el Admin le asignó.

### 2.2 Pantallas (UI) que debe tener

| # | Pantalla | Propósito | HU |
|---|---|---|---|
| C01 | **Login** | Acceso al sistema | — |
| C02 | **Dashboard / Jornada del día** | Saludo + "Iniciar Jornada" + KPIs del día (cobros esperados, realizados) | — |
| C03 | **Etapas asignadas — Lista** | Las etapas que el Admin le asignó | HU-10 |
| C04 | **Casas de la etapa** | Lista de casas con semáforo (🟢🟡🔴) | — |
| C05 | **Propietario — Detalle / Cartera** | Cuotas pendientes/vencidas + últimas pagas | HU-19 |
| C06 | **Registrar Pago** (flujo guiado) | Wizard: etapa → casa → propietario → cuota → monto predefinido | HU-14, HU-15, HU-16, HU-17b |
| C07 | **Selección de monto predefinido** | Chips con los 5 (o menos) montos del Admin | HU-14, HU-05b |
| C08 | **Confirmación de pago** | Resumen + botón "Registrar" (offline-safe) | HU-14 |
| C09 | **Cola de sincronización** | Lista de pagos en estado PENDIENTE_SYNC, con retry | HU-15, HU-16 |
| C10 | **Indicador de conectividad** | Banner superior: ONLINE / OFFLINE | HU-15 |
| C11 | **Propietario — Crear inline** | Form rápido desde flujo de cobro si no existe | HU-17b |
| C12 | **Recibo digital** | Pantalla con QR/código tras registrar pago | — |
| C13 | **Más / Perfil** | Logout, ver mi info | — |

### 2.3 Historias de Usuario asignadas
- **Sprint 1:** HU-06, HU-07
- **Sprint 2:** HU-13 (búsqueda)
- **Sprint 4/5:** HU-14, HU-15, HU-16, HU-17b
- **Sprint 5:** HU-19 (cartera consolidada de sus etapas)

### 2.4 Casos de Uso que ejecuta
**CU-01 (Registrar Pago)** — el caso de uso más crítico del sistema. **CU-05
(Sincronización Offline→Backend)** de forma automática.

### 2.5 Métodos / Endpoints backend que consume

| Verbo | Endpoint | HU/RF | Modo |
|---|---|---|---|
| POST | `/auth/login` | — | Online |
| GET | `/cobrador/etapas` | HU-10 | Online + cache local |
| GET | `/etapas/:id/casas` | — | Online + cache local |
| GET | `/propietarios?etapa=&casa=` | HU-13 | Online + cache local |
| POST | `/pagos` (con `clientPaymentId`) | HU-14, HU-15 | **Online** (sync desde cola) |
| GET | `/pagos/mios?from=&to=` | HU-17 | Online |

### 2.6 Operaciones locales (SQLite en móvil)

| Método local | Tabla SQLite | Propósito | HU |
|---|---|---|---|
| `LocalPagoRepository.save(pago)` | `pagos_pendientes` | Encolar pago offline | HU-15 |
| `LocalPagoRepository.markSyncOk(id)` | `pagos_pendientes` | Limpiar cola tras POST OK | HU-16 |
| `LocalPagoRepository.markConflicto(id)` | `pagos_pendientes` | Reportar colisión de idempotencia | CU-05 E1 |
| `ConnectivityService.stream` | — | Detectar online/offline | HU-15, HU-16 |
| `SyncService.flush()` | `pagos_pendientes` | Batch FIFO de pagos al reconectar | HU-16 |
| `LocalCacheService.cacheEtapas()` | `cache_etapas` | Cache de etapas asignadas | HU-10 |
| `LocalCacheService.cacheCasas()` | `cache_casas` | Cache de casas por etapa | HU-13 |
| `LocalCacheService.cachePropietarios()` | `cache_propietarios` | Cache de propietarios | HU-13 |
| `LocalCuotaRepository.updateEstado()` | `cuotas` | Aplicar Pendiente→Pagada/Parcial local | HU-14 |

### 2.7 Reglas de negocio críticas
- Idempotencia: cada pago lleva `clientPaymentId` (UUID v4 generado en móvil).
  Duplicados en backend → 200 con el pago original (no error).
- FIFO: si el monto cubre más de una cuota, se aplica a la más antigua primero
  (regla de negocio del módulo `ledger`).
- Si el monto < saldo de la cuota → queda `PARCIAL` (no se rechaza).
- Sin conexión: NUNCA se bloquea el flujo de cobro; el pago queda en cola.

---

## 3. PROPIETARIO — Dueño de casa

### 3.1 Perfil funcional
Consulta su propio estado de cartera. **Solo lectura** en la app. Puede
solicitar revisión de un cargo si lo ve mal.

### 3.2 Pantallas (UI) que debe tener

| # | Pantalla | Propósito | HU |
|---|---|---|---|
| P01 | **Login** | Acceso (vinculado a su Usuario) | HU-09 |
| P02 | **Mi Estado** (dashboard) | Tarjeta grande 🟢/🟡/🔴 + saldo + próximo vencimiento | — |
| P03 | **Mi Cartera — Calendario** | Vista mensual con cada cuota coloreada | HU-18 |
| P04 | **Mi Cartera — Lista** | Lista cronológica con monto, fecha, cobrador | HU-18 |
| P05 | **Detalle de cuota** | Período, monto, fecha pago, cobrador que registró | HU-18 |
| P06 | **Mis Movimientos** (timeline) | Pagos recibidos + cuotas generadas | — |
| P07 | **Mi Casa** | Dirección, etapa, antigüedad | — |
| P08 | **Solicitar Revisión de cargo** | Form simple para pedir revisión de un cobro | — (extra UI) |
| P09 | **Mi Perfil** | Datos de contacto, logout | — |

### 3.3 Historias de Usuario asignadas
- **HU-18** (cartera con semáforo) — Sprint 6
- **HU-09** (vinculación Usuario↔Propietario) — Sprint 2 (config inicial)

### 3.4 Casos de Uso que ejecuta
**CU-06 (Visualizar Cartera Propia)** — solo lectura.

### 3.5 Métodos / Endpoints backend que consume

| Verbo | Endpoint | HU/RF | Modo |
|---|---|---|---|
| POST | `/auth/login` | — | Online |
| GET | `/propietarios/me/cartera?periodo=` | HU-18 | Online + cache |
| GET | `/propietarios/me/cuotas/:id` | HU-18 | Online |
| GET | `/propietarios/me/pagos` | — | Online |
| POST | `/propietarios/me/solicitudes-revision` | — | Online |

### 3.6 Reglas de negocio críticas
- RLS (Row Level Security) en Supabase: el propietario **solo ve sus propios
  datos**. El backend debe filtrar por `propietarioId = auth.user.propietarioId`.
- No ve datos de otros propietarios, ni tarifas, ni configuración.

---

## 4. SISTEMA — Jobs automáticos (sin UI)

### 4.1 Perfil funcional
Procesos backend que corren por cron. **No tienen pantalla**; se monitorean vía
logs y el panel del Admin (A20).

### 4.2 Responsabilidades

| Job | Cron | HU | Módulo NestJS |
|---|---|---|---|
| **Generar cuotas del período** | Diario 00:05 | HU-11 | `ledger` (generador) |
| **Marcar cuotas vencidas** | Diario 00:30 | HU-12 | `ledger` (vencidas) |
| **Encolar notificaciones de vencimiento** | Diario 00:35 | HU-21 | `notifications` |
| **Worker de envío de correos** | Continuo (cola BullMQ) | HU-21 | `notifications` |
| **Reintentos de notificación** | Continuo (backoff 15/30 min) | HU-22 | `notifications` |

### 4.3 Casos de Uso que ejecuta
- **CU-03** Generación automática de cuotas
- **CU-04** Notificar vencimiento + reintentos
- **CU-05** Sincronización (lado backend: aceptar pagos idempotentes)

### 4.4 Métodos / Endpoints internos (no REST público)

| Método | Descripción | HU |
|---|---|---|
| `GeneradorCuotasService.ejecutarDiario()` | Crea cuotas del nuevo período | HU-11 |
| `VencimientoService.marcarVencidas()` | Pasa Pendiente→Vencida si pasó la fecha | HU-12 |
| `NotificacionService.encolarVencimientos()` | Encola correos de cuotas vencidas | HU-21 |
| `EmailSender.send({to, subject, body})` | Puerto saliente (Resend/SendGrid) | HU-21 |
| `NotificacionService.reintentarFallidas()` | Backoff exponencial hasta 3 intentos | HU-22 |
| `PagoService.registrar(pago)` | POST interno con idempotencia | CU-05 |

### 4.5 Reglas de negocio críticas
- **Idempotencia:** `clientPaymentId` único en BD. Si llega duplicado, se
  devuelve el pago ya registrado, no se duplica.
- **Trazabilidad:** cada pago lleva `createdBy` (UserId), `createdAt`,
  `syncedAt`, `deviceId`. La auditoría la ve el Admin.
- **Reintentos:** 1er intento inmediato, 2do a +15min, 3ro a +45min total;
  al 3er fallo → estado `FALLIDA` para revisión manual del Admin.

---

## 5. Mapa de dependencias UI ↔ Roles

```
┌──────────────────────────────────────────────────────────┐
│  ADMIN     →  Acceso total: configuración + supervisión  │
│  COBRADOR  →  Operación de campo: cobrar + ver cartera   │
│  PROPIET.  →  Solo lectura: ver su cartera               │
│  SISTEMA   →  Sin UI: jobs automáticos                   │
└──────────────────────────────────────────────────────────┘
```

### 5.1 Pantallas compartidas entre roles
| Pantalla | Admin | Cobrador | Propietario |
|---|:---:|:---:|:---:|
| Login | ✅ | ✅ | ✅ |
| Dashboard | ejecutivo | jornada | mi estado |
| Cartera (visualización) | consolidada (A17) | por etapa (C05) | propia (P03) |
| Registrar pago | puntual | flujo principal | ❌ |
| Propietarios CRUD | ✅ | crear inline (C11) | ❌ |
| Configuración | ✅ | ❌ | ❌ |
| Reportes | ✅ | parcial (mis cobros) | ❌ |
| Perfil/Logout | ✅ | ✅ | ✅ |

---

## 6. Endpoints ya implementados (estado del repo)

Inspección rápida de `apps/backend/src/**/controllers/*.ts`:

| Módulo | Endpoints | Estado |
|---|---|---|
| `community` | `conjuntos.controller.ts`, `propietarios.controller.ts` | ✅ Implementado (S1) |
| `iam` | `auth.controller.ts`, `usuarios.controller.ts` | ✅ Implementado (S2) |
| `ledger` | `tarifas.controller.ts`, `montos.controller.ts`, `cuotas.controller.ts`, `cuentas-cartera.controller.ts`, `pagos.controller.ts` | ✅ Implementado (S3+S4) |
| `notifications` | (sin controllers visibles) | ⏳ Pendiente (S6) |
| `mobile/lib/features` | `auth/`, `cobro/` | 🟡 Scaffold (S5) |

**Pendientes clave para la UI:**
- Pantallas A02–A21 (Admin) — sin implementar
- Pantallas C02–C13 (Cobrador) — parcialmente, falta wizard completo
- Pantallas P01–P09 (Propietario) — sin implementar
- Notificaciones backend (módulo `notifications`)

---

## 7. Resumen de capacidades por rol (cheat sheet)

| Capacidad | Admin | Cobrador | Propietario | Sistema |
|---|:---:|:---:|:---:|:---:|
| Login | ✅ | ✅ | ✅ | — |
| Crear conjunto/etapa/casa | ✅ | ❌ | ❌ | — |
| Crear propietario | ✅ | ✅ (inline) | ❌ | — |
| Crear usuarios y roles | ✅ | ❌ | ❌ | — |
| Asignar etapas a cobrador | ✅ | ❌ | ❌ | — |
| Configurar tarifas | ✅ | ❌ | ❌ | — |
| Configurar montos predefinidos | ✅ | ❌ | ❌ | — |
| Buscar propietario | ✅ | ✅ | ❌ | — |
| Registrar pago online | ✅ | ✅ | ❌ | — |
| Registrar pago offline | ✅ | ✅ | ❌ | — |
| Sincronizar cola | ✅ | ✅ | ❌ | ✅ (server side) |
| Ver cartera propia | ✅ | ✅ | ✅ | — |
| Ver cartera consolidada | ✅ | ✅ (sus etapas) | ❌ | — |
| Ver auditoría de pagos | ✅ | parcial | ❌ | — |
| Generar reporte de recaudo | ✅ | ❌ | ❌ | — |
| Recibir correo vencimiento | ❌ | ❌ | ✅ | emisor |
| Generar cuotas | ❌ | ❌ | ❌ | ✅ |
| Marcar vencidas | ❌ | ❌ | ❌ | ✅ |
| Reintentar notificaciones | ❌ | ❌ | ❌ | ✅ |

---

## 8. Próximos pasos sugeridos (UI por sprint restante)

1. **Sprint 6** — Implementar pantallas de Propietario (P01–P09) y
   Cartera Consolidada (A17, C05). Módulo `notifications` backend.
2. **Sprint 6** — Dashboard del Cobrador (C02) y wizard completo de cobro
   (C06–C08) con manejo offline.
3. **Sprint 6** — Dashboard del Admin (A02) con KPIs y selector de mes.
4. **Sprint 7** — Reportes (A18) con exportador PDF/CSV.
5. **Sprint 7** — Auditoría de pagos (A19) y cola de notificaciones fallidas (A20).
