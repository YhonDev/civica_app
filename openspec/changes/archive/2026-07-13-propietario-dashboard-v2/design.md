# Design: Propietario Dashboard v2 — Activity Timeline

## Technical Approach

Add a single paginated timeline endpoint (`GET /dashboard/propietario/timeline`) that merges pagos and solicitudes for the authenticated propietario. Create a new `PropietarioDashboardScreen` with infinite scroll using the existing `TimelineWidget`. No new entities, no migration, no Actividad table changes.

Key insight: `Solicitud.usuarioId` links to `Usuario.id`, and `user.propietarioId` is available from the auth token. We resolve solicitudes via `SolicitudRepository.findByUsuario(usuarioId)`.

## Architecture Decisions

### Decision: Extend DashboardController vs. new controller

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Add method to `DashboardController` | Keeps all dashboard endpoints together; already has auth/role guards wired; no new module registration | **Chosen** |
| New `PropietarioTimelineController` | Cleaner SRP but requires new provider registration, guard wiring, and spreads dashboard logic across files | Rejected — overkill for one endpoint |

### Decision: Solicitud lookup strategy

| Option | Tradeoff | Decision |
|--------|----------|----------|
| `SolicitudRepository.findByUsuario(usuarioId)` — existing method | Works today; solicitudes are already keyed by `usuarioId`; no new query needed | **Chosen** |
| Add `findByPropietario()` to SolicitudRepository | Cleaner naming but requires joining through Usuario; adds method nobody else needs | Rejected |
| Raw SQL join via DataSource | Maximum control but breaks repository abstraction | Rejected |

### Decision: Pagination — backend merge + slice vs. two parallel paginated queries

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Fetch all propietario's pagos + solicitudes, merge in memory, slice `[offset..offset+limit]` | Simple; fine for MVP where a propietario has <500 lifetime records | **Chosen** |
| Two separate paginated SQL queries + merge in controller | More complex; needed only at scale (1000+ records per propietario) | Deferred |

### Decision: New screen vs. modify MiEstadoScreen

| Option | Tradeoff | Decision |
|--------|----------|----------|
| New `PropietarioDashboardScreen` at `/dashboard-propietario` | Preserves MiEstadoScreen as home (status card); timeline is a separate full-screen experience | **Chosen** |
| Modify MiEstadoScreen to add infinite scroll | Conflates "account status" with "activity feed"; breaks the 5-block rule from doc/19 | Rejected |

## Data Flow

```
GET /dashboard/propietario/timeline?offset=0&limit=20
        │
        ▼
DashboardController.getPropietarioTimeline()
        │
        ├──→ PagoRepository.findByPropietario(propId)  ──→ Pago[]
        │
        ├──→ SolicitudRepository.findByUsuario(user.id) ──→ Solicitud[]
        │
        ▼
  Merge + sort by date DESC
        │
        ▼
  Slice [offset .. offset+limit] → TimelineItemDto[]
  + hasMore flag
        │
        ▼
  Response: { items: TimelineItemDto[], hasMore: boolean }
```

Frontend:
```
PropietarioDashboardScreen
    │
    ├──→ GET /dashboard/propietario/timeline?offset=0&limit=20
    │       → items[] → ListView.builder
    │
    └──→ onScrollBottom → GET ...?offset=20&limit=20
            → append items[] → update hasMore
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `apps/backend/src/ledger/infrastructure/controllers/dashboard.controller.ts` | Modify | Add `getPropietarioTimeline()` endpoint with `@Roles(PROPIETARIO)`, offset/limit query params |
| `apps/mobile/lib/features/dashboard_propietario/propietario_dashboard_screen.dart` | Create | New screen: timeline feed with infinite scroll, loading/error/empty states |
| `apps/mobile/lib/core/router/app_router.dart` | Modify | Add `/dashboard-propietario` route and import |
| `apps/mobile/lib/features/dashboard_propietario/widgets/timeline_paged_list.dart` | Create | Reusable paged ListView wrapping TimelineWidget with infinite scroll + loading indicator |

## Interfaces / Contracts

### Backend — TimelineItemDto

```typescript
// Returned by GET /dashboard/propietario/timeline
interface TimelineItemDto {
  id: string;              // UUID
  type: 'PAGO' | 'SOLIDUD';
  date: string;            // ISO 8601
  monto: number | null;    // COP, only for PAGO
  description: string;     // Human-readable
  estado: string;          // Current status
}

// Response envelope
interface TimelineResponse {
  items: TimelineItemDto[];
  hasMore: boolean;
}
```

### Mapping logic (controller)

```
Pago → { id, type: 'PAGO', date: pago.fechaPago, monto: pago.monto/100, description: 'Pago de cuota', estado: 'PAGADO' }
Solicitud → { id, type: 'SOLIDUD', date: solicitud.fecha, monto: null, description: solicitud.descripcion, estado: solicitud.estado }
```

### Frontend — PropietarioDashboardScreen

Reuses existing `TimelineWidget` from `shared/widgets/timeline_widget.dart`. Labels in propietario voice: pagos show "Pagaste $X COP", solicitudes show "Solicitaste cobro". No "Hoy" block. AppBar with back navigation.

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Unit (backend) | Timeline merge + sort + pagination logic | Test controller method with mocked repositories (PagoRepository, SolicitudRepository) — follow `dashboard.query.spec.ts` pattern |
| Integration (backend) | Endpoint auth + role guard + DB queries | E2E test: create pagos + solicitudes for a propietario, hit endpoint, verify merged sorted response |
| Unit (frontend) | PropietarioDashboardScreen renders timeline items | Widget test with mocked ApiClient response |
| E2E | Infinite scroll loads next page | Manual / integration test: verify scroll triggers next fetch and appends items |

## Migration / Rollout

No migration required. All data comes from existing `pagos` and `solicitudes` tables. The new endpoint is additive — existing `/dashboard/propietario` remains unchanged.

## Open Questions

- [ ] Should solicitudes include cuota info (periodo, monto) for richer timeline display? Current spec says `monto: null` for solicitudes — confirm this is acceptable.
- [ ] Should the route `/dashboard-propietario` replace `MiEstadoScreen` as the propietario home, or remain a separate navigable screen?
