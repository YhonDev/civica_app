# Tasks: Beta1 Propietario & Cartera

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~120–150 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |
| Delivery strategy | auto-forecast |
| Chain strategy | size-exception |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: size-exception
400-line budget risk: Low

## Phase 1: Backend — Propietario Info

- [x] 1.1 Add `findByIdWithRelations(id)` to `apps/backend/src/community/infrastructure/propietario.repository.ts` — loads tenencias→casa→manzana→etapa via `findOne` with relations
- [x] 1.2 Inject `PropietarioRepository` into `apps/backend/src/ledger/infrastructure/controllers/dashboard.controller.ts` constructor
- [x] 1.3 In `getDashboardPropietario`, call `findByIdWithRelations(user.propietarioId)` and add `propietarioInfo: { nombre, casaDireccion, etapaNombre }` to the return object
- [x] 1.4 Handle null propietario / missing tenencia: return empty strings for all propietarioInfo fields

## Phase 2: Backend — Role Gating

- [x] 2.1 In `apps/backend/src/ledger/infrastructure/controllers/cuotas.controller.ts`, change `@Roles(RolUsuario.ADMIN)` on `listar()` (`GET /cuotas`) to `@Roles(RolUsuario.ADMIN, RolUsuario.COBRADOR)`
- [x] 2.2 Change `@Roles(RolUsuario.ADMIN)` on `listarPorPropietario()` (`GET /cuotas/propietario/:id`) to `@Roles(RolUsuario.ADMIN, RolUsuario.PROPIETARIO)`
- [x] 2.3 Add self-access guard in `listarPorPropietario`: if `user.rol === PROPIETARIO && user.propietarioId !== propietarioId`, throw `ForbiddenException`
- [x] 2.4 Add `@CurrentUser() user: Usuario` parameter to `listarPorPropietario` method signature

## Phase 3: Frontend — CarteraRepository Role-Aware

- [x] 3.1 In `apps/mobile/lib/features/cartera/cartera_repository.dart`, add optional `role` and `propietarioId` constructor params
- [x] 3.2 In `getCarteraResumen()` and `getCobros()`: if role is `PROPIETARIO`, call `GET /cuotas/propietario/{propietarioId}` instead of `GET /cuotas`
- [x] 3.3 In `apps/mobile/lib/features/cartera/cartera_screen.dart`, read `rol` and `propietarioId` from `AuthCubit` in `initState`, pass them to `CarteraRepository` constructor

## Phase 4: Frontend — Router & Screen Adaptations

- [x] 4.1 In `apps/mobile/lib/core/router/app_router.dart`, replace `PlaceholderScreen('Cartera')` in `_carteraForRol` for COBRADOR/PROPIETARIO with `CarteraScreen()`
- [x] 4.2 In `cartera_screen.dart`, make subtitle dynamic by role: ADMIN→"Resumen general de tu comunidad", COBRADOR→"Resumen de cobros", PROPIETARIO→"Tus cuotas"
- [x] 4.3 In `cartera_screen.dart`, hide "Registrar Pago" button when role is PROPIETARIO (pass `null` for `onRegistrarPago`)
- [x] 4.4 In `apps/mobile/lib/features/dashboard_propietario/mi_estado_screen.dart`, parse `propietarioInfo` from dashboard API response in `_loadDashboardData`
- [x] 4.5 In `_buildHeader`, replace hardcoded `'Urb. San Sebastián - Etapa 1'` and `'Mz. A, Casa 1'` with `propietarioInfo['etapaNombre']` and `propietarioInfo['casaDireccion']`

## Phase 5: Testing

- [x] 5.1 Backend integration: test `GET /dashboard/propietario` returns `propietarioInfo` with real data for a propietario with tenencia/casa
- [x] 5.2 Backend integration: test `GET /cuotas` returns 200 for COBRADOR, 403 for PROPIETARIO
- [x] 5.3 Backend integration: test `GET /cuotas/propietario/:id` returns 200 for PROPIETARIO (own data), 403 when accessing another propietario's cuotas
- [x] 5.4 Frontend unit: test `CarteraRepository` calls correct endpoint for PROPIETARIO vs COBRADOR role
