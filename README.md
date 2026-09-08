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

### Comandos locales

```bash
# Backend
cd apps/backend
npm test
npm run test:cov
npm run test:e2e

# Móvil
cd apps/mobile
flutter analyze
flutter test
```

El repositorio contiene pruebas unitarias, de integración/e2e y widget, pero este README no fija cifras de tests ni cobertura: deben obtenerse de una ejecución reproducible del entorno y no de documentación histórica.

### Pipeline actual

`.github/workflows/ci.yml` se ejecuta para `main` y `master` y realiza:

1. Backend con Node.js 22: `npm ci`, `npx tsc --noEmit`, `npm test` y `npm run test:cov`.
2. Móvil con Flutter estable: `flutter pub get`, `flutter analyze` y `flutter test --no-coverage`.
3. Publicación del artefacto de coverage del backend durante 14 días.

El workflow actual no ejecuta `npm run test:e2e`, build de producción, migraciones, smoke tests de arranque o pruebas de endpoints protegidos.

## Documentación

La documentación técnica vigente está en [`docs/`](./docs/):

- [Índice de documentación](./docs/README.md)
- [Arquitectura](./docs/05-arquitectura.md)
- [Modelo de dominio](./docs/06-modelo-dominio.md)
- [Estrategias offline y multi-tenant](./docs/09-estrategias.md)
- [Despliegue](./docs/10-despliegue.md)
- [Decisiones de arquitectura](./docs/11-adrs.md)
- [Trazabilidad](./docs/12-trazabilidad.md)
- [UI por rol](./docs/14-ui-por-rol.md)
- [Especificaciones de pantallas](./docs/20-screen-specifications.md)
- [Biblioteca de componentes](./docs/21-component-library.md)

Algunos documentos y scripts conservan nomenclatura o decisiones de etapas anteriores del proyecto. Contrasta siempre la documentación con el código actual antes de ejecutar SQL o diseñar una integración.

## Limitaciones y deuda técnica conocida

### Seguridad — prioridad crítica

- El aislamiento multi-tenant no es uniforme. Hay repositorios, consultas y endpoints de proyectos, residentes, tarifas, montos, cobros, tickets, solicitudes, asignaciones y reportes que no reciben o aplican `tenantId` de forma consistente.
- El esquema SQL declara RLS, pero las políticas observadas son de servicio y no implementan por sí solas un contexto tenant-aware para las consultas TypeORM. No debe asumirse que RLS compensa los filtros de aplicación faltantes.
- Deben revisarse IDOR, validaciones de recursos anidados, cambio de contraseña y revocación de sesiones, acceso al health check y exposición de tokens en logs.
- La base local SQLite almacena información operativa offline sin cifrado de base de datos observado.
- Las credenciales demo de la UI y las credenciales embebidas en scripts legacy deben retirarse o aislarse de cualquier build no demo. Si algún secreto fue compartido, debe revocarse y rotarse.

### Rendimiento y consistencia

- Algunos dashboards, timelines y reportes cargan conjuntos grandes y filtran/agregan en memoria, sin paginación o agregación SQL suficiente.
- La generación de cobros se invoca desde una ruta de dashboard y puede realizar trabajo global; debería trasladarse a un job controlado y tener restricciones únicas contra duplicados concurrentes.
- La numeración de tickets usa una estrategia susceptible a carreras (`MAX + 1`) bajo pagos concurrentes.
- El pago y la generación del ticket no están completamente ligados a la misma transacción.

### UI/UX y mantenimiento

- Hay pantallas placeholder, acciones sin callback, rutas duplicadas y estados de error que terminan mostrando un estado vacío indistinguible de una respuesta sin datos.
- Deben validarse accesibilidad, contraste, escalado de texto, overflow en pantallas pequeñas y navegación Android back.
- Existen componentes candidatos a retirar o integrar —por ejemplo, sistemas duplicados de quick actions/charts— y DAOs legacy sin referencias aparentes. No deben eliminarse sin confirmar ownership y ejecutar análisis/tests.
- Los scripts `inspect-propietarios.js`, `clean-propietarios.js` y parte de los wrappers de propietarios conservan nomenclatura legacy; deben archivarse o migrarse mediante una decisión explícita.

Estas limitaciones son un diagnóstico del estado observado, no cambios aplicados por este README.

## Contribución

1. Crea una rama de trabajo.
2. No incluyas `.env`, tokens, contraseñas, bases locales ni artefactos generados.
3. Mantén los cambios acotados al dominio que modificas.
4. Ejecuta las verificaciones relevantes antes de abrir una revisión.
5. Comprueba que cualquier cambio de esquema, contrato de dinero, autorización o sincronización incluya pruebas y documentación actualizada.
