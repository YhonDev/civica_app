# 01 — Visión General

> **Propósito:** Entender el problema que resuelve la app, a quién va dirigida, y cuál es el alcance del MVP.

---

## Problema

Los conjuntos residenciales administran manualmente el cobro de cuotas de mantenimiento:

- **Cobradores** recorren las casas, anotan pagos en libretas físicas, y al final del día transcriben a Excel.
- **Propietarios** no saben si están al día hasta que preguntan.
- **Administradores** no tienen visibilidad en tiempo real de morosidad.
- Los recibos se **pierden**, los datos se **digitación mal**, y no hay **trazabilidad** de quién cobró qué.

## Solución

Una aplicación **mobile-first** con capacidad **offline** que permite:

1. **Registrar pagos desde el móvil** sin conexión a Internet (SQLite local → sync automático).
2. **Visualizar la cartera** con semáforo de colores (verde/amarillo/rojo).
3. **Generar cuotas automáticamente** según la frecuencia de pago de cada propietario.
4. **Notificar vencimientos** por correo electrónico.
5. **Controlar montos de cobro** con hasta 5 valores predefinidos (transparencia).

## Actores del sistema

| Actor | Descripción | Dispositivo |
|---|---|---|
| **Admin** | Administrador del conjunto. Configura tarifas, etapas, usuarios, reportes. | Móvil + opcional web |
| **Cobrador** | Recorre las casas y registra pagos. Ve solo sus etapas asignadas. | Móvil (offline-first) |
| **Propietario** | Dueño de una o más casas. Consulta su cartera. | Móvil |
| **Sistema** | Jobs automáticos: generar cuotas, marcar vencidas, enviar correos. | Backend (cron) |

## Alcance del MVP

### Incluye (MVP)

- [x] Registro y configuración del conjunto, etapas y casas
- [x] Registro de propietarios (con asignación a casa)
- [x] Creación de usuarios con roles (Admin, Cobrador, Propietario)
- [x] Configuración de tarifas por frecuencia (semanal/quincenal/mensual)
- [x] Configuración de hasta **5 montos predefinidos** de pago
- [x] Generación automática de cuotas (cron diario)
- [x] Registro de pagos **offline-first** con cola de sincronización
- [x] Cartera visual con colores (pagado/pendiente/vencido)
- [x] Reporte consolidado de recaudo (Admin)
- [x] Notificaciones de vencimiento por correo
- [x] Trazabilidad completa: quién cobró, cuándo, desde dónde

### No incluye (MVP)

- ❌ Notificaciones push (RF13 — post-MVP)
- ❌ Pagos electrónicos / pasarela de pagos
- ❌ Multi-tenant activo (diseñado pero no implementado)
- ❌ Web App completa (solo móvil + backend API)

## Métricas de éxito (MVP)

| Métrica | Objetivo |
|---|---|
| Tiempo de registro de un pago | < 30 segundos |
| Cobros sin conexión | 100% funcionales (sin pérdida de datos) |
| Sincronización al reconectar | < 5 segundos |
| Cuotas vencidas sin notificar | 0% (todas notificadas en < 1 hora) |
| Trazabilidad | 100% de pagos trazables a cobrador+fecha |

## Glosario rápido

| Término | Definición |
|---|---|
| **Conjunto** | Entidad raíz. Ej: "Portal del Prado" |
| **Etapa** | Fase constructiva dentro del conjunto. Ej: "Etapa 1 - Manzana A" |
| **Casa / Unidad** | Unidad habitacional dentro de una etapa. |
| **Propietario** | Persona dueña de una o más casas. |
| **Tenencia** | Relación entre propietario y casa (con fechas inicio/fin). |
| **Cuota** | Monto periódico que debe pagar un propietario. |
| **Tarifa** | Monto configurado por frecuencia (define cuánto debe pagar). |
| **Monto Predefinido** | Hasta 5 valores que el cobrador puede seleccionar al cobrar. |
| **Cartera** | Estado consolidado de cuotas de un propietario o conjunto. |
| **Frecuencia** | Periodicidad de pago: SEMANAL, QUINCENAL, MENSUAL. |
| **Pago** | Transacción que cancela total o parcialmente una cuota. |

> Para el glosario completo y detallado, ver [`glosario.md`](./glosario.md).

---

## Requisitos Funcionales (alto nivel)

| ID | Descripción |
|---|---|
| RF01 | Gestionar conjunto, etapas y casas |
| RF02 | Gestionar propietarios (CRUD + asignación a casas) |
| RF03 | Gestionar usuarios con roles (Admin, Cobrador, Propietario) |
| RF04 | Configurar tarifas por frecuencia (semanal/quincenal/mensual) |
| RF05 | Generar cuotas automáticamente al inicio de cada período |
| RF06 | Registrar pagos con soporte offline |
| RF07 | Buscar propietarios por etapa y casa |
| RF08 | Visualizar cartera con semáforo de colores |
| RF09 | Notificar vencimientos por correo |
| RF10 | Trazabilidad de pagos (quién, cuándo) |
| RF11 | Reporte de recaudo por período |
| RF12 | Sincronización automática al recuperar conexión |
| RF13 | Configurar hasta 5 montos predefinidos de pago |

> Para trazabilidad detallada HU ↔ CU ↔ RF, ver [`12-trazabilidad.md`](./12-trazabilidad.md).
