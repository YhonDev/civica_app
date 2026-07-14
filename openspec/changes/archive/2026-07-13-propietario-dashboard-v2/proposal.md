# Proposal: Propietario Dashboard v2 — Activity Timeline

## Intent

The propietario dashboard currently shows only 2 raw "movimientos" (cuota + pago) with no activity feed. The AMI admin dashboard has a rich timeline — propietarios need the same but scoped to their own data. This adds a pagos + solicitudes timeline to give propietarios visibility into their payment history and requests.

## Scope

### In Scope
- Backend: new timeline query endpoint returning pagos + solicitudes by `propietario_id`
- Backend: new DTO for propietario timeline items
- Frontend: new `PropietarioDashboardScreen` (separate from `MiEstadoScreen`)
- Timeline events with propietario-perspective labels ("Pagaste", "Solicitaste cobro")
- Reuse existing `TimelineWidget` and `ActividadSection` pattern

### Out of Scope
- Actividad entity changes (no `propietario_id` column, no migration)
- "Hoy" summary block — timeline only
- Cobrador name references in propietario view
- Solicitud creation/resolution activity types (future)
- Modifying `MiEstadoScreen` — stays as-is for state-of-account

## Capabilities

### New Capabilities
- `propietario-timeline`: Backend endpoint + frontend screen showing pagos and solicitudes scoped to a propietario, displayed as a chronological timeline

### Modified Capabilities
None — existing specs (cartera, historial, propietario-info) are unaffected.

## Approach

**Direct Query (Approach C from exploration)** — query `Pago` and `Solicitud` entities directly by `propietario_id`. No Actividad system changes, no migration.

**Backend**:
1. Add `findRecentByPropietario(propietarioId, tenantId, limit)` to `PagoRepository`
2. Add equivalent for solicitudes (or reuse existing propietario-scoped query)
3. New endpoint `GET /dashboard/propietario/timeline` or extend existing endpoint with `timeline[]` array
4. Merge + sort pagos + solicitudes by date, map to unified `TimelineItemDto`

**Frontend**:
1. New `PropietarioDashboardScreen` at route `/dashboard-propietario`
2. Fetches timeline from backend, renders via `TimelineWidget`
3. Labels: pagos → "Pagaste $X COP", solicitudes → "Solicitaste cobro"
4. No "Hoy" block, no cobrador names

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `apps/backend/src/ledger/infrastructure/controllers/dashboard.controller.ts` | Modified | New timeline endpoint or extended propietario endpoint |
| `apps/backend/src/ledger/domain/pago.repository.ts` | Modified | Add `findRecentByPropietario` method |
| `apps/backend/src/ledger/infrastructure/pago.repository.impl.ts` | Modified | Implement new query |
| `apps/backend/src/ledger/application/dtos/dashboard.dto.ts` | Modified | New `TimelineItemDto` |
| `apps/mobile/lib/features/dashboard_propietario/` | New | New `PropietarioDashboardScreen` + widgets |
| `apps/mobile/lib/app/router.dart` | Modified | New route `/dashboard-propietario` |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Solicitud query may not exist yet for propietario scope | Medium | Check existing SolicitudRepository; add method if missing |
| Response size increase if combining with existing endpoint | Low | New endpoint avoids breaking existing `MiEstadoScreen` contract |
| No activity types beyond PAGO/SOLICITUD in MVP | Low | Acceptable — timeline will be financial-only initially |

## Rollback Plan

- **Backend**: Remove new endpoint/method; existing `getDashboardPropietario` unchanged
- **Frontend**: Remove new screen + route; `MiEstadoScreen` untouched
- **No migration to revert** — no schema changes

## Dependencies

- `SolicitudRepository` must support propietario-scoped query (verify during design)

## Success Criteria

- [ ] Propietario can view a timeline of their pagos and solicitudes
- [ ] Timeline shows correct propietario-perspective labels
- [ ] `MiEstadoScreen` continues working unchanged
- [ ] No Actividad entity changes or DB migration required
- [ ] Response time for timeline query < 500ms with 100+ records
