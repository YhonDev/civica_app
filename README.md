# Cívica Pago

Plataforma mobile-first para gestionar el recaudo, la cartera y las operaciones de comunidades residenciales. El sistema combina una API REST en NestJS con una aplicación Flutter que puede registrar pagos sin conexión y sincronizarlos posteriormente.

> **Estado:** código en evolución / entorno de desarrollo. Este README describe la implementación observada en el repositorio; no implica disponibilidad productiva ni certificación de seguridad.

## Índice

- [Capacidades](#capacidades)
- [Arquitectura](#arquitectura)
- [Stack](#stack)
- [Estructura del repositorio](#estructura-del-repositorio)
- [Requisitos](#requisitos)
- [Configuración segura](#configuración-segura)
- [Puesta en marcha](#puesta-en-marcha)
- [API y flujo de pagos](#api-y-flujo-de-pagos)
- [Pruebas y CI](#pruebas-y-ci)
- [Documentación](#documentación)
- [Limitaciones y deuda técnica](#limitaciones-y-deuda-técnica)
- [Contribución](#contribución)

## Capacidades

| Rol | Capacidades implementadas en la aplicación |
|---|---|
| **Administrador** | Gestionar usuarios, proyectos, etapas, residentes, tarifas, montos, cartera, reportes, dashboard y notificaciones. |
| **Cobrador** | Consultar etapas asignadas, recorrer casas, registrar pagos y trabajar con una cola offline de sincronización. |
| **Residente** | Consultar cartera e historial, revisar información de su unidad y crear o consultar solicitudes disponibles para su rol. |

La API expone además operaciones para cobros, pagos, tickets, reportes, dashboard, solicitudes, autenticación y health checks. Algunas pantallas y acciones todavía son placeholders o requieren validación funcional adicional.

## Arquitectura

```text
┌──────────────────────┐       HTTP/JSON        ┌────────────────────────┐
│ Flutter (Android...) │ ─────────────────────> │ NestJS API              │
│ BLoC + GoRouter      │                        │ /api                    │
│ Drift / SQLite       │ <───────────────────── │ JWT + roles + tenant    │
│ Cola offline         │       sincronización   │ Swagger /docs           │
└──────────────────────┘                        └───────────┬────────────┘
                                                            │ TypeORM
                                                            ▼
                                                 ┌────────────────────────┐
                                                 │ PostgreSQL / Supabase   │
                                                 └────────────────────────┘
```

### Backend

El backend está organizado por contextos y módulos de dominio:

- `community`: proyectos, etapas, manzanas, casas y residentes.
- `iam`: usuarios, autenticación y asignaciones.
- `ledger`: tarifas, planes, periodos, cobros, pagos, tickets y reportes.
- `notifications`: actividades, notificaciones y eventos.
- `shared`: autenticación JWT, tenant, health checks, configuración y componentes comunes.

El arranque configura el prefijo global `/api`, Swagger en `/docs` fuera de producción —o cuando `ENABLE_SWAGGER=true`—, Helmet, CORS, validación global, serialización, rate limiting y apagado controlado. Véase `apps/backend/src/main.ts` y `apps/backend/src/app.module.ts`.

### Aplicación móvil

`apps/mobile/lib/main.dart` inicializa la base local Drift, carga variables de entorno, configura el cliente HTTP, detecta conectividad y arranca `SyncService`. El router dirige al dashboard según el rol (`ADMIN`, `COBRADOR` o `RESIDENTE`).

Cuando se recupera la conectividad, `SyncService` envía los pagos pendientes individualmente a `POST /api/pagos` y distingue estados de éxito, sincronización parcial, error de red y conflicto. No se debe asumir que existe un endpoint batch `/pagos/sync`: el flujo actual no lo utiliza.

## Stack

| Capa | Tecnología | Referencia |
|---|---|---|
| Backend | NestJS 11, TypeScript, TypeORM, PostgreSQL (`pg`) | `apps/backend/package.json` |
| Autenticación | JWT, Passport, bcrypt, almacenamiento de sesiones | Backend `shared/auth` e `iam` |
| API | REST, Swagger/OpenAPI, Socket.IO | `apps/backend/src/main.ts` |
| Seguridad HTTP | Helmet, CORS, `@nestjs/throttler` | `apps/backend/src/main.ts` y `app.module.ts` |
| Móvil | Flutter, Dart SDK `^3.12.2`, BLoC, GoRouter | `apps/mobile/pubspec.yaml` |
| Persistencia local | Drift sobre SQLite | `apps/mobile/lib/core/database` |
| Red y offline | Dio, `connectivity_plus`, cola de sincronización | `apps/mobile/lib/core/network` y `core/sync` |
| Servicios adicionales | Redis/ioredis, Firebase Admin, Socket.IO | Dependencias del backend |

## Estructura del repositorio

```text
.
├── apps/
│   ├── backend/              # API NestJS, dominio, persistencia y tests
│   └── mobile/               # Aplicación Flutter, UI, SQLite y sync offline
├── database/                 # Dentro de backend: schema y scripts SQL
├── docs/                     # Arquitectura, dominio, UX, despliegue y diagramas
├── openspec/                 # Especificaciones y cambios documentados
├── .github/workflows/ci.yml  # Pipeline de calidad
├── mise.toml                 # Herramientas locales opcionales
└── README.md
```

Los directorios `build/`, `dist/`, `.dart_tool/`, `node_modules/`, `.idea/`, `.codegraph/` y otros artefactos locales son generados o ignorados; no forman parte del código fuente que debe revisarse o versionarse.

## Requisitos

- Node.js compatible con el proyecto; CI usa Node.js 22.
- npm.
- Flutter estable y Dart SDK compatible con `apps/mobile/pubspec.yaml`.
- PostgreSQL local o una instancia compatible de Supabase.
- Docker es opcional para el apoyo de comprobación de base de datos local de los scripts `ensure-db.js`.
- Variables mínimas del backend: `DATABASE_PASSWORD` y `JWT_SECRET`.

El entorno actual no versiona las dependencias instaladas ni los archivos `.env`. La versión exacta de cada paquete se define en `package-lock.json` del backend y en `pubspec.yaml` del móvil; `pubspec.lock` está excluido por la configuración actual del repositorio.

## Configuración segura

Nunca copies credenciales reales en el repositorio, README, issues, logs o capturas de pantalla.

### Escaneo de secretos en commits (gitleaks)

El repositorio incluye un hook `pre-commit` que bloquea cualquier commit que contenga secretos detectados (claves de API, tokens, contraseñas, connection strings). Para activarlo en tu clon local:

```bash
git config core.hooksPath .githooks
mise install   # instala gitleaks junto con el resto de herramientas de mise.toml
```

Sin gitleaks instalado el hook **falla cerrado** (rechaza el commit) para no permitir saltos de seguridad accidentales. Las reglas viven en `.gitleaks.toml`; los falsos positivos verificados se listan ahí como excepciones acotadas por ruta — nunca agregues secretos reales a esa lista. Para auditar toda la historia:

```bash
gitleaks detect --source . -c .gitleaks.toml
```

### Backend

```bash
cd apps/backend
cp .env.example .env
```

Configura al menos la conexión PostgreSQL, `DATABASE_PASSWORD`, `JWT_SECRET`, `NODE_ENV` y `PORT`. El código de arranque escucha `PORT` y usa `3000` como valor predeterminado. `APP_PORT` aparece en el ejemplo de entorno y no debe sustituir a `PORT` sin comprobar el comportamiento del entorno local.

La configuración de TypeORM mantiene `synchronize=false`. Revisa el esquema y las migraciones/scripts SQL antes de usar datos reales.

### Móvil

```bash
cd apps/mobile
cp .env.example .env
```

La URL de la API puede definirse de forma explícita:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

En Android, el valor de desarrollo predeterminado apunta a `127.0.0.1:3000/api` y normalmente requiere `adb reverse`. Para una compilación de producción debe configurarse una URL HTTPS explícita; no se debe reutilizar el fallback HTTP local.

## Puesta en marcha

### Backend

```bash
cd apps/backend
npm ci
npm run start:dev
```

Otros scripts disponibles en `apps/backend/package.json` incluyen `build`, `start`, `start:debug`, `start:prod`, `lint`, `format`, `test`, `test:watch`, `test:cov`, `test:e2e` y `seed`. Los comandos de arranque ejecutan previamente `ensure-db.js` y `ensure-port.js`; comprueba que Docker, la base de datos y las variables estén disponibles en tu entorno.

El seed es operativo para datos de desarrollo y no debe ejecutarse sobre una base de datos compartida sin revisar antes `apps/backend/src/seed-completo.ts` y los scripts de `apps/backend/database/scripts`.

### Móvil

```bash
cd apps/mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

La ejecución requiere tener instalado Flutter; este entorno de desarrollo no garantiza que el SDK esté disponible en todas las máquinas.

## API y flujo de pagos

- Prefijo base: `/api`.
- Documentación interactiva: `/docs` cuando Swagger está habilitado.
- Autenticación: Bearer JWT obtenido mediante el flujo de autenticación.
- Registro de pago: `POST /api/pagos`.
- Los montos del backend se manejan como enteros en centavos de COP.
- El pago se distribuye FIFO entre cobros y usa una clave de cliente para idempotencia.
- El cliente móvil online genera actualmente `clientPaymentId` desde el tiempo en milisegundos; el flujo offline utiliza UUID. Esta diferencia debe unificarse antes de depender de la idempotencia bajo concurrencia.

## Pruebas y CI

### Comandos de Verificación Local

```bash
# Backend (Pruebas unitarias completas)
cd apps/backend
npm test

# Backend (Pruebas de cobertura)
npm run test:cov

# Backend (Pruebas E2E y Smoke Test contra base de datos)
npm run test:e2e
npm run test:smoke

# Móvil (Análisis estático y pruebas de widgets)
cd apps/mobile
flutter analyze
flutter test
```

### Pipeline de Integración Continua (GitHub Actions)

El archivo [.github/workflows/ci.yml](.github/workflows/ci.yml) se ejecuta automáticamente en cada `push` y `pull_request` sobre `main` y `dev`:
1. **Backend**:
   * Levanta un contenedor Postgres 16 en el runner de CI.
   * Aplica [schema.sql](apps/backend/database/schema.sql) y migraciones incrementales.
   * Ejecuta chequeo TypeScript (`tsc --noEmit`) y pruebas unitarias con Jest.
   * Ejecuta pruebas E2E y levanta el servidor compilado (`dist/main.js`).
   * Ejecuta el *smoke test* contra el servidor vivo y reporta logs en caso de fallo.
2. **Móvil / Desktop**:
   * Inicializa el SDK de Flutter (`stable`).
   * Valida sintaxis con `flutter analyze` y ejecuta la suite de tests de widgets.
3. **Automatizaciones Operativas**:
   * [.github/workflows/wake-up-cron.yml](.github/workflows/wake-up-cron.yml): Despertador automático diario a las 00:00 COT para calentar la instancia de Render antes de los cron jobs nocturnos.
   * [.github/workflows/build-windows.yml](.github/workflows/build-windows.yml): Compilación nativa de Windows x64 en runner `windows-latest` y empaquetado en `.zip`.

---

## Guía Maestra de Ingeniería y Estándar de Contribución

Para garantizar la estabilidad en producción y la trazabilidad del código, todo el equipo y agentes automatizados siguen rigurosamente este protocolo:

### 1. Flujo Oficial de Ramas y Pull Requests (Gitflow Profesional)

```mermaid
graph LR
    subgraph Ciclo de Desarrollo
        DEV_LOCAL[dev Local] -->|git checkout -b| FEAT_BRANCH[feature/nueva-cosa]
        FEAT_BRANCH -->|Commit & Test Local| FEAT_LOCAL[Probado en Local]
        FEAT_LOCAL -->|git push origin| FEAT_REMOTE[origin/feature/nueva-cosa]
        FEAT_REMOTE -->|Crear PR| PR_DEV[Pull Request a origin/dev]
        PR_DEV -->|Revisión & Aprobación Manual| DEV_REMOTE[origin/dev]
    end

    subgraph Corte de Versión
        DEV_REMOTE -->|Acumular 5-10 features| PR_MAIN[Pull Request a origin/main]
        PR_MAIN -->|Merge & Tag v1.x.x| MAIN_REMOTE[origin/main Producción]
        MAIN_REMOTE -->|Auto-deploy| RENDER[Render Cloud API]
    end
```

> [!IMPORTANT]
> **Cero Pushes Directos a Producción ni a Desarrollo Remoto**:
> Está prohibido hacer `git push origin main` o `git push origin dev` de forma directa. Todo cambio viaja a través de ramas temporales y Pull Requests revisados y aprobados manualmente.

#### Protocolo Paso a Paso para Nuevas Funcionalidades o Fixes:

```bash
# 1. Asegurar que la rama base 'dev' local esté al día
git checkout dev
git pull origin dev

# 2. Crear rama temporal de trabajo (usar prefijo feature/ o fix/)
git checkout -b feature/nombre-descriptivo
# o para corrección de bugs:
git checkout -b fix/nombre-del-bug

# 3. Desarrollar, implementar y validar localmente
npm test              # en apps/backend
flutter test          # en apps/mobile

# 4. Crear commit semántico y subir rama
git add .
git commit -m "feat(modulo): descripción concisa del cambio"
git push -u origin feature/nombre-descriptivo

# 5. Abrir Pull Request hacia dev usando GitHub CLI
gh pr create \
  --base dev \
  --head feature/nombre-descriptivo \
  --title "feat: Titulo claro de la funcionalidad" \
  --body "### Resumen de cambios\n- Detalle 1\n- Detalle 2\n\n### Verificación realizada\n- Tests locales aprobados."

# 6. Una vez revisado y aprobado el PR en GitHub:
git checkout dev
git pull origin dev
git branch -d feature/nombre-descriptivo  # Limpiar rama local
```

### 2. Estándar de Commits Semánticos (Conventional Commits)

Cada commit debe incluir un prefijo identificador claro:
- `feat:` Nuevas funcionalidades para el usuario o API.
- `fix:` Corrección de errores o anomalías de negocio.
- `security:` Endurecimiento de seguridad, tokens, hashing, sanitización o RLS.
- `perf:` Mejoras de rendimiento o consultas optimizadas.
- `docs:` Cambios o añadidos en documentación técnica.
- `test:` Inclusión o ajuste de suites de prueba.
- `chore:` Tareas de mantenimiento, dependencias o configuración interna.

### 3. Política de Versiones (SemVer) y Despliegue

- **Backend (Render Cloud)**: Despliegue continuo activado en la rama `main`. Cada fusión aprobada a `main` desencadena automáticamente la compilación y puesta en producción en `https://cuentiva.onrender.com/api`.
- **Clientes Móvil y Desktop (APK / ZIP)**:
  - Se acumulan entre **5 y 10 features / mejoras** probadas en `dev` antes de realizar un corte de versión oficial.
  - Esto evita saturar a los usuarios y administradores con actualizaciones continuas por cambios cosméticos.
  - Al cortar versión, se genera un tag de release (ej. `v1.1.0`), se compila el APK y se dispara el workflow `build-windows.yml` para publicar los instaladores simultáneamente en el repositorio oficial de descargas.

---

## Comandos Operativos Cloud

### Conexión a la Base de Datos Cloud (Supabase Pooler)
```bash
# Conexión directa mediante psql con SSL
psql "postgresql://postgres.fpgukukujxfrlvynpyha:6eq7I3m4RFH6ft@aws-1-us-east-2.pooler.supabase.com:5432/postgres?sslmode=require"
```

### Disparo Manual de Generación de Cobros en Nube
```bash
# Invocación autenticada al endpoint de producción (solo rol ADMIN)
curl -X POST https://cuentiva.onrender.com/api/cobros/generar \
  -H "Authorization: Bearer <TOKEN_ADMIN_JWT>" \
  -H "Content-Type: application/json"
```

### Monitoreo del Cron Despertador Nocturno
```bash
# Inspeccionar ejecuciones del workflow despertador
gh workflow view wake-up-cron.yml --web
# o dispararlo manualmente para probar calentamiento
gh workflow run wake-up-cron.yml
```

### Compilación y Publicación de Windows Desktop
```bash
# Disparar compilación remota de Windows x64 en GitHub Actions
gh workflow run build-windows.yml -f release_tag=v1.0.0 -f upload_to_release=true
```

