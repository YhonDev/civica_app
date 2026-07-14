# Tasks: Propietario Dashboard v2 — Activity Timeline

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | 280–350 |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |
| Delivery strategy | auto-forecast |
| Chain strategy | size-exception |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: size-exception
400-line budget risk: Low

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | Backend timeline endpoint + Frontend screen + router | PR 1 | Single PR — all changes are tightly coupled |

## Phase 1: Backend — Timeline DTO + Endpoint

- [x] 1.1 Create `TimelineItemDto` and `TimelineResponse` interfaces in `apps/backend/src/ledger/application/dtos/dashboard.dto.ts` — type `PAGO | SOLICITUD`, fields: id, date, monto, description, estado
- [x] 1.2 Add `getPropietarioTimeline(@CurrentUser() user, @Query('offset') offset, @Query('limit') limit)` to `DashboardController` — `@Get('dashboard/propietario/timeline')`, `@Roles(PROPIETARIO)`
- [x] 1.3 Implement merge logic: fetch all pagos via `pagoRepository.findByPropietario(user.propietarioId)` and all solicitudes via `solicitudRepository.findByUsuario(user.id)`, map to `TimelineItemDto[]`, sort by date DESC, slice `[offset..offset+limit]`, return `{ items, hasMore }`
- [x] 1.4 Pago mapping: `{ type: 'PAGO', date: pago.fechaPago, monto: pago.monto/100, description: 'Pago de cuota', estado: 'PAGADO' }`
- [x] 1.5 Solicitud mapping: `{ type: 'SOLICITUD', date: solicitud.fecha, monto: null, description: solicitud.descripcion, estado: solicitud.estado }`

## Phase 2: Backend — Unit Tests

- [x] 2.1 Create `apps/backend/src/ledger/application/queries/dashboard.timeline.spec.ts` — mock PagoRepository + SolicitudRepository, test merge + sort + pagination logic
- [x] 2.2 Test: pagos and solicitudes merged, sorted by date DESC
- [x] 2.3 Test: empty response when both repos return []
- [x] 2.4 Test: pagination — offset=0 limit=2 returns first 2, hasMore=true when 5 total
- [x] 2.5 Test: last page — offset=4 limit=2 returns 1 item, hasMore=false

## Phase 3: Frontend — PropietarioDashboardScreen

- [x] 3.1 Create `apps/mobile/lib/features/dashboard_propietario/propietario_dashboard_screen.dart` — StatefulWidget, fetches `GET /dashboard/propietario/timeline` on init, manages `_items`, `_offset`, `_hasMore`, `_loading` state
- [x] 3.2 Reuse existing summary card data from `GET /dashboard/propietario` (saldo, status, proximoCobro, ultimoPago) — call both endpoints, show summary at top
- [x] 3.3 Render summary section: `EstadoCuentaCard` + proximoPago + ultimoPago (same as MiEstadoScreen top section)
- [x] 3.4 Create `apps/mobile/lib/features/dashboard_propietario/widgets/timeline_paged_list.dart` — wraps `ListView.builder` + `TimelineWidget`, calls `onLoadMore` when scrolled to bottom, shows `CircularProgressIndicator` at bottom during fetch
- [x] 3.5 Map backend `TimelineItemDto` → `TimelineItem`: pagos show "Pagaste $X COP", solicitudes show "Solicitaste cobro"
- [x] 3.6 Add loading shimmer state (reuse `SkeletonBox`/`SkeletonCard` from `dashboard/widgets/skeleton_loading.dart`)
- [x] 3.7 Add empty state: "Sin actividad reciente" when no items

## Phase 4: Frontend — Router + Integration

- [x] 4.1 Update `apps/mobile/lib/core/router/app_router.dart` — change `_dashboardForRol` PROPIETARIO case to return `PropietarioDashboardScreen` instead of `MiEstadoScreen`
- [x] 4.2 Import `propetario_dashboard_screen.dart` in router, keep MiEstadoScreen import for potential fallback

## Phase 5: Frontend — Widget Tests

- [x] 5.1 Create `apps/mobile/test/widgets/propetario_dashboard_screen_test.dart` — widget test with mocked ApiClient, verify timeline items render
- [x] 5.2 Test: loading state shows skeleton
- [x] 5.3 Test: timeline items display correct labels ("Pagaste", "Solicitaste")
