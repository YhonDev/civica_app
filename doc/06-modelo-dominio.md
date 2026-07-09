# 06 — Modelo de Dominio

> **Propósito:** Descripción detallada de los agregados, entidades, value objects e invariantes de cada Bounded Context.

---

## 6.1 BC Comunidad (Community)

### Agregado: Conjunto

```mermaid
classDiagram
    class ConjuntoAggregate {
        <<Aggregate Root>>
        +UUID id
        +String nombre
        +String tenantId
        +crearEtapa(nombre)
        +eliminarEtapa(etapaId)
    }
    class Etapa {
        <<Entity>>
        +UUID id
        +String nombre
        +crearCasa(direccion)
    }
    class Casa {
        <<Entity>>
        +UUID id
        +String direccionInterna
        +String metadata
    }
    class PropietarioAggregate {
        <<Aggregate Root>>
        +UUID id
        +String nombre
        +String telefono
        +String email
        +String tenantId
        +agregarTenencia(casa, fechaInicio)
        +finalizarTenencia(casa, fechaFin)
    }
    class Tenencia {
        <<Entity>>
        +UUID id
        +UUID casaId
        +Date fechaInicio
        +Date fechaFin?
    }

    ConjuntoAggregate "1" --> "*" Etapa
    Etapa "1" --> "*" Casa
    PropietarioAggregate "1" --> "*" Tenencia
    Tenencia "*" --> "1" Casa : referencia
```

**Invariantes:**
- Una `Casa` pertenece a una sola `Etapa`.
- Una `Tenencia` activa (sin `fechaFin`) no puede duplicarse para la misma `Casa`.
- `Propietario` es independiente del `Conjunto` (para soportar multi-tenant futuro).

---

## 6.2 BC IAM (Identidad y Acceso)

### Agregado: Usuario

```mermaid
classDiagram
    class UsuarioAggregate {
        <<Aggregate Root>>
        +UUID id
        +String username
        +String email
        +Credencial credencial
        +Rol rol
        +UUID? propietarioId
        +String tenantId
        +cambiarPassword(old, new)
        +asignarEtapa(etapaId)
        +revocarEtapa(etapaId)
    }
    class Credencial {
        <<Value Object>>
        +String passwordHash
        +String salt
        +Date ultimoCambio
    }
    class AsignacionEtapa {
        <<Entity>>
        +UUID etapaId
        +Date fechaAsignacion
    }

    UsuarioAggregate "1" --> "1" Credencial
    UsuarioAggregate "1" --> "*" AsignacionEtapa
```

**Invariantes:**
- `username` y `email` únicos dentro del tenant.
- Un `Usuario` con rol `Propietario` debe estar vinculado a un `Propietario`.
- Solo usuarios con rol `Cobrador` pueden tener `AsignacionEtapa`.

**Roles disponibles:**

| Rol | Permisos |
|---|---|
| `ADMIN` | CRUD completo sobre Conjunto, Etapas, Casas, Tarifas, Usuarios, Montos. Reportes. |
| `COBRADOR` | CRUD Propietarios (en etapas asignadas), Registrar pagos, Ver cartera (etapas asignadas). |
| `PROPIETARIO` | Ver solo su propia cartera (lectura). |

---

## 6.3 BC Cartera (Ledger) — EL MÁS CRÍTICO

### Agregado: CuentaDeCartera

```mermaid
classDiagram
    class CuentaDeCarteraAggregate {
        <<Aggregate Root>>
        +UUID id
        +UUID propietarioId
        +String tenantId
        +Frecuencia frecuencia
        +List~Cuota~ cuotas
        +List~Pago~ pagos
        +registrarPago(monto, fecha, cobradorId) Money
        +generarCuota(monto, periodo)
        +marcarVencidas(fechaHoy)
        +saldoPendiente() Money
    }
    class Cuota {
        <<Entity>>
        +UUID id
        +Money monto
        +Money montoPagado
        +Date periodoInicio
        +Date periodoFin
        +Date fechaVencimiento
        +EstadoCuota estado
        +Boolean notificacionEnviada
        +aplicarPago(monto) Money
        +saldo() Money
    }
    class Pago {
        <<Entity>>
        +UUID id
        +UUID clientPaymentId
        +UUID? cuotaId
        +Money monto
        +Date fechaPago
        +UUID cobradorId
        +Date fechaRegistro
        +Date? fechaSync
        +SyncStatus syncStatus
    }
    class Tarifa {
        <<Entity>>
        +UUID id
        +Frecuencia frecuencia
        +Money monto
        +Date fechaVigencia
    }
    class MontoPagoPredefinido {
        <<Entity>>
        +UUID id
        +Money monto
        +String descripcion
        +Boolean activo
        +Int orden
    }

    CuentaDeCarteraAggregate "1" --> "*" Cuota
    CuentaDeCarteraAggregate "1" --> "*" Pago
    CuentaDeCarteraAggregate "*" --> "*" Tarifa : usa vigente
    CuentaDeCarteraAggregate "*" --> "*" MontoPagoPredefinido : cobra con
```

### Invariantes CRÍTICAS (garantizadas por la raíz del agregado)

| # | Invariante | ¿Qué pasa si se viola? |
|---|---|---|
| 1 | `saldoPendiente() = Σ cuotas.saldo()` — nunca negativo | Saldos inconsistentes |
| 2 | Un `Pago` no puede aplicarse a una `Cuota` ya `PAGADA` | Doble pago |
| 3 | `clientPaymentId` es único (idempotencia para sync) | Duplicación de pagos |
| 4 | Máximo **5** `MontoPagoPredefinido` activos por tenant | Control financiero |
| 5 | Una `Cuota` pasa a `VENCIDA` solo por el job, nunca por el cobrador | Consistencia del proceso |
| 6 | Al aplicar un pago, se distribuye FIFO a la cuota más antigua con saldo | Orden lógico de cartera |

### Value Objects del BC Cartera

```typescript
// money.vo.ts
export class Money {
  constructor(
    public readonly amount: number,    // en centavos (integer)
    public readonly currency: 'COP'
  ) {}

  static ofCOP(pesos: number): Money {
    if (pesos < 0) throw new DomainError('Money no puede ser negativo');
    if (!Number.isInteger(pesos)) throw new DomainError('COP no acepta decimales');
    return new Money(pesos, 'COP');
  }

  add(other: Money): Money { /* ... */ }
  subtract(other: Money): Money { /* ... */ }
  isZero(): boolean { return this.amount === 0; }
  isGreaterThan(other: Money): boolean { return this.amount > other.amount; }
}

// frecuencia.vo.ts
export type Frecuencia = 'SEMANAL' | 'QUINCENAL' | 'MENSUAL';

export class Periodo {
  static calcularSiguiente(frecuencia: Frecuencia, desde: Date): Periodo {
    // Calcula inicio, fin y vencimiento según la frecuencia
  }
}

// estado-cuota.vo.ts
export type EstadoCuota = 'PENDIENTE' | 'PARCIAL' | 'PAGADA' | 'VENCIDA';

// estado-notificacion.vo.ts
export type EstadoNotif = 'PENDIENTE' | 'ENVIADA' | 'FALLIDA';

// sync-status.vo.ts
export type SyncStatus = 'PENDIENTE_SYNC' | 'SYNC_OK' | 'CONFLICTO';
```

### Diagrama de Estados de una Cuota

```mermaid
stateDiagram-v2
    [*] --> Pendiente : Generación automática<br/>(cron según frecuencia)

    Pendiente --> Pagada : Registrar Pago<br/>(monto total)
    Pendiente --> Parcial : Registrar Pago<br/>(monto parcial)
    Pendiente --> Vencida : Cron diario<br/>(fechaVencimiento < hoy)

    Parcial --> Pagada : Pago restante
    Parcial --> Vencida : Cron diario

    Vencida --> Pagada : Registrar Pago<br/>(con recargo si aplica)

    Pagada --> [*]

    state Vencida {
        [*] --> NotificacionPendiente
        NotificacionPendiente --> NotificacionEnviada : Email OK
        NotificacionPendiente --> NotificacionFallida : 3 reintentos fallidos
    }
```

---

## 6.4 BC Notificaciones (Notifications)

### Agregado: Notificacion

```mermaid
classDiagram
    class NotificacionAggregate {
        <<Aggregate Root>>
        +UUID id
        +UUID cuotaId
        +UUID propietarioId
        +String destinatario
        +String asunto
        +String cuerpo
        +EstadoNotif estado
        +Int intentos
        +Date? ultimoIntento
        +Date? fechaEnvio
        +registrarIntento(exito)
    }
```

**Invariantes:**
- Una notificación se crea **solo** cuando una cuota pasa a `VENCIDA` (evento de dominio).
- Máximo 3 reintentos antes de marcar `FALLIDA`.
- Backoff: inmediato → 15 min → 30 min.
