# Proposal: Functional MVP — Cartera, Asignación Etapas, Registro Inline, Conflictos Sync

## Intent

Complete the functional MVP by filling five gaps that block real-world use: cartera visibility for residents and cobradores (HU-18/19), stage assignment management (HU-10), inline resident registration from payment flow (HU-17b), and offline sync conflict resolution (HU-17). Email notifications are explicitly excluded from this change.

## Scope

### In Scope
- **Cartera Visual (HU-18)** — Calendar + list views with colored status badges for PROPIETARIO
- **Cartera Consolidada (HU-19)** — Unified admin/cobrador view with filters (etapa, manzana, status)
- **Asignación Etapas (HU-10)** — CRUD for assigning/unassigning etapas to cobrador, mobile UI
- **Registro Inline (HU-17b)** — Bottom sheet form to create resident when paying a casa with no linked resident
- **Conflictos Sync (HU-17)** — Detect 409 conflicts, show alert, retry with backoff (no silent SYNC_OK)

### Out of Scope
- Email notifications (future SDD)
- Deploy/infra changes (Railway/Render deferred)
- Sentry/error monitoring setup
- E2E tests (unit + integration only this cycle)
- Dashboard monolith refactor (HU-20 reportes — deferred; current dashboard endpoints serve cartera data adequately)
- CSV/PDF export (deferred to reportes SDD)
- Batch etapa assignment (single-assign per interaction)

## Capabilities

### New Capabilities
- `cartera-visual`: Calendar and list views for resident wallet with status badges and date filtering
- `cartera-consolidated`: Unified admin/cobrador cartera with etapa/manzana/status filters
- `asignacion-etapas`: CRUD management of cobrador-to-etapa assignments, mobile UI
- `registro-inline-residente`: Inline resident creation from payment flow when casa has no resident
- `sync-conflict-resolution`: 409 detection, user alert, and retry with exponential backoff

### Modified Capabilities
- `cartera`: Existing spec adds calendar view requirement for PROPIETARIO and filter params for COBRADOR/ADMIN

## Approach

### Cartera Visual (HU-18)
- Add `table_calendar` package; replace raw setState with CarteraCubit for reactive state
- Fix CobroItem model to deserialize `fechaVencimiento` and `periodoInicio` from backend
- Eliminate redundant `getCarteraResumen()` / `getCobros()` calls — single data source
- Two view modes: calendar (tap date → cobros for that period) and list (grouped by month, colored badges: green=pagado, yellow=pendiente, red=vencido, blue=parcial)
- Online-only initially; offline cache added later

### Cartera Consolidada (HU-19)
- Extend `GET /cuotas` with query params: `?etapaId=&manzana=&status=`
- Add `CarteraConsolidatedCubit` with filter state
- Display card per propietario with aggregated monto/pagado/pendiente

### Asignación Etapas (HU-10)
- Add `DELETE /asignaciones/:id` endpoint
- Add `POST /asignaciones/batch` for multi-etapa assignment
- New mobile screen: `AsignacionEtapaScreen` with list of cobradores, tap to manage assigned etapas
- Fix `DashboardController` to use TypeORM entity relationships instead of raw SQL

### Registro Inline (HU-17b)
- Add `ResidenteInlineSheet` bottom sheet triggered from CobroBloc when `casa.residente == null`
- Fields: nombre, email, telefono, password (auto-generated)
- Calls `POST /residentes`, links to casa, returns Residente for payment flow to continue
- Error handling: duplicate email → show message, allow retry

### Conflictos Sync (HU-17)
- Create `conflict_handler.dart` with `SyncConflictHandler` class
- On HTTP 409: call `PagoDao.marcarConflicto()` (already exists, never used), show `ConflictAlertDialog` with retry button
- Retry uses exponential backoff (1s, 2s, 4s) — max 3 attempts
- Sequential sync stops on conflict; user must resolve before continuing
- `SYNC_OK` only on true 200/201 — fix the bug where 409 was treated as success

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `apps/mobile/lib/features/cartera/` | New/Modified | New cubit, calendar view, list view, badges, consolidated view |
| `apps/mobile/lib/core/models/cobro_item.dart` | Modified | Add fechaVencimiento, periodoInicio fields |
| `apps/mobile/lib/core/sync/sync_service.dart` | Modified | Fix 409 handling, add conflict_handler integration |
| `apps/mobile/lib/core/sync/conflict_handler.dart` | New | Conflict detection, alert, retry logic |
| `apps/mobile/lib/features/residentes/` | New | Inline resident bottom sheet |
| `apps/mobile/lib/features/asignacion_etapas/` | New | Cobrador assignment management screen |
| `apps/backend/src/ledger/controllers/` | Modified | DELETE endpoint, batch assignment, filter params on cuotas |
| `apps/backend/src/iam/controllers/dashboard.controller.ts` | Modified | Replace raw SQL with entity relationships |

## Dependencies

- `asignacion-etapas` → enables `cartera-consolidated` filtering by etapa for cobrador role
- `sync-conflict-resolution` → required before `cartera-visual` online payments are reliable
- `registro-inline-residente` → independent, can be built in parallel with others
- `cartera-visual` → depends on CobroItem model fix (backend already sends the data)

## Sequencing

1. **Phase A**: Conflictos sync (fix bug, add handler) + CobroItem model fix — foundational
2. **Phase B**: Asignación etapas (backend + mobile) — enables filtering
3. **Phase C**: Cartera visual (calendar + list) + Cartera consolidated — depends on A and B
4. **Phase D**: Registro inline — independent, can slot anywhere

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| `table_calendar` compatibility with Flutter 3.44 | Low | Check pub.dev compatibility before adding; fallback to custom calendar widget |
| 409 conflict resolution UX confuses residents | Medium | Keep alert simple: "Pago en conflicto" + retry button only; no manual merge |
| DELETE endpoint breaks existing assignment data | Low | Add soft delete (status field) instead of hard delete |
| Batch assignment increases scope significantly | Medium | Start with single-assign; batch is a follow-up if time permits |

## Rollback Plan

- All changes are additive (new endpoints, new screens, new files)
- Revert by removing new routes, new screens, and new endpoint handlers
- CobroItem model fix is safe — adds fields that backend already sends; no breaking change
- Conflict handler: disable by reverting sync_service.dart 409 handling to previous behavior
- No database migrations required (existing tables suffice)

## Success Criteria

- [ ] PROPIETARIO sees calendar view with cobros color-coded by status
- [ ] PROPIETARIO can switch between calendar and list views
- [ ] ADMIN/COBRADOR can filter cartera by etapa, manzana, and payment status
- [ ] COBRADOR can manage assigned etapas from mobile (assign/unassign)
- [ ] When paying a cobro for a casa with no resident, inline form appears and creates resident
- [ ] 409 sync conflicts show alert (not silent success) and retry works with backoff
- [ ] Existing cartera, historial, and dashboard functionality remains intact (no regressions)
- [ ] All existing tests pass; new code has ≥80% coverage
