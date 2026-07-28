# Cívica Pago

![CI](https://github.com/USER/REPO/actions/workflows/ci.yml/badge.svg)
![Coverage](https://img.shields.io/badge/coverage-49%25-yellow)
![NestJS](https://img.shields.io/badge/backend-NestJS-e0234e)
![Flutter](https://img.shields.io/badge/mobile-Flutter-02569B)

> Plataforma inteligente para la gestión del recaudo de comunidades residenciales.
> Mobile-first, offline-ready, multi-tenant.

---

## Stack

| Capa | Tecnología |
|---|---|
| **Backend** | NestJS 11 + TypeORM + PostgreSQL |
| **Móvil** | Flutter 3.x + BLoC + GoRouter + SQLite |
| **DB Cloud** | Supabase (PostgreSQL + RLS) |
| **Offline** | SQLite local + sync FIFO con idempotencia |

## Arquitectura

```
┌─────────────┐     ┌─────────────────────┐     ┌──────────────┐
│  Flutter App │ ──> │  NestJS API (REST)  │ ──> │  PostgreSQL  │
│  (Android)   │     │                     │     │  (Supabase)  │
│  +SQLite     │     │  ┌─────────────────┐│     │              │
│  offline     │     │  │   Bounded Ctxs  ││     │  Multi-      │
└─────────────┘     │  │  - Community     ││     │  tenant      │
                    │  │  - IAM           ││     │  (RLS)       │
                    │  │  - Ledger        ││     │              │
                    │  │  - Notifications ││     └──────────────┘
                    │  └─────────────────┘│
                    └─────────────────────┘
```

## Tests

| Suite | Tests | Estado |
|---|---|---|
| **Backend Unit** | 253 | ✅ 100% passing |
| **Backend e2e** | 7 spec files | ✅ |
| **Mobile Unit** | 2 spec files | ✅ |
| **Mobile Widget** | 6 spec files | ✅ |

```bash
# Backend
cd apps/backend && npm test          # 253 tests
cd apps/backend && npm run test:cov   # coverage

# Mobile
cd apps/mobile && flutter test        # all mobile tests
```

## Coverage (49%)

| Módulo | Cobertura |
|---|---|
| `src/shared/auth` | 82% |
| `src/ledger/domain` | 76% |
| `src/ledger/jobs` | 100% |
| `src/iam/use-cases` | 100% |
| `src/community/controllers` | 62% |
| `src/ledger/use-cases` | 52% |

## Roles

| Rol | Acceso |
|---|---|
| **Admin** | Configura tarifas, usuarios, reportes, dashboard global |
| **Cobrador** | Registra pagos offline, ve sus etapas asignadas |
| **Residente** | Consulta su cartera, solicita revisiones |

## Desarrollo Local

```bash
# Backend
cd apps/backend
cp .env.example .env     # configurar BD
npm install
npm run start:dev

# Mobile
cd apps/mobile
flutter pub get
flutter run
```

## Documentación

Toda la documentación técnica está en [`doc/`](./doc/):

- [Visión del Producto](./doc/01-vision.md)
- [Arquitectura](./doc/05-arquitectura.md)
- [Modelo de Dominio](./doc/06-modelo-dominio.md)
- [Decisiones (ADRs)](./doc/11-adrs.md)
- [Plan de Desarrollo](./doc/13-plan-desarrollo.md)

---

> Reemplaza `USER/REPO` en el badge de CI con la URL real de tu repositorio de GitHub.
