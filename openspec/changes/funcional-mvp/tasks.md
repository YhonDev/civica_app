# Tasks: Functional MVP — Cartera, Asignacion Etapas, Registro Inline, Conflictos Sync

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | 680–750 |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | PR 1: Sync fix + data model (~130 lines) → PR 2: Backend endpoints + assignment UI (~220 lines) → PR 3: Cartera UI + consolidated + inline reg (~330 lines) |
| Delivery strategy | ask-on-risk |
| Chain strategy | pending |

Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: pending
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|------|------|-----------|----------------------|-----------------|-------------------|
| 1 — Sync Fix + Data Model | Fix critical 409 bug, add ConflictHandler, extend CobroItem model, single-fetch | PR 1 (~130 lines) | `flutter test test/core/sync/` | Offline payment → 409 → verify CONFLICTO status in SQLite | `conflict_handler.dart`, `sync_service.dart`, `cartera_models.dart`, `cartera_repository.dart` — revert independently of UI |
| 2 — Backend Endpoints + Assignment | Add DELETE/POST backend endpoints, assignment Cubit + screen | PR 2 (~220 lines) | `npm run test && flutter test test/features/residentes/` | Admin toggles etapas → save → verify via API | `usuarios.controller.ts`, `asignar_etapas_cubit.dart`, `asignar_etapas_screen.dart` — no dependency on cartera UI |
| 3 — Cartera Visual + Consolidated + Inline | CarteraCubit, calendar/list, consolidated filters, inline registration | PR 3 (~330 lines) | `flutter test test/features/cartera/` | Open cartera → toggle view → verify no extra API calls | `cartera_screen.dart`, `calendar_view.dart`, `consolidated_screen.dart`, `residente_inline_sheet.dart` — all UI, fully revertable |

## Phase A: Sync Conflict Fix (Foundation)

- [x] **T01** `[mobile]` Create `apps/mobile/lib/core/sync/conflict_handler.dart` — standalone class with exponential backoff (1s→2s→4s), max 3 retries, `resolve()` method returning `ConflictResolution` enum
- [x] **T02** `[mobile]` Fix `apps/mobile/lib/core/sync/sync_service.dart` — replace `marcarSincronizado()` with `marcarConflicto()` on 409 (line 225); remove `break` on `NetworkException` to continue processing queue; emit conflict count via `_resultController`

## Phase B: CobroItem Model + Single-Fetch (Data Layer)

- [x] **T03** `[mobile]` Add `periodoInicio` and `periodoFin` fields to `CobroItem` in `apps/mobile/lib/features/cartera/models/cartera_models.dart` — extend constructor, props, and `fromJson` mapping
- [x] **T04** `[mobile]` Refactor `apps/mobile/lib/features/cartera/cartera_repository.dart` — remove `getCarteraResumen()`, add `computeResumen(List<CobroItem> cobros)` static method; map `periodoInicio`/`periodoFin` from API response in `getCobros()`
- [x] **T05** `[backend]` Modify `apps/backend/src/ledger/infrastructure/controllers/cobros.controller.ts` — accept optional `?etapaId=`, `?manzanaId=`, `?status=` query params, pass to repository

## Phase C: Etapa Assignment Management (Backend + Mobile)

- [x] **T06** `[backend]` Add `DELETE /usuarios/:id/etapas/:etapaId` to `apps/backend/src/iam/infrastructure/controllers/usuarios.controller.ts` — soft delete via repository, 200 on success, 404 if not found
- [x] **T07** `[mobile]` Create `apps/mobile/lib/features/residentes/bloc/asignacion_etapa_cubit.dart` — Cubit with `AsignacionEtapaState` (allEtapas, selectedIds, isLoading, isSaving), methods: `load(cobradorId)`, `toggle(etapaId)`, `save()`, `remove(etapaId)`
- [x] **T08** `[mobile]` Refactor `apps/mobile/lib/features/residentes/asignar_etapas_screen.dart` — replace setState with `BlocProvider<AsignacionEtapaCubit>`, add multi-select checkboxes with save/delete actions

## Phase D: Cartera Cubit + Calendar + List Views (Main UI)

- [x] **T09** `[mobile]` Create `apps/mobile/lib/features/cartera/bloc/cartera_cubit.dart` — `CarteraState` (cobros, resumen, activeFilter, showCalendar, isLoading, error); methods: `loadCobros()`, `setFilter()`, `toggleView()`; compute resumen locally from cobros list
- [x] **T10** `[mobile]` Refactor `apps/mobile/lib/features/cartera/cartera_screen.dart` — replace setState with `BlocProvider<CarteraCubit>` + `BlocBuilder`, maintain existing SegmentedButton toggle and FilterChip layout
- [x] **T11** `[mobile]` Create `apps/mobile/lib/features/cartera/widgets/calendar_view.dart` — custom month-grid calendar widget showing colored dots (🟢🟡🔴) per day based on cobro status; no new dependencies

## Phase E: Cartera Consolidated View

- [x] **T12** `[mobile]` Create `apps/mobile/lib/features/cartera/bloc/consolidated_cubit.dart` — `ConsolidatedState` (items, filters, summary metrics, isLoading); methods: `load(role, assignedEtapaIds)`, `setFilter(status, etapa, manzana)`
- [x] **T13** `[mobile]` Refactor `apps/mobile/lib/features/cartera/cartera_consolidada_screen.dart` — replace setState with `BlocProvider<ConsolidatedCubit>`, add summary metrics header (total por cobrar, mora, recaudado), add etapa/manzana dropdown filters

## Phase F: Residente Inline Registration

- [x] **T14** `[mobile]` Create `apps/mobile/lib/features/cartera/widgets/residente_inline_sheet.dart` — `showModalBottomSheet` form: nombre (required), telefono (required), email (optional), modalidadPago, etapa→manzana→casa cascade dropdowns; call `POST /residentes` on submit
- [x] **T15** `[mobile]` Modify `apps/mobile/lib/screens/cobro/payment_screen.dart` — detect when casa has no residente, trigger `ResidenteInlineSheet`, pass created residenteId back to continue payment flow
