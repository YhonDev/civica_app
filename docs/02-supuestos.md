# 02 — Supuestos Resueltos (Decisiones de Diseño)

> **Propósito:** Consolidar las decisiones que quedaron abiertas durante las fases de análisis, para que no haya ambigüedad al implementar.

---

## Decisiones confirmadas

| # | Pregunta | Decisión | Justificación |
|---|---|---|---|
| 1 | ¿Color de "pendiente dentro de plazo"? | **Amarillo** (tercer estado visual) | Verde=Pagado, Amarillo=Pendiente vigente, Rojo=Vencido. Reduce ansiedad del propietario y refleja la realidad. |
| 2 | ¿Alcance del Cobrador? | Ve **solo las Etapas asignadas** por el Admin | Principio de mínimo privilegio + escalabilidad (varios cobradores por conjunto). |
| 3 | ¿Propietario con varias Casas? | **Sí, relación 1:N** (un propietario puede tener varias unidades) | Caso real común (inversionistas). Se modela como `Tenencia` (entidad de asociación con fechas). |
| 4 | ¿Notificación push? | **Futuro (fase 2)**. MVP solo correo | Reduce complejidad inicial; el correo ya cumple notificación de vencimiento. |
| 5 | ¿Visibilidad del Propietario? | **Solo su propia información** | Habeas Data + simplicidad. |
| 6 | ¿Histórico de tarifas? | Cambios aplican **solo a cuotas futuras** | Inmutabilidad contable: una cuota ya generada no se recalcula. |
| 7 | ¿Propietario en varios Conjuntos? | **Sí, posible en el futuro** | Se modela `Propietario` como entidad independiente del `Conjunto`; la relación se da vía `Tenencia`. |
| 8 | ¿Pago parcial? | **Sí, con montos predefinidos** (máximo 5, configurados por Admin) | El cobrador no digita montos; selecciona de una lista. Control + transparencia + evita errores. |
| 9 | ¿Registro de propietario inline? | **Sí, durante el flujo de cobro** | Casos de recién mudados o personas sin acceso tecnológico. |
| 10 | ¿Aplicación de pagos parciales? | **FIFO**: el pago se aplica a la cuota más antigua con saldo pendiente | Simplicidad + lógica natural de cartera. |
| 11 | ¿Cobrador puede ver el histórico? | **Sí**, de los propietarios que tiene asignados | Necesario para resolver disputas en terreno. |

---

## Reglas de negocio derivadas

### Montos predefinidos

- El Admin configura hasta **5 montos activos** por conjunto.
- Cada monto tiene: `valor (en COP)`, `descripción`, `orden`, `activo/inactivo`.
- El cobrador **no puede ingresar un monto libre** — solo selecciona de la lista.
- Al registrar un pago, el sistema distribuye el monto FIFO entre cuotas pendientes.
- Si el monto pagado < saldo de la cuota → la cuota pasa a `PARCIAL`.
- Si el monto pagado >= saldo de las cuotas pendientes → se marca como `PAGADA` y el excedente pasa a la siguiente cuota.

### Tarifas y cuotas

- La `Tarifa` define cuánto **debe** pagar el propietario por período.
- El `MontoPredefinido` define cuánto **puede cobrar** el cobrador en una transacción.
- Son conceptos distintos. Un propietario puede deber $40.000 (tarifa mensual) pero pagar de a $10.000 (monto predefinido).
- Las cuotas ya generadas **no se modifican** si cambia la tarifa.

### Offline y sincronización

- El pago se guarda **primero en SQLite local** (estado `PENDIENTE_SYNC`).
- La cuota se marca como `PAGADA` inmediatamente en local.
- Al detectar conexión, la cola de pagos se sincroniza al backend.
- `clientPaymentId` (UUID v4) garantiza idempotencia en el backend.
- Si hay conflicto (mismo `clientPaymentId`, distinto contenido), se marca `CONFLICTO` y se notifica al Admin.

### Estados de cuota

```
PENDIENTE → PAGADA (pago total)
PENDIENTE → PARCIAL (pago parcial)
PENDIENTE → VENCIDA (pasó fecha límite)
PARCIAL → PAGADA (restante pagado)
PARCIAL → VENCIDA (pasó fecha límite)
VENCIDA → PAGADA (pago con recargo si aplica)
```
