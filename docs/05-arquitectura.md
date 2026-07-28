# 05 — Arquitectura Hexagonal + DDD

> **Propósito:** Visión general de la arquitectura del sistema. Si solo lees un documento técnico, que sea este.

---

## Principios Arquitectónicos

1. **Hexagonal (Ports & Adapters):** el dominio es puro, sin dependencias externas. Frameworks, bases de datos, y servicios externos son adaptadores intercambiables.
2. **DDD con Bounded Contexts:** dividimos el dominio en 4 contextos delimitados, cada uno con su propio lenguaje y modelo.
3. **Offline-first:** la app móvil es la fuente de verdad inmediata; el backend es el sistema de record consolidado.
4. **Event-Driven:** los Bounded Contexts se comunican mediante eventos de dominio (desacoplamiento).
5. **Multi-tenant por diseño:** todas las entidades llevan `tenantId` desde el día 1.

---

## Diagrama C4 — Contexto del Sistema

```mermaid
flowchart TB
    subgraph Personas
        AdminP[👤 Administrador<br/>del Conjunto]
        CobradorP[👤 Cobrador]
        PropP[👤 Propietario]
    end

    subgraph Sistema["🏠 AppControlPagos<br/>(Sistema principal)"]
        direction TB
        BACKEND[Backend NestJS<br/>API + Jobs]
        MOBILE[App Móvil Flutter<br/>offline-first]
    end

    subgraph Externos["Sistemas Externos"]
        EMAIL[📧 Proveedor de Correo<br/>Resend / SendGrid]
        SUPABASE[(☁️ Supabase<br/>PostgreSQL + Auth)]
    end

    AdminP -->|configura conjunto,<br/>tarifas, usuarios| MOBILE
    AdminP -->|configura conjunto,<br/>tarifas, usuarios| BACKEND
    CobradorP -->|registra pagos<br/>(online/offline)| MOBILE
    PropP -->|consulta su cartera| MOBILE

    MOBILE -->|HTTPS REST| BACKEND
    MOBILE -->|SQLite local| MOBILE
    BACKEND -->|persiste datos| SUPABASE
    BACKEND -->|envía notificaciones| EMAIL
    BACKEND -.->|futuro multi-tenant| SUPABASE
```

---

## Bounded Contexts

```mermaid
flowchart LR
    subgraph BC1["🏘️ Comunidad<br/>(Community)"]
        C1[Conjunto, Etapa, Casa,<br/>Propietario, Tenencia]
    end
    subgraph BC2["🔐 Identidad y Acceso<br/>(IAM)"]
        C2[Usuario, Rol,<br/>AsignacionEtapa, Credencial]
    end
    subgraph BC3["💰 Cartera<br/>(Ledger)"]
        C3[CuentaDeCartera, Cuota,<br/>Pago, Tarifa,<br/>MontoPagoPredefinido]
    end
    subgraph BC4["📣 Notificaciones<br/>(Notifications)"]
        C4[Notificacion,<br/>ColaEnvio]
    end

    BC3 -->|PropietarioId, EtapaId| BC1
    BC3 -->|CobradorId| BC2
    BC4 -->|PropietarioId, email| BC1
    BC2 -->|valida permisos| BC1
    BC2 -->|valida permisos| BC3
```

| BC | Responsabilidad | Agregado Raíz |
|---|---|---|
| **Community** | Catálogo de conjunto, etapas, casas, propietarios | `Conjunto`, `Propietario` |
| **IAM** | Autenticación, autorización, roles | `Usuario` |
| **Ledger** | Cuotas, pagos, tarifas, montos predefinidos | `CuentaDeCartera` |
| **Notifications** | Cola de envío de correos, reintentos | `Notificacion` |

---

## Mapa de Módulos NestJS

```mermaid
flowchart TB
    subgraph App["AppControlPagos (NestJS)"]
        subgraph Shared["🔧 shared/"]
            AUTH[AuthModule]
            TENANT[TenantModule]
            EVENT[EventBusModule]
            COMMON[CommonModule<br/>Money, Clock, IdGen]
        end

        subgraph Community["🏘️ community/"]
            COMM_C[Controllers]
            COMM_UC[UseCases]
            COMM_DOM[Domain<br/>Entities, VOs]
            COMM_INF[Infrastructure<br/>PostgresRepo]
        end

        subgraph Iam["🔐 iam/"]
            IAM_C[Controllers]
            IAM_UC[UseCases]
            IAM_DOM[Domain]
            IAM_INF[Infrastructure]
        end

        subgraph Ledger["💰 ledger/"]
            LED_C[Controllers]
            LED_UC[UseCases]
            LED_DOM[Domain<br/>CuentaDeCartera, Cuota, Pago]
            LED_INF[Infrastructure]
        end

        subgraph Notifications["📣 notifications/"]
            NOT_C[Jobs/Controllers]
            NOT_UC[UseCases]
            NOT_DOM[Domain]
            NOT_INF[Infrastructure<br/>EmailAdapter]
        end
    end

    COMM_C --> COMM_UC --> COMM_DOM
    COMM_UC --> COMM_INF
    LED_C --> LED_UC --> LED_DOM
    LED_UC --> LED_INF
    LED_DOM -.eventos.-> NOT_DOM

    AUTH --> TENANT
    TENANT --> LED_C
    TENANT --> COMM_C
```

---

## Estructura de Carpetas (monorepo)

```
app-control-pagos/
├── apps/
│   ├── backend/                          # NestJS
│   │   ├── src/
│   │   │   ├── main.ts
│   │   │   ├── app.module.ts
│   │   │   ├── shared/
│   │   │   │   ├── auth/
│   │   │   │   ├── tenant/
│   │   │   │   ├── event-bus/
│   │   │   │   └── common/               # Money, Clock, IdGenerator
│   │   │   ├── community/
│   │   │   │   ├── application/          # UseCases, DTOs, Commands
│   │   │   │   ├── domain/               # Entities, VOs, Repos interfaces, Events
│   │   │   │   └── infrastructure/       # Postgres repos, controllers
│   │   │   ├── iam/
│   │   │   ├── ledger/
│   │   │   └── notifications/
│   │   ├── test/
│   │   └── nest-cli.json
│   │
│   └── mobile/                            # Flutter
│       ├── lib/
│       │   ├── main.dart
│       │   ├── core/
│       │   │   ├── network/              # ApiClient (Dio)
│       │   │   ├── database/             # SQLite local (sqflite/drift)
│       │   │   ├── sync/                 # SyncService, ConnectivityDetector
│       │   │   └── di/                   # GetIt / Injectable
│       │   ├── features/
│       │   │   ├── auth/
│       │   │   ├── cobro/                # RegistrarPago BLoC + UI
│       │   │   ├── cartera/              # VisualizarCartera BLoC + UI
│       │   │   ├── propietarios/
│       │   │   └── config/
│       │   └── shared/
│       └── test/
│
├── packages/
│   └── contracts/                         # DTOs TypeScript compartidos (openapi-ts)
│
├── infra/
│   ├── supabase/
│   │   ├── migrations/
│   │   └── seed.sql
│   └── docker-compose.yml
│
├── docs/                                  # ← ESTÁS AQUÍ
│   ├── README.md
│   ├── 01-vision.md ... 12-trazabilidad.md
│   ├── glosario.md
│   └── diagramas/
│
├── package.json
└── README.md
```

---

## Diagrama de Paquetes — Ledger (backend)

```mermaid
flowchart TB
    subgraph ledger["ledger/"]
        subgraph domain["domain/"]
            entities[entities/<br/>cuenta-de-cartera.ts<br/>cuota.ts<br/>pago.ts<br/>tarifa.ts<br/>monto-pago-predefinido.ts]
            vos[value-objects/<br/>money.ts<br/>frecuencia.ts<br/>estado-cuota.ts<br/>sync-status.ts]
            events[events/<br/>pago-registrado.event.ts<br/>cuota-vencida.event.ts]
            repos[ports/<br/>cuenta-cartera.repository.ts<br/>monto-predefinido.repository.ts]
            services[ports/<br/>clock.ts<br/>id-generator.ts]
        end
        subgraph application["application/"]
            usecases[use-cases/<br/>registrar-pago.use-case.ts<br/>generar-cuotas.use-case.ts<br/>marcar-vencidas.use-case.ts<br/>configurar-monto.use-case.ts]
            dto[dto/<br/>registrar-pago.command.ts]
        end
        subgraph infrastructure["infrastructure/"]
            controllers[controllers/<br/>pagos.controller.ts<br/>cartera.controller.ts]
            pgrepos[persistence/<br/>pg-cuenta-cartera.repository.ts]
            mappers[mappers/<br/>cuenta-cartera.mapper.ts]
        end
    end

    controllers --> usecases
    usecases --> repos
    usecases --> entities
    entities --> vos
    entities --> events
    pgrepos --> repos
    pgrepos --> mappers
    mappers --> entities
```
