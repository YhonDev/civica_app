# 07 — Puertos e Interfaces (Ports & Adapters)

> **Propósito:** Definición de los contratos entre capas. El dominio solo depende de estas interfaces. Las implementaciones concretas (Postgres, SQLite, Resend) se conectan a través de estas interfaces sin que el dominio las conozca.

---

## 7.1 Puertos Entrantes (Use Cases / Commands)

Son las interfaces que los controladores (REST, CLI, jobs) invocan. El dominio no las conoce — viven en la capa de **application**.

### BC Cartera

```typescript
export interface RegistrarPagoCommand {
  clientPaymentId: string;      // UUID generado en móvil (idempotencia)
  propietarioId: string;
  monto: number;                // en centavos
  fechaPago: string;            // ISO
  cobradorId: string;
  tenantId: string;
}

export interface RegistrarPagoUseCase {
  execute(cmd: RegistrarPagoCommand): Promise<PagoResult>;
}

export interface GenerarCuotasUseCase {
  execute(tenantId: string, fechaHoy: Date): Promise<number>;
}

export interface MarcarVencidasUseCase {
  execute(tenantId: string, fechaHoy: Date): Promise<number>;
}

export interface ConfigurarMontoPredefinidoCommand {
  monto: number;
  descripcion: string;
  activo: boolean;
  orden: number;
  tenantId: string;
}

export interface ConfigurarMontoPredefinidoUseCase {
  execute(cmd: ConfigurarMontoPredefinidoCommand): Promise<void>;
}

export interface GenerarReporteRecaudoCommand {
  tenantId: string;
  fechaInicio: string;
  fechaFin: string;
}

export interface GenerarReporteRecaudoUseCase {
  execute(cmd: GenerarReporteRecaudoCommand): Promise<ReporteRecaudo>;
}
```

### BC Comunidad

```typescript
export interface RegistrarPropietarioCommand {
  nombre: string;
  telefono: string;
  email: string;
  casaId: string;
  tenantId: string;
}

export interface RegistrarPropietarioUseCase {
  execute(cmd: RegistrarPropietarioCommand): Promise<string>; // propietarioId
}

export interface CrearConjuntoCommand {
  nombre: string;
  tenantId: string;
}

export interface CrearConjuntoUseCase {
  execute(cmd: CrearConjuntoCommand): Promise<string>;
}
```

### BC IAM

```typescript
export interface CrearUsuarioCommand {
  username: string;
  password: string;
  email: string;
  rol: 'ADMIN' | 'COBRADOR' | 'PROPIETARIO';
  propietarioId?: string;
  tenantId: string;
}

export interface CrearUsuarioUseCase {
  execute(cmd: CrearUsuarioCommand): Promise<string>;
}

export interface AutenticarCommand {
  username: string;
  password: string;
  tenantId: string;
}

export interface AutenticarUseCase {
  execute(cmd: AutenticarCommand): Promise<TokenResult>;
}
```

---

## 7.2 Puertos Salientes (Repositorios y Servicios)

Son las interfaces que el dominio **define** y la infraestructura **implementa**.

### Repositorios

```typescript
// === BC Cartera ===
export interface CuentaDeCarteraRepository {
  findById(id: string): Promise<CuentaDeCartera | null>;
  findByPropietario(propietarioId: string, tenantId: string): Promise<CuentaDeCartera>;
  save(cuenta: CuentaDeCartera): Promise<void>;
  findConCuotasVencidasSinNotificar(tenantId: string): Promise<CuentaDeCartera[]>;
}

export interface MontoPagoPredefinidoRepository {
  findActivos(tenantId: string): Promise<MontoPagoPredefinido[]>;
  save(monto: MontoPagoPredefinido): Promise<void>;
  countActivos(tenantId: string): Promise<number>;
}

// === BC Comunidad ===
export interface PropietarioRepository {
  findById(id: string): Promise<Propietario | null>;
  save(propietario: Propietario): Promise<void>;
  findByCasa(casaId: string, tenantId: string): Promise<Propietario[]>;
}

export interface ConjuntoRepository {
  findById(id: string): Promise<Conjunto | null>;
  save(conjunto: Conjunto): Promise<void>;
}

// === BC IAM ===
export interface UsuarioRepository {
  findByUsername(username: string, tenantId: string): Promise<Usuario | null>;
  findById(id: string): Promise<Usuario | null>;
  save(usuario: Usuario): Promise<void>;
}

// === BC Notificaciones ===
export interface NotificacionRepository {
  save(notif: Notificacion): Promise<void>;
  findPendientesReintento(): Promise<Notificacion[]>;
}
```

### Servicios externos

```typescript
export interface EmailSender {
  send(destinatario: string, asunto: string, cuerpo: string): Promise<void>;
}

export interface EventBus {
  publish(event: DomainEvent): Promise<void>;
  subscribe<T extends DomainEvent>(handler: (e: T) => Promise<void>): void;
}

export interface Clock {
  now(): Date;
}

export interface IdGenerator {
  uuid(): string;
}
```

---

## 7.3 Adaptadores (Implementaciones)

| Puerto | Adaptador | Tecnología |
|---|---|---|
| `PropietarioRepository` | `PgPropietarioRepository` | PostgreSQL (Supabase) |
| `CuentaDeCarteraRepository` | `PgCuentaCarteraRepository` | PostgreSQL (Supabase) |
| `NotificacionRepository` | `PgNotificacionRepository` | PostgreSQL (Supabase) |
| `EmailSender` | `ResendEmailAdapter` | Resend API |
| `EventBus` | `InProcessEventBus` (MVP) | NestJS EventEmitter |
| `Clock` | `SystemClock` | `new Date()` |
| `IdGenerator` | `UuidGenerator` | `uuid` npm package |
| — | `SqlitePagoLocalRepository` | SQLite (drift/sqflite) |

## 7.4 Flujo completo de una solicitud

```
Controlador HTTP
    │ llama a
    ▼
Use Case (application/)
    │ usa puertos salientes (interfaces)
    ▼
Domain (entidades, VOs, reglas)
    │ persiste vía
    ▼
Repositorio (infrastructure/)
    │ implementa con
    ▼
PostgreSQL / SQLite
```
