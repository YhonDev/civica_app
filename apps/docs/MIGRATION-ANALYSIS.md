# 🔍 Análisis Completo y Guía de Migración — Civica Pago App

> **Fecha:** 29 de Agosto, 2026
> **Estado:** Documento de análisis y planificación
> **Objetivo:** Migrar backend NestJS → Go o Java Spring Boot

---

## 📑 Tabla de Contenidos

1. [Resumen Ejecutivo](#1-resumen-ejecutivo)
2. [Arquitectura Actual](#2-arquitectura-actual)
3. [Análisis de Errores y Bugs](#3-análisis-de-errores-y-bugs)
4. [Mejoras de Diseño](#4-mejoras-de-diseño)
5. [Comparativa: Go vs Java Spring Boot](#5-comparativa-go-vs-java-spring-boot)
6. [Opciones de Cloud Deployment](#6-opciones-de-cloud-deployment)
7. [Guía de Migración a Go](#7-guía-de-migración-a-go)
8. [Guía de Migración a Java Spring Boot](#8-guía-de-migración-a-java-spring-boot)
9. [Checklist de Decisión](#9-checklist-de-decisión)

---

## 1. Resumen Ejecutivo

La app **Civica Pago** es un sistema de recaudo comunitario multi-tenant para cuotas de vigilancia, construido con:

- **Backend:** NestJS (TypeScript) + TypeORM + PostgreSQL
- **Mobile:** Flutter (Android/iOS/macOS/Linux/Windows/Web)
- **Base de datos:** PostgreSQL

**Motivación de la migración:** Experiencia personal y productividad con Go o Java.

**Hallazgos clave:**
- Arquitectura DDD sólida con entidades ricas y patrón Repository
- 9+ bugs identificados (1 crítico, 4 altos, 4 medios)
- Módulo Ledger con ~40 archivos backend
- La migración preserva la lógica de negocio, Flutter frontend y PostgreSQL

---

## 2. Arquitectura Actual

### 2.1 Stack Tecnológico

| Capa | Tecnología |
|------|-----------|
| Backend | NestJS 10+ (TypeScript) |
| ORM | TypeORM |
| Base de datos | PostgreSQL |
| Mobile | Flutter (Dart) |
| Auth | JWT (access + refresh tokens) |
| Cron | @nestjs/schedule |
| Validación | class-validator |
| Seguridad | Helmet, CORS, Rate Limiting |

### 2.2 Estructura del Backend

```
backend/src/
├── shared/
│   ├── auth/          # JWT, guards, roles
│   ├── tenant/        # Multi-tenancy
│   └── common/        # Value objects, base repository
├── community/
│   ├── domain/        # Residente, Casa, Manzana, Etapa, Tenencia
│   ├── application/   # Use cases
│   └── infrastructure/# Controllers, repositories
├── iam/
│   ├── domain/        # Usuario, AsignacionEtapa
│   ├── application/   # CrearUsuario, AsignarEtapa
│   └── infrastructure/# Auth controller, usuarios controller
├── ledger/
│   ├── domain/        # 10 entidades (Cobro, Pago, Tarifa, etc.)
│   ├── application/   # 13 use cases + 2 queries + services
│   └── infrastructure/# 9 controllers, 9 repositories, 2 cron jobs
└── notifications/
    ├── domain/        # Actividad, Notificacion
    └── infrastructure/# Email sender, jobs
```

### 2.3 Módulo Ledger (corazón del sistema)

| Componente | Cantidad | Descripción |
|-----------|----------|-------------|
| Entidades | 10 | Cobro, Pago, PagoEdicion, Tarifa, MontoPagoPredefinido, PlanDeCobro, PeriodoCobro, Solicitud, Ticket, TicketCobro |
| Use Cases | 13 | RegistrarPago, EliminarPago, CorregirPago, ValidarPago, GenerarCobros, EliminarCobro, MarcarVencidas, GenerarTicket, GenerarReporte, ConfigurarTarifa, ActualizarTarifa, ConfigurarMonto, TarifaDerivacion |
| Controllers | 9 | Cobros, Pagos, Tarifas, Montos, PlanesDeCobro, Dashboard, Solicitudes, Tickets, Reportes |
| Repositories | 9 | Cobro, Pago, Tarifa, MontoPagoPredefinido, PlanDeCobro, PeriodoCobro, Solicitud, Ticket |
| Cron Jobs | 2 | GenerarCobrosJob (00:05), MarcarVencidasJob (00:10) |
| Tests E2E | 9 | app, community, auth, ledger, dashboard, pagos, lifecycle-recaudo, beta1-cuotas-role-gating |

### 2.4 API Endpoints Principales

```
# Cobros
GET    /api/cobros                          # Listar (admin/cobrador)
GET    /api/cobros/residente/:id            # Por residente
GET    /api/cobros/casas/cartera-resumen    # Resumen cartera
DELETE /api/cobros/:id                      # Eliminar (admin)

# Pagos
POST   /api/pagos                           # Registrar pago (FIFO)
DELETE /api/pagos/:id                       # Eliminar/revertir
PATCH  /api/pagos/:id/corregir              # Corregir monto
PATCH  /api/pagos/:id/validar               # Validar/rechazar

# Dashboard
GET    /api/dashboard/administrador         # Admin dashboard
GET    /api/dashboard/cobrador              # Cobrador dashboard
GET    /api/dashboard/residente             # Residente dashboard
GET    /api/dashboard/residente/timeline    # Timeline paginada

# Tarifas
POST   /api/tarifas                         # Crear (derive 3 modalidades)
GET    /api/tarifas                         # Listar
GET    /api/tarifas/vigentes                # Vigentes por conjunto
PATCH  /api/tarifas/:id                     # Actualizar
DELETE /api/tarifas/:id                     # Desactivar

# Otros
GET    /api/solicitudes                     # Listar solicitudes
POST   /api/solicitudes                     # Crear solicitud
PATCH  /api/solicitudes/:id/resolver        # Resolver solicitud
GET    /api/tickets                         # Listar tickets
GET    /api/reportes/recaudo                # Reporte de recaudo
GET    /api/planes-de-cobro                 # Listar planes activos
POST   /api/montos-predefinidos             # Crear monto predefinido
```

---

## 3. Análisis de Errores y Bugs

### 3.1 🚨 BUGS CRÍTICOS

#### BUG #1: SQL Injection en RegistrarPagoUseCase
**Archivo:** `backend/src/ledger/application/use-cases/registrar-pago.use-case.ts` (líneas 167-175)

```typescript
const pendingSolicitudes = await queryRunner.query(
  `SELECT id FROM solicitudes 
   WHERE tenant_id = $1 
     AND (residente_id = $2 OR cobro_id IN (${cobrosAfectados.map((_, i) => `$${i + 3}`).join(',') || 'NULL'}))
     AND estado IN ('PENDIENTE', 'EN_REVISION')`,
  [input.tenantId, input.residenteId, ...cobrosAfectados.map((c) => c.id)],
);
```

**Problema:** Si `cobrosAfectados` está vacío, genera SQL: `cobro_id IN (NULL)` — resultados incorrectos. El parámetro `$N` se genera por interpolación, no por query parameter seguro.

**Solución:** Usar `In()` de TypeORM o construir array de parámetros limpio.

---

#### BUG #2: findByCobradorToday carga TODOS los pagos
**Archivo:** `backend/src/ledger/infrastructure/persistence/pago.repository.ts` (líneas 141-157)

```typescript
async findByCobradorToday(cobradorId: string) {
  const pagos = await this.repo.find({
    where: { cobradorId },
    order: { fechaPago: 'DESC' },
  });
  const hoyPagos = pagos.filter((p) => p.fechaPago.startsWith(hoyStr));
```

**Problema:** Carga TODOS los pagos de la historia del cobrador y filtra en memoria. Con el tiempo será un problema de rendimiento grave.

**Solución:** Filtrar por `fechaPago` directamente en el query WHERE.

---

#### BUG #3: findAllActivos() sin filtro de tenant
**Archivo:** `backend/src/ledger/infrastructure/persistence/plan-de-cobro.repository.ts`

```typescript
async findAllActivos(): Promise<PlanDeCobro[]> {
  return this.repo.find({
    where: { activa: true },
  });
}
```

**Problema:** No filtra por `tenantId`. Los cron jobs generarían cobros para TODOS los tenants.

**Solución:** Agregar filtro `tenantId` o usar `findAllActivosByTenant(tenantId)`.

---

#### BUG #4: Dashboard ejecuta jobs completos en cada request del residente
**Archivo:** `backend/src/ledger/infrastructure/controllers/dashboard.controller.ts` (líneas 290-296)

```typescript
if (this.generarCobrosUC) {
  await this.generarCobrosUC.execute().catch(() => {});
}
if (this.marcarVencidasUC) {
  await this.marcarVencidasUC.execute().catch(() => {});
}
```

**Problema:** Cada request del dashboard residente ejecuta generación de cobros Y marcado de vencidas para TODOS los planes de TODOS los tenants.

**Solución:** Eliminar estas líneas y confiar en los cron jobs programados.

---

### 3.2 ⚠️ BUGS MEDIOS

#### BUG #5: Refresh token blacklist en memoria
**Archivo:** `backend/src/shared/auth/auth.service.ts` (línea 9)

```typescript
private readonly revokedRefreshTokens = new Set<string>();
```

**Problema:** Si el servidor se reinicia, todos los tokens revocados se pierden.

**Solución:** Usar Redis o tabla en DB.

---

#### BUG #6: Solicitud.nroRecibo usa Math.random()
**Archivo:** `backend/src/ledger/domain/solicitud.entity.ts` (líneas 90-92)

```typescript
const randomNum = Math.floor(100000 + Math.random() * 900000);
solicitud.nroRecibo = `TK-${randomNum}`;
```

**Problema:** Prefijo `TK-` colisiona con tickets (`TKT-YYYY-NNNNNN`). `Math.random()` puede generar duplicados.

**Solución:** Usar UUID corto o secuencial.

---

#### BUG #7: ValidarPagoUseCase reversa con LIFO pero aplica con FIFO
**Archivo:** `backend/src/ledger/application/use-cases/validar-pago.use-case.ts`

**Problema:** La reversión usa LIFO (más reciente primero) pero el pago original fue FIFO (más antiguo primero). Puede dejar estados inconsistentes.

**Solución:** Mantener consistencia en la dirección de reversión.

---

#### BUG #8: CorregirPagoUseCase sin control de concurrencia
**Archivo:** `backend/src/ledger/application/use-cases/corregir-pago.use-case.ts`

**Problema:** Revierte y re-aplica pagos sin pessimistic locking. Dos admins corrigiendo simultáneamente podrían corromper saldos.

**Solución:** Agregar `@Transactional` con locking explícito.

---

### 3.3 📋 BUGS MENORES

| # | Problema | Ubicación |
|---|----------|-----------|
| 9 | `EstadoCobro` incluye `EN_REVISION` pero no se usa | `value-objects.ts` |
| 10 | `findByResidentes()` no carga relaciones pero se usa con `c.residente` | `cobro.repository.ts` |
| 11 | `SolicitudesController` duplica `listarPendientes` y `listarPendientesAdmin` | `solicitudes.controller.ts` |
| 12 | `SolicitudRepository.findPendingByTenant()` carga todo y filtra en memoria | `solicitud.repository.ts` |

---

## 4. Mejoras de Diseño

### 4.1 Problemas de Arquitectura

| # | Área | Problema | Impacto |
|---|------|----------|---------|
| 1 | Performance | `eager: true` en ManyToOne causa N+1 queries silenciosos | ALTO |
| 2 | DRY | Lógica de reversión LIFO duplicada en 3 use cases | MEDIO |
| 3 | Performance | `findByResidentes()` no carga relaciones | MEDIO |
| 4 | Performance | `findPendingByTenant()` carga todo y filtra en memoria | MEDIO |
| 5 | API | No hay versión de API (`/api/v1/`) | BAJO |
| 6 | Docs | No hay Swagger/OpenAPI | BAJO |
| 7 | Testing | Falta tests para SolicitudesController y TicketsController | MEDIO |
| 8 | Performance | Faltan índices en `cobros(estado, tenant_id, fecha_vencimiento)` | ALTO |

### 4.2 Lo que está bien hecho ✅

1. **Transacciones con pessimistic locking** en RegistrarPagoUseCase
2. **Idempotencia** en pagos y generación de cobros
3. **Tickets inmutables** con snapshot de datos
4. **Value Objects** inmutables (Money, Periodo, TenantId)
5. **Abstracción de secure storage** (testeable)
6. **Auth interceptor** con refresh automático
7. **BaseTenantRepository** — aislamiento multi-tenant
8. **Job scheduling** automatizado

---

## 5. Comparativa: Go vs Java Spring Boot

### 5.1 Comparación Técnica

| Aspecto | Go | Java Spring Boot | NestJS (actual) |
|---------|-----|-----------------|-----------------|
| **Velocidad de migración** | 3-4 semanas | 4-5 semanas | N/A |
| **RAM mínima** | ~30 MB | ~256-512 MB | ~120 MB |
| **Tamaño Docker** | ~15 MB | ~200-300 MB | ~200-400 MB |
| **Cold start** | < 50ms | 5-30 segundos | 1-2 segundos |
| **Curva de aprendizaje** | Moderada | Baja (si conoces POO) | Ya la tienes |
| **Líneas de código** | ~3,000 | ~5,000+ | ~4,000+ |
| **Testing** | `go test` (rápido) | JUnit 5 (maduro) | Jest (ya configurado) |

### 5.2 Comparación de Costos Cloud

| Componente | Go | Java Spring Boot | NestJS |
|-----------|-----|-----------------|--------|
| **Compute mínimo** | 0.25 vCPU / 256MB | 0.5-1 vCPU / 512MB-1GB | 0.5 vCPU / 512MB |
| **Railway** | ~$10-15/mes | ~$25-35/mes | ~$15-25/mes |
| **Cloud Run** | ~$5-10/mes | ~$15-25/mes | ~$10-15/mes |
| **AWS ECS** | ~$15-25/mes | ~$40-60/mes | ~$25-40/mes |
| **DB PostgreSQL** | ~$7-10/mes | ~$7-10/mes | ~$7-10/mes |
| **Total estimado** | **~$15-20/mes** | **~$35-50/mes** | **~$25-35/mes** |

### 5.3 Stack Recomendado por Opción

#### 🐹 Go
```
Go 1.22+
├── Framework:     Gin o Echo
├── ORM:           sqlx + pgx (directo a PostgreSQL)
├── Auth:          golang-jwt/jwt v5
├── Migrations:    golang-migrate/migrate
├── Cron:          robfig/cron
├── Config:        viper
├── Validation:    go-playground/validator
├── Testing:       testify + go test -race
└── Logging:       zerolog o zap
```

#### ☕ Java Spring Boot
```
Java 21 LTS + Spring Boot 3.3+
├── ORM:           Spring Data JPA + Hibernate
├── Auth:          Spring Security + jjwt
├── Migrations:    Flyway
├── Scheduling:    @Scheduled
├── Validation:    Jakarta Bean Validation
├── Testing:       JUnit 5 + MockMvc + Testcontainers
├── Config:        application.yml + @Configuration
└── Logging:       SLF4J + Logback
```

### 5.4 Mapeo de Conceptos NestJS → Go / Java

| NestJS | Go | Java Spring Boot |
|--------|-----|-----------------|
| `@Injectable()` | `type Service struct` | `@Service` |
| `@Controller()` | `func Handler()` | `@RestController` |
| `@UseGuards(JwtAuthGuard)` | Middleware | `@PreAuthorize` |
| `@Roles(RolUsuario.ADMIN)` | Middleware check | `@PreAuthorize("hasRole('ADMIN')")` |
| `@CurrentTenant()` | Middleware + context | TenantContext + Interceptor |
| `@Cron('0 5 0 * * *')` | `robfig/cron` | `@Scheduled(cron = "...")` |
| TypeORM Repository | sqlx queries | Spring Data JPA Repository |
| `class-validator` DTOs | `binding:"required"` | `@Valid` + Jakarta |
| `DataSource.transaction()` | `db.Beginx()` | `@Transactional` |
| `@nestjs/schedule` | `robfig/cron/v3` | `@EnableScheduling` |
| `forwardRef(() => Module)` | N/A (no circular deps) | `@Lazy` |

### 5.5 Recomendación Final

| Si tu objetivo es... | Elige... |
|---------------------|----------|
| **Aprendizaje y simplicidad** | 🐹 Go |
| **Menor costo cloud** | 🐹 Go |
| **Deploy más rápido** | 🐹 Go |
| **Empleabilidad en LATAM** | ☕ Java |
| **Ecosistema enterprise** | ☕ Java |
| **Ya conoces POO/TypeScript** | ☕ Java |
| **Quieres menos código** | 🐹 Go |
| **Binario pequeño para deploy** | 🐹 Go |

---

## 6. Opciones de Cloud Deployment

### 6.1 Railway (Recomendado para empezar)

| Característica | Detalle |
|---------------|---------|
| **Free tier** | Trial 30 días con $5 crédito |
| **Precio** | $5/mes base + uso real |
| **PostgreSQL** | Managed, un clic |
| **Cron jobs** | Nativos |
| **Deploy** | Conectar GitHub → auto-deploy |
| **Región** | US-East (default) |

```json
// railway.json
{
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "Dockerfile"
  },
  "deploy": {
    "startCommand": "./server",
    "healthcheckPath": "/api/health"
  }
}
```

### 6.2 Google Cloud Run (Más barata)

| Característica | Detalle |
|---------------|---------|
| **Free tier** | 2M requests/mes gratis |
| **Precio** | Pay-per-use (solo cuando hay tráfico) |
| **PostgreSQL** | Cloud SQL o Neon externo |
| **Cron jobs** | Cloud Scheduler |
| **Scale-to-zero** | Sí (sin tráfico = $0) |

### 6.3 Fly.io (Global)

| Característica | Detalle |
|---------------|---------|
| **Free tier** | 3 shared VMs |
| **PostgreSQL** | Managed disponible |
| **Regiones** | Múltiples (bajo latency LATAM) |
| **Precio** | ~$5-15/mes |

### 6.4 Comparativa de Plataformas

| Plataforma | Go | Java | NestJS | PostgreSQL | Cron | Facilidad |
|-----------|-----|------|--------|-----------|------|-----------|
| **Railway** | ✅ | ✅ | ✅ | ✅ Built-in | ✅ | ⭐⭐⭐⭐⭐ |
| **Cloud Run** | ✅ | ✅ | ✅ | Externo | Cloud Scheduler | ⭐⭐⭐⭐ |
| **Fly.io** | ✅ | ✅ | ✅ | ✅ | Manual | ⭐⭐⭐ |
| **Render** | ✅ | ✅ | ✅ | ✅ Managed | ✅ | ⭐⭐⭐⭐ |
| **AWS ECS** | ✅ | ✅ | ✅ | RDS | EventBridge | ⭐⭐ |

---

## 7. Guía de Migración a Go

### 7.1 Estructura del Proyecto

```
civica-go/
├── cmd/server/main.go
├── internal/
│   ├── config/config.go
│   ├── middleware/{auth,tenant,roles,ratelimit}.go
│   ├── domain/{money,periodo,modalidad,estado_cobro,
│   │          cobro,pago,pago_edicion,tarifa,
│   │          monto_predefinido,plan_de_cobro,
│   │          periodo_cobro,solicitud,ticket,
│   │          ticket_cobro,residente}.go
│   ├── repository/{base,cobro_repo,pago_repo,tarifa_repo,
│   │              monto_repo,plan_cobro_repo,periodo_repo,
│   │              solicitud_repo,ticket_repo}.go
│   ├── service/{registrar_pago,eliminar_pago,corregir_pago,
│   │           validar_pago,generar_cobros,eliminar_cobro,
│   │           marcar_vencidas,generar_ticket,generar_reporte,
│   │           configurar_tarifa,actualizar_tarifa,
│   │           configurar_monto,tarifa_derivacion}.go
│   ├── handler/{cobros,pagos,tarifas,montos,planes_cobro,
│   │           solicitudes,dashboard,tickets,reportes}.go
│   ├── dto/DTOs.go
│   └── cron/{generar_cobros_job,marcar_vencidas_job}.go
├── migrations/001_ledger_schema.sql
├── Dockerfile
├── railway.json
├── go.mod
└── go.sum
```

### 7.2 Dependencias

```go
require (
    github.com/gin-gonic/gin v1.10+
    github.com/jmoiron/sqlx v1.3+
    github.com/jackc/pgx/v5 v5.7+
    github.com/golang-jwt/jwt/v5 v5.2+
    github.com/go-playground/validator/v10 v10.22+
    github.com/robfig/cron/v3 v3.0+
    github.com/spf13/viper v1.19+
    go.uber.org/zap v1.27+
)
```

### 7.3 Domain Layer — Money

```go
package domain

type Money struct {
    Amount   int    // centavos COP
    Currency string // "COP"
}

func NewMoney(amount int) Money {
    return Money{Amount: amount, Currency: "COP"}
}

func OfCOP(pesos int) Money {
    if pesos < 0 { panic("Money no puede ser negativo") }
    return Money{Amount: pesos, Currency: "COP"}
}

func (m Money) Add(other Money) Money {
    return Money{Amount: m.Amount + other.Amount, Currency: "COP"}
}

func (m Money) Subtract(other Money) (Money, error) {
    result := m.Amount - other.Amount
    if result < 0 {
        return Money{}, errors.New("saldo no puede ser negativo")
    }
    return Money{Amount: result, Currency: "COP"}, nil
}

func (m Money) IsZero() bool { return m.Amount == 0 }
```

### 7.4 Domain Layer — Cobro

```go
package domain

type EstadoCobro string

const (
    EstadoPENDIENTE EstadoCobro = "PENDIENTE"
    EstadoPARCIAL   EstadoCobro = "PARCIAL"
    EstadoPAGADA    EstadoCobro = "PAGADA"
    EstadoVENCIDA   EstadoCobro = "VENCIDA"
    EstadoANULADO   EstadoCobro = "ANULADO"
)

type Cobro struct {
    ID                string     `db:"id" json:"id"`
    ResidenteID       string     `db:"residente_id" json:"residenteId"`
    TenantID          string     `db:"tenant_id" json:"tenantId"`
    PeriodoID         *string    `db:"periodo_id" json:"periodoId"`
    CasaID            *string    `db:"casa_id" json:"casaId"`
    TarifaID          *string    `db:"tarifa_id" json:"tarifaId"`
    Concepto          string     `db:"concepto" json:"concepto"`
    Monto             int        `db:"monto" json:"monto"`
    MontoPagado       int        `db:"monto_pagado" json:"montoPagado"`
    PeriodoInicio     string     `db:"periodo_inicio" json:"periodoInicio"`
    PeriodoFin        string     `db:"periodo_fin" json:"periodoFin"`
    FechaVencimiento  string     `db:"fecha_vencimiento" json:"fechaVencimiento"`
    Estado            EstadoCobro `db:"estado" json:"estado"`
    NotificacionEnviada bool    `db:"notificacion_enviada" json:"notificacionEnviada"`
}

func (c *Cobro) Saldo() int { return c.Monto - c.MontoPagado }

func (c *Cobro) AplicarPago(montoPago int) (excedente int, err error) {
    if c.Estado == EstadoPAGADA {
        return 0, errors.New("no se puede pagar un cobro ya PAGADO")
    }
    if c.Estado == EstadoANULADO {
        return 0, errors.New("no se puede pagar un cobro en estado ANULADO")
    }
    saldo := c.Saldo()
    if montoPago >= saldo {
        excedente = montoPago - saldo
        c.MontoPagado += saldo
        c.Estado = EstadoPAGADA
        return excedente, nil
    }
    c.MontoPagado += montoPago
    c.Estado = EstadoPARCIAL
    return 0, nil
}

func (c *Cobro) MarcarVencida() {
    if c.Estado == EstadoPENDIENTE || c.Estado == EstadoPARCIAL {
        c.Estado = EstadoVENCIDA
    }
}
```

### 7.5 Repository — Cobro con Pessimistic Locking

```go
package repository

import (
    "database/sql"
    "github.com/jmoiron/sqlx"
    "civica-go/internal/domain"
)

type CobroRepository struct {
    DB *sqlx.DB
}

func (r *CobroRepository) FindMasAntiguoConSaldoLocked(
    tx *sqlx.Tx, residenteID string,
) (*domain.Cobro, error) {
    var cobro domain.Cobro
    err := tx.QueryRowx(
        `SELECT * FROM cobros 
         WHERE residente_id = $1 
           AND estado IN ('VENCIDA','PARCIAL','PENDIENTE')
         ORDER BY fecha_vencimiento ASC 
         FOR UPDATE`,
        residenteID,
    ).StructScan(&cobro)
    if err == sql.ErrNoRows {
        return nil, nil
    }
    return &cobro, err
}
```

### 7.6 Service — RegistrarPago

```go
package service

import "context"

type RegistrarPagoInput struct {
    ClientPaymentID string
    TenantID        string
    Monto           int
    FechaPago       string
    CobradorID      string
    ResidenteID     string
    SolicitudID     *string
}

func (s *Service) RegistrarPago(ctx context.Context, input RegistrarPagoInput) (*domain.Pago, []domain.Cobro, error) {
    // 1. Idempotency check
    existing, _ := s.pagoRepo.FindByIdempotentKey(input.TenantID, input.ClientPaymentID)
    if existing != nil {
        return existing, nil, nil
    }

    // 2. Validate plan activo
    plan, err := s.planRepo.FindByResidente(input.ResidenteID)
    if err != nil || plan == nil || !plan.Activa {
        return nil, nil, ErrNoActivePlan
    }

    // 3. Transaction con pessimistic locking
    tx, _ := s.db.Beginx()
    defer tx.Rollback()

    var cobrosAfectados []domain.Cobro
    remaining := input.Monto

    for remaining > 0 {
        cobro, _ := s.cobroRepo.FindMasAntiguoConSaldoLocked(tx, input.ResidenteID)
        if cobro == nil { break }

        excedente, _ := cobro.AplicarPago(remaining)
        tx.Exec("UPDATE cobros SET monto_pagado=$1, estado=$2 WHERE id=$3",
            cobro.MontoPagado, cobro.Estado, cobro.ID)
        cobrosAfectados = append(cobrosAfectados, *cobro)
        remaining = excedente
    }

    if len(cobrosAfectados) == 0 {
        return nil, nil, ErrNoPendingCobros
    }

    // 4. Create pago
    pago := domain.Pago.Crear(input.ClientPaymentID, input.TenantID,
        input.Monto, input.FechaPago, input.CobradorID,
        input.ResidenteID, &cobrosAfectados[0].ID)
    tx.Exec("INSERT INTO pagos ...", pago.Values()...)

    // 5. Commit
    tx.Commit()

    return &pago, cobrosAfectados, nil
}
```

### 7.7 Handler — Cobros

```go
package handler

import (
    "net/http"
    "github.com/gin-gonic/gin"
    "civica-go/internal/service"
)

type CobrosHandler struct {
    svc *service.Service
}

func (h *CobrosHandler) Listar(c *gin.Context) {
    tenantID := c.GetString("tenantId")
    etapaId := c.Query("etapaId")
    manzanaId := c.Query("manzanaId")
    status := c.Query("status")

    cobros, err := h.svc.ListarCobros(tenantID, etapaId, manzanaId, status)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, cobros)
}
```

### 7.8 Router Setup

```go
package handler

import (
    "github.com/gin-gonic/gin"
    "civica-go/internal/middleware"
)

func SetupRoutes(r *gin.Engine, deps *Deps) {
    api := r.Group("/api")
    api.Use(middleware.JWTAuth(deps.JWTSecret))
    api.Use(middleware.TenantExtractor())

    // Cobros
    cobros := api.Group("/cobros")
    cobros.GET("", deps.CobrosHandler.Listar)
    cobros.GET("/residente/:residenteId", deps.CobrosHandler.ListarPorResidente)
    cobros.DELETE("/:id", middleware.Roles("ADMIN"), deps.CobrosHandler.Eliminar)

    // Pagos
    pagos := api.Group("/pagos")
    pagos.POST("", middleware.Roles("ADMIN", "COBRADOR"), deps.PagosHandler.Registrar)
    pagos.DELETE("/:id", middleware.Roles("ADMIN"), deps.PagosHandler.Eliminar)
    pagos.PATCH("/:id/corregir", deps.PagosHandler.Corregir)
    pagos.PATCH("/:id/validar", middleware.Roles("ADMIN"), deps.PagosHandler.Validar)

    // Dashboard
    api.GET("/dashboard/administrador", deps.DashboardHandler.Admin)
    api.GET("/dashboard/cobrador", deps.DashboardHandler.Cobrador)
    api.GET("/dashboard/residente", deps.DashboardHandler.Residente)
}
```

### 7.9 Dockerfile

```dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/server ./cmd/server

FROM alpine:3.19
RUN apk --no-cache add ca-certificates tzdata
COPY --from=builder /app/server /app/server
COPY --from=builder /app/migrations /app/migrations
EXPOSE 3000
CMD ["/app/server"]
```

### 7.10 Timeline Estimado — Go

| Fase | Duración | Contenido |
|------|----------|-----------|
| FASE 0 | 1 día | Setup proyecto, go.mod, Dockerfile, railway.json |
| FASE 1 | 2-3 días | Domain: Money, Cobro, Pago, Tarifa, etc. |
| FASE 2 | 3-4 días | Repositories con sqlx |
| FASE 3 | 4-5 días | Services/Use cases críticos |
| FASE 4 | 3-4 días | HTTP Handlers + DTOs |
| FASE 5 | 1 día | Cron jobs + Config |
| FASE 6 | 1 día | Migraciones SQL |
| FASE 7 | 2-3 días | Tests unitarios |
| FASE 8 | 1-2 días | Integración Flutter |
| **TOTAL** | **~3-4 semanas** | |

---

## 8. Guía de Migración a Java Spring Boot

### 8.1 Estructura del Proyecto

```
civica-java/
├── src/main/java/com/civicapago/civica/
│   ├── CivicaApplication.java
│   ├── config/{SecurityConfig,CorsConfig,TenantInterceptor,RateLimitConfig}.java
│   ├── shared/
│   │   ├── valueobject/{Money,ModalidadRecaudo,EstadoCobro,Periodo}.java
│   │   ├── tenant/{TenantContext,TenantInterceptor,CurrentTenant}.java
│   │   └── auth/{JwtTokenProvider,JwtAuthFilter,Roles}.java
│   ├── ledger/
│   │   ├── domain/{Cobro,Pago,PagoEdicion,Tarifa,MontoPagoPredefinido,
│   │   │          PlanDeCobro,PeriodoCobro,Solicitud,Ticket,TicketCobro}.java
│   │   ├── repository/{CobroRepository,PagoRepository,TarifaRepository,
│   │   │               MontoPagoPredefinidoRepository,PlanDeCobroRepository,
│   │   │               PeriodoCobroRepository,SolicitudRepository,
│   │   │               TicketRepository}.java
│   │   ├── service/{RegistrarPagoService,EliminarPagoService,...}.java
│   │   ├── controller/{CobrosController,PagosController,...}.java
│   │   ├── dto/{RegistrarPagoRequest,CobroResponse,...}.java
│   │   └── job/{GenerarCobrosJob,MarcarVencidasJob}.java
│   └── community/domain/{Residente,Casa,Manzana,Etapa}.java
├── src/main/resources/
│   ├── application.yml
│   └── db/migration/V1__ledger_schema.sql
├── src/test/java/...
├── Dockerfile
├── railway.json
└── pom.xml
```

### 8.2 Dependencias (pom.xml)

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.3.3</version>
</parent>

<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    <dependency>
        <groupId>org.postgresql</groupId>
        <artifactId>postgresql</artifactId>
        <scope>runtime</scope>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-security</artifactId>
    </dependency>
    <dependency>
        <groupId>io.jsonwebtoken</groupId>
        <artifactId>jjwt-api</artifactId>
        <version>0.12.6</version>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
    <dependency>
        <groupId>org.flywaydb</groupId>
        <artifactId>flyway-core</artifactId>
    </dependency>
    <dependency>
        <groupId>org.flywaydb</groupId>
        <artifactId>flyway-database-postgresql</artifactId>
    </dependency>
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <optional>true</optional>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

### 8.3 application.yml

```yaml
spring:
  datasource:
    url: jdbc:postgresql://${DB_HOST:localhost}:${DB_PORT:5432}/${DB_NAME:civica}
    username: ${DB_USER:postgres}
    password: ${DB_PASS:postgres}
    hikari:
      maximum-pool-size: 20
  jpa:
    hibernate:
      ddl-auto: validate
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect
  flyway:
    enabled: true
    locations: classpath:db/migration

server:
  port: ${PORT:3000}
  servlet:
    context-path: /api

app:
  jwt:
    secret: ${JWT_SECRET:your-secret-key}
    expiration: 3600000
```

### 8.4 Domain — Money

```java
package com.civicapago.civica.shared.valueobject;

public final class Money {
    private final int amount; // centavos COP

    public Money(int amount) { this.amount = amount; }

    public static Money ofCOP(int pesos) {
        if (pesos < 0) throw new IllegalArgumentException("Money no puede ser negativo");
        return new Money(pesos);
    }

    public Money add(Money other) {
        return new Money(this.amount + other.amount);
    }

    public Money subtract(Money other) {
        int result = this.amount - other.amount;
        if (result < 0) throw new ArithmeticException("Saldo no puede ser negativo");
        return new Money(result);
    }

    public int getAmount() { return amount; }
    public boolean isZero() { return amount == 0; }
}
```

### 8.5 Entity — Cobro

```java
package com.civicapago.civica.ledger.domain;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "cobros")
public class Cobro {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @Column(name = "residente_id", nullable = false)
    private String residenteId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "residente_id", insertable = false, updatable = false)
    private Residente residente;

    @Column(name = "tenant_id", nullable = false)
    private String tenantId;

    @Column(nullable = false)
    private int monto;

    @Column(name = "monto_pagado", nullable = false)
    private int montoPagado = 0;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private EstadoCobro estado = EstadoCobro.PENDIENTE;

    // ... otros campos

    public int getSaldo() { return monto - montoPagado; }

    public int aplicarPago(int montoPago) {
        if (this.estado == EstadoCobro.PAGADA)
            throw new IllegalStateException("No se puede pagar un cobro ya PAGADO");
        if (this.estado == EstadoCobro.ANULADO)
            throw new IllegalStateException("No se puede pagar un cobro en estado ANULADO");

        int saldo = getSaldo();
        if (montoPago >= saldo) {
            int excedente = montoPago - saldo;
            this.montoPagado += saldo;
            this.estado = EstadoCobro.PAGADA;
            return excedente;
        }
        this.montoPagado += montoPago;
        this.estado = EstadoCobro.PARCIAL;
        return 0;
    }

    public void marcarVencida() {
        if (this.estado == EstadoCobro.PENDIENTE || this.estado == EstadoCobro.PARCIAL)
            this.estado = EstadoCobro.VENCIDA;
    }
}
```

### 8.6 Repository — CobroRepository

```java
package com.civicapago.civica.ledger.repository;

import com.civicapago.civica.ledger.domain.Cobro;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CobroRepository extends JpaRepository<Cobro, String> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT c FROM Cobro c WHERE c.residenteId = :residenteId " +
           "AND c.estado IN ('VENCIDA', 'PARCIAL', 'PENDIENTE') " +
           "ORDER BY c.fechaVencimiento ASC FETCH FIRST 1 ROW ONLY")
    Optional<Cobro> findMasAntiguoConSaldoLocked(
        @Param("residenteId") String residenteId);

    List<Cobro> findByResidenteIdOrderByPeriodoInicioDesc(String residenteId);

    @Query("SELECT c FROM Cobro c WHERE c.estado = 'PENDIENTE' " +
           "AND c.fechaVencimiento < CURRENT_DATE")
    List<Cobro> findVencidas();
}
```

### 8.7 Service — RegistrarPagoService

```java
package com.civicapago.civica.ledger.service;

import com.civicapago.civica.ledger.domain.*;
import com.civicapago.civica.ledger.repository.*;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Service;
import java.util.ArrayList;
import java.util.List;

@Service
public class RegistrarPagoService {

    private final PagoRepository pagoRepo;
    private final CobroRepository cobroRepo;
    private final PlanDeCobroRepository planRepo;

    public RegistrarPagoService(PagoRepository pagoRepo, CobroRepository cobroRepo,
                                 PlanDeCobroRepository planRepo) {
        this.pagoRepo = pagoRepo;
        this.cobroRepo = cobroRepo;
        this.planRepo = planRepo;
    }

    @Transactional
    public RegistrarPagoResult execute(RegistrarPagoInput input) {
        // 1. Idempotency check
        var existing = pagoRepo.findByTenantIdAndClientPaymentId(
            input.tenantId(), input.clientPaymentId());
        if (existing.isPresent()) {
            return new RegistrarPagoResult(existing.get(), List.of());
        }

        // 2. Validate plan activo
        var plan = planRepo.findByResidenteIdAndActivaTrue(input.residenteId());
        if (plan.isEmpty()) throw new BadRequestException("No hay plan activo");

        // 3. FIFO Distribution con pessimistic locking
        int remaining = input.monto();
        var cobrosAfectados = new ArrayList<Cobro>();

        while (remaining > 0) {
            var cobroOpt = cobroRepo.findMasAntiguoConSaldoLocked(input.residenteId());
            if (cobroOpt.isEmpty()) break;

            var cobro = cobroOpt.get();
            int excedente = cobro.aplicarPago(remaining);
            cobroRepo.save(cobro);
            cobrosAfectados.add(cobro);
            remaining = excedente;
        }

        if (cobrosAfectados.isEmpty())
            throw new BadRequestException("No hay cobros pendientes");

        // 4. Create Pago
        var pago = Pago.crear(input.clientPaymentId(), input.tenantId(),
            input.monto(), input.fechaPago(), input.cobradorId(),
            input.residenteId(), cobrosAfectados.get(0).getId());
        pagoRepo.save(pago);

        return new RegistrarPagoResult(pago, cobrosAfectados);
    }
}
```

### 8.8 Controller — CobrosController

```java
package com.civicapago.civica.ledger.controller;

import com.civicapago.civica.ledger.dto.*;
import com.civicapago.civica.ledger.service.*;
import com.civicapago.civica.shared.tenant.TenantContext;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/cobros")
@PreAuthorize("isAuthenticated()")
public class CobrosController {

    private final CobroRepository cobroRepo;
    private final EliminarCobroService eliminarCobroService;

    public CobrosController(CobroRepository cobroRepo,
                            EliminarCobroService eliminarCobroService) {
        this.cobroRepo = cobroRepo;
        this.eliminarCobroService = eliminarCobroService;
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'COBRADOR')")
    public ResponseEntity<List<CobroResponse>> listar(
            @RequestParam(required = false) String etapaId,
            @RequestParam(required = false) String manzanaId,
            @RequestParam(required = false) String status) {
        String tenantId = TenantContext.getTenantId();
        var cobros = cobroRepo.findByTenantIdWithFilters(tenantId, etapaId, manzanaId, status);
        return ResponseEntity.ok(cobros.stream().map(this::mapCobroItem).toList());
    }

    @GetMapping("/residente/{residenteId}")
    @PreAuthorize("hasAnyRole('ADMIN', 'COBRADOR', 'RESIDENTE')")
    public ResponseEntity<List<CobroResponse>> listarPorResidente(
            @PathVariable String residenteId) {
        var cobros = cobroRepo.findByResidenteIdOrderByPeriodoInicioDesc(residenteId);
        return ResponseEntity.ok(cobros.stream().map(this::mapCobroItem).toList());
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> eliminar(@PathVariable String id) {
        eliminarCobroService.execute(id);
        return ResponseEntity.ok().build();
    }

    private CobroResponse mapCobroItem(Cobro cobro) {
        // Mapeo idéntico al NestJS mapCobroItem
        return new CobroResponse(cobro.getId(),
            cobro.getResidente() != null ? cobro.getResidente().getNombre() : "Residente",
            cobro.getCasa() != null ? cobro.getCasa().getDireccionInterna() : "Inmueble",
            cobro.getMonto(), cobro.getMontoPagado(), cobro.getEstado().name(),
            cobro.getFechaVencimiento().toString());
    }
}
```

### 8.9 Security Config

```java
package com.civicapago.civica.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;

    public SecurityConfig(JwtAuthFilter jwtAuthFilter) {
        this.jwtAuthFilter = jwtAuthFilter;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .cors(cors -> {})
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/health").permitAll()
                .requestMatchers("/api/auth/**").permitAll()
                .anyRequest().authenticated()
            )
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
```

### 8.10 Dockerfile

```dockerfile
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /app
COPY . .
RUN ./mvnw clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine
RUN apk --no-cache add tzdata
COPY --from=builder /app/target/*.jar /app/civica.jar
EXPOSE 3000
ENTRYPOINT ["java", "-jar", "/app/civica.jar"]
```

### 8.11 Timeline Estimado — Java

| Fase | Duración | Contenido |
|------|----------|-----------|
| FASE 0 | 1-2 días | Setup Spring Boot, pom.xml, Dockerfile |
| FASE 1 | 3-4 días | Domain + JPA Entities |
| FASE 2 | 2-3 días | Spring Data Repositories |
| FASE 3 | 5-6 días | Services/Use cases |
| FASE 4 | 3-4 días | Controllers + DTOs |
| FASE 5 | 2-3 días | Security + Tenant |
| FASE 6 | 1 día | Flyway migrations |
| FASE 7 | 3-4 días | Tests |
| FASE 8 | 1-2 días | Integración Flutter |
| **TOTAL** | **~4-5 semanas** | |

---

## 9. Checklist de Decisión

Antes de elegir, responte estas preguntas:

### Sobre tu experiencia:
- [ ] ¿Tienes experiencia con Go? → Si → Go
- [ ] ¿Tienes experiencia con Java/Spring? → Si → Java
- [ ] ¿Conoces bien patrones DDD? → Si → Cualquiera funciona
- [ ] ¿Prefieres menos boilerplate? → Si → Go
- [ ] ¿Prefieres más "batteries included"? → Si → Java

### Sobre el proyecto:
- [ ] ¿Necesitas deploy rápido? → Si → Go + Railway
- [ ] ¿El costo cloud es prioridad? → Si → Go
- [ ] ¿Necesitas empleabilidad LATAM? → Si → Java
- [ ] ¿La app crecerá mucho? → Si → Java (enterprise patterns)
- [ ] ¿Es un proyecto personal/learning? → Si → Go

### Sobre infraestructura:
- [ ] ¿Ya tienes cuenta en Railway? → Si → Railway
- [ ] ¿Prefieres serverless? → Si → Cloud Run + Go
- [ ] ¿Necesitas multi-región? → Si → Fly.io

---

## 📊 Resumen Visual

```
                    ┌─────────────────────────────────────┐
                    │     CIVICA PAGO — DECISIÓN          │
                    └─────────────────┬───────────────────┘
                                      │
                    ┌─────────────────┴───────────────────┐
                    │                                     │
              ┌─────▼─────┐                        ┌──────▼──────┐
              │  🐹 GO    │                        │ ☕ JAVA     │
              │           │                        │ SPRING BOOT │
              └─────┬─────┘                        └──────┬──────┘
                    │                                     │
              ┌─────▼─────┐                        ┌──────▼──────┐
              │ $15-20/mes│                        │ $35-50/mes  │
              │ 3-4 sem   │                        │ 4-5 sem     │
              │ ~15MB     │                        │ ~200MB      │
              │ <50ms cold│                        │ 5-30s cold  │
              └─────┬─────┘                        └──────┬──────┘
                    │                                     │
              ┌─────▼─────┐                        ┌──────▼──────┐
              │ Railway   │                        │ Railway     │
              │ Cloud Run │                        │ AWS ECS     │
              │ Fly.io    │                        │ Cloud Run   │
              └───────────┘                        └─────────────┘
```

---

> **Nota:** Este documento fue generado el 29 de Agosto de 2026 como parte del análisis de migración del backend NestJS de Civica Pago.
>
> **Recomendación personal:** Para tu caso específico (experiencia personal, costo importa, app no enterprise), **Go + Railway** es la opción más eficiente. Si la empleabilidad es prioridad, **Java + Railway** es más seguro.
