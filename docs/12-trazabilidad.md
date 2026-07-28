# 12 — Trazabilidad: HU ↔ Casos de Uso ↔ Requisitos

> **Propósito:** Matriz de trazabilidad que conecta cada Historia de Usuario con su Caso de Uso y Requisito Funcional.

---

## Matriz completa

| HU | Descripción | Caso de Uso | RF |
|---|---|---|---|
| HU-01 | Crear Conjunto | — (CRUD) | RF01 |
| HU-02 | Crear Etapas | — (CRUD) | RF01 |
| HU-03 | Registrar Casas | — (CRUD) | RF01 |
| HU-04 | Definir Tarifas | CU-02 | RF04 |
| HU-05 | Editar Tarifas | CU-02 | RF04 |
| HU-05b | Configurar Montos Predefinidos | CU-02 (ext) | RF13 |
| HU-06 | Registrar Propietario | — (CRUD) | RF02 |
| HU-07 | Múltiples Casas por Propietario | — (CRUD) | RF02 |
| HU-08 | Crear Usuarios con Roles | — (CRUD) | RF03 |
| HU-09 | Vincular Usuario a Propietario | — (CRUD) | RF03 |
| HU-10 | Asignar Etapas a Cobrador | — (CRUD) | RF03 + RNF03 |
| HU-11 | Generar Cuota por Período | CU-03 | RF05 |
| HU-12 | Marcar Cuotas Vencidas | CU-04 | RF09 |
| HU-13 | Buscar Propietario | CU-01 (pasos 2-4) | RF07 |
| HU-14 | Registrar Pago (con montos predefinidos) | CU-01 | RF06 + RF13 |
| HU-15 | Pago Offline | CU-05 | RF06 + RNF07 |
| HU-16 | Sincronización Automática | CU-05 | RF12 |
| HU-17 | Trazabilidad de Pagos | CU-01 (auditoría) | RF10 + RNF08 |
| HU-17b | Registrar Propietario Inline | CU-01 (E2a) | RF02 |
| HU-18 | Cartera del Propietario (Calendario) | CU-06 | RF08 |
| HU-19 | Cartera Consolidada | — (variante de CU-06) | RF08 |
| HU-20 | Reporte de Recaudo | — (reporte) | RF11 |
| HU-21 | Notificar Vencimiento por Correo | CU-04 | RF09 + RNF05 |
| HU-22 | Reintento de Notificación | CU-04 | RNF05 |

---

## Matriz por RF

| RF | Descripción | HU asociadas | CU asociados |
|---|---|---|---|
| RF01 | Gestionar conjunto, etapas y casas | HU-01, HU-02, HU-03 | — |
| RF02 | Gestionar propietarios | HU-06, HU-07, HU-17b | — |
| RF03 | Gestionar usuarios y roles | HU-08, HU-09, HU-10 | — |
| RF04 | Configurar tarifas | HU-04, HU-05 | CU-02 |
| RF05 | Generar cuotas automáticas | HU-11 | CU-03 |
| RF06 | Registrar pagos offline | HU-14, HU-15 | CU-01, CU-05 |
| RF07 | Buscar propietarios | HU-13 | CU-01 |
| RF08 | Visualizar cartera | HU-18, HU-19 | CU-06 |
| RF09 | Notificar vencimientos | HU-12, HU-21, HU-22 | CU-04 |
| RF10 | Trazabilidad de pagos | HU-17 | CU-01 |
| RF11 | Reporte de recaudo | HU-20 | — |
| RF12 | Sincronización automática | HU-16 | CU-05 |
| RF13 | Montos predefinidos | HU-05b, HU-14 | CU-01, CU-02 |

---

## Matriz por Rol

| Rol | HU disponibles | CU que ejecuta |
|---|---|---|
| **Admin** | HU-01 a HU-10, HU-17, HU-19, HU-20 | CU-01, CU-02, CU-06 |
| **Cobrador** | HU-06, HU-07, HU-13 a HU-17b, HU-19 | CU-01, CU-06 |
| **Propietario** | HU-18 | CU-06 |
| **Sistema** | HU-11, HU-12, HU-16, HU-21, HU-22 | CU-03, CU-04, CU-05 |

---

## RF ↔ RNF (Requisitos No Funcionales)

| RNF | Descripción | Cómo se garantiza |
|---|---|---|
| RNF01 | La app debe funcionar offline | SQLite local + SyncService (ADR-002) |
| RNF02 | Los pagos no deben duplicarse | clientPaymentId + unique constraint (ADR-005) |
| RNF03 | El cobrador solo ve sus etapas | AsignacionEtapa + filtro en queries |
| RNF04 | Multi-tenant desde el diseño | tenantId + RLS (ADR-004) |
| RNF05 | Los correos deben reintentarse | Cola bullmq + 3 reintentos con backoff |
| RNF06 | Respuesta API < 500ms p95 | Índices compuestos (tenant_id, ...) + Redis cache |
| RNF07 | Sincronización < 5 segundos al reconectar | Batch sync + cola FIFO |
| RNF08 | Trazabilidad completa | event sourcing mínimo (audit log por eventos) |
| RNF09 | Control de montos | Montos predefinidos (ADR-003) |
