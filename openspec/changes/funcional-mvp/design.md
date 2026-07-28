# Design: Functional MVP — Cartera, Asignacion Etapas, Registro Inline, Conflictos Sync

## Technical Approach

Five feature areas building on existing NestJS + Flutter architecture. The codebase already uses flutter_bloc (CobroBloc, AuthCubit, DashboardCubit) but CarteraScreen and AsignarEtapasScreen use raw setState. This change migrates those to Cubit, fixes the sync 409 bug, adds missing backend endpoints, and introduces inline resident registration. No database schema migrations required — all needed columns exist in backend entities already.

## Architecture Decisions

| Choice | Alternatives | Rationale |
|--------|-------------|-----------|
| CarteraCubit (not full Bloc) | Keep setState; full Bloc with events | Cubit matches AuthCubit/DashboardCubit pattern; read-only screen doesn't need event bus |
| Fix 409: call marcarConflicto() | Server-side idempotency; conflict dialog | marcarConflicto() exists but is never called — one-line bug fix |
| Single-fetch: one GET /cobros | Keep two calls; server-side resumen | getCarteraResumen() and getCobros() call same endpoint — eliminate redundancy |
| DELETE /usuarios/:id/etapas/:etapaId | Use PUT with filtered list | Explicit DELETE for UX clarity; PUT remains for batch replace |
| Alert dialog for conflicts | Inline banner; snackbar | Conflicts are rare; dialog matches existing credential pattern |
| CarteraCubit + filter/view state | Separate Cubits per concern | One Cubit manages resumen + cobros + active filter + view toggle — simple, testable |
| AsignacionEtapaCubit | Keep raw setState in AsignarEtapasScreen | Load+toggle+save cycle needs proper state for loading/error/saving |
| ConflictHandler as standalone class | Embed in SyncService | Separation of concerns; SyncService stays lean, ConflictHandler owns retry logic |
| ResidenteInlineSheet (StatefulWidget) | Use BLoC for form | Bottom sheet form is short-lived; StatefulWidget with local state is standard pattern in this codebase |
| CarteraConsolidatedCubit | Keep raw setState | Filter state + loading + data needs proper lifecycle management |

## Data Flow

### Sync Conflict Flow

```
PagoDao.insertOffline() --> SyncService._executeSync()
    --> POST /pagos
        |-- 200 OK --> PagoDao.marcarSincronizado()
        |-- 409    --> PagoDao.marcarConflicto()  [BUG FIX]
        |-- 401    --> break (auth error)
        |-- other  --> errors++
    --> Stream<SyncResult> --> UI listens
    --> ConflictHandler checks getEnConflicto()
    --> Shows AlertDialog with retry/omit options
```

### Cartera Visual Flow

```
CarteraScreen (BLoCProvider)
  --> CarteraCubit.loadCobros()
    --> CarteraRepository.getCobros()  [single call]
    --> Emits CarteraState(cobros, resumen, filter, viewMode)
  --> CarteraCalendar or GroupedList based on viewMode
  --> FilterChip changes cubit.setFilter()
```

### Asignacion Etapas Flow

```
CobradorCard --> tap "Gestionar Etapas"
  --> AsignarEtapasScreen
    --> AsignacionEtapaCubit.load(cobradorId)
      --> GET /usuarios/:id/etapas  (current assignments)
      --> GET /comunidad/etapas     (all available)
    --> Toggle checkbox
    --> AsignacionEtapaCubit.save()
      --> PUT /usuarios/:id/etapas {etapaIds: [...]}
    --> Delete single: DELETE /usuarios/:id/etapas/:etapaId
```

### Registro Inline Flow

```
CobroCard --> "Registrar" button
  --> ResidenteInlineSheet (showModalBottomSheet)
    --> Form: nombre, telefono, email, casa (dropdown)
    --> Submit --> POST /residentes
    --> On success: close sheet, pass residenteId back
    --> Parent opens RegistrarPagoBottomSheet with new residenteId
```

## API Contracts

### New: DELETE /usuarios/:id/etapas/:etapaId

```typescript
// Request
DELETE /usuarios/:id/etapas/:etapaId
Authorization: Bearer <token>
Roles: ADMIN

// Response 200
{ success: true }

// Response 404
{ statusCode: 404, message: "Asignacion no encontrada" }
```

### Modified: GET /cobros (add date fields to response)

```typescript
// Response item adds:
{
  "periodoInicio": "2026-07-01",
  "periodoFin": "2026-07-31",
  "fechaVencimiento": "2026-07-15",
  // ... existing fields unchanged
}
```

### Modified: GET /dashboard/cartera-consolidada (add etapaId filter for cobrador)

```typescript
// Already supports ?etapaId= and ?estado= query params
// No change needed — mobile just needs to pass cobrador's assigned etapaIds
```

### New: POST /residentes (already exists — inline sheet reuses it)

```typescript
// Existing endpoint, used by NuevoResidenteScreen
// ResidenteInlineSheet calls same endpoint with subset of fields
POST /residentes
{
  "nombre": "string",
  "telefono": "string",
  "email": "string (optional)",
  "casaId": "string (optional)",
  "modalidadPago": "MENSUAL"
}
```

## Database Changes

No migrations required. All needed columns already exist:

- `cobros`: `periodo_inicio`, `periodo_fin`, `fecha_vencimiento` — already in Cobro entity
- `pagos`: `syncStatus` with values `PENDIENTE_SYNC`, `SYNC_OK`, `CONFLICTO` — already in Drift schema
- `asignaciones_etapa`: `usuario_id`, `etapa_id`, `tenant_id` — already exists with CASCADE delete

## File Changes

### Mobile (apps/mobile/lib/)

| File | Action | Description |
|------|--------|-------------|
| `features/cartera/cartera_cubit.dart` | Create | Cubit managing resumen, cobros, filter, viewMode |
| `features/cartera/cartera_state.dart` | Create | Equatable state class for CarteraCubit |
| `features/cartera/cartera_screen.dart` | Modify | Replace setState with BlocProvider + BlocBuilder |
| `features/cartera/cartera_repository.dart` | Modify | Remove getCarteraResumen(), compute from getCobros() |
| `features/cartera/models/cartera_models.dart` | Modify | Add periodoInicio, periodoFin to CobroItem |
| `features/cartera/widgets/cartera_calendar.dart` | Create | New calendar widget using table_calendar package |
| `features/cartera/cartera_consolidada_screen.dart` | Modify | Replace setState with CarteraConsolidatedCubit |
| `features/cartera/cartera_consolidated_cubit.dart` | Create | Cubit for consolidated view with filters |
| `features/residentes/asignacion_etapa_cubit.dart` | Create | Cubit for assignment load/toggle/save |
| `features/residentes/asignar_etapas_screen.dart` | Modify | Replace setState with BlocProvider + BlocBuilder |
| `features/residentes/widgets/residente_inline_sheet.dart` | Create | Bottom sheet for inline resident creation |
| `core/sync/conflict_handler.dart` | Create | Conflict detection, retry queue, exponential backoff |
| `core/sync/sync_service.dart` | Modify | Fix 409 bug: call marcarConflicto(), stream conflicts |

### Backend (apps/backend/src/)

| File | Action | Description |
|------|--------|-------------|
| `iam/infrastructure/controllers/usuarios.controller.ts` | Modify | Add DELETE endpoint for single etapa removal |
| `ledger/infrastructure/controllers/cobros.controller.ts` | Modify | Add query params (etapaId, manzanaId) for filtering |
| `ledger/infrastructure/controllers/dashboard.controller.ts` | Modify | Add cobrador filter support to cartera-consolidada |

## Interfaces / Contracts

```dart
// CarteraState
class CarteraState extends Equatable {
  final List<CobroItem> cobros;
  final CarteraResumen? resumen;
  final String activeFilter;     // 'Pendiente' | 'Mora' | 'Pagado' | 'Todos'
  final bool showCalendar;
  final bool isLoading;
  final String? error;
}

// CobroItem — extended
class CobroItem extends Equatable {
  // ... existing fields ...
  final String fechaVencimiento;
  final String periodoInicio;   // NEW
  final String periodoFin;      // NEW
}

// ConflictHandler
class ConflictHandler {
  Future<ConflictResolution> resolve({
    required Pago pago,
    required Future<void> Function() retry,
    required Future<void> Function() markConflict,
  });
}

enum ConflictResolution { resolved, skipped, deferred }

// AsignacionEtapaState
class AsignacionEtapaState extends Equatable {
  final List<Map<String, dynamic>> allEtapas;
  final Set<String> selectedEtapaIds;
  final bool isLoading;
  final bool isSaving;
  final String? error;
}
```

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Unit | CarteraCubit state transitions | Mock CarteraRepository, verify emits loading->loaded |
| Unit | ConflictHandler retry logic | Mock PagoDao + syncPayment callback, simulate 409 then 200 |
| Unit | AsignacionEtapaCubit toggle/save | Mock ApiClient, verify selected IDs track correctly |
| Unit | Single-fetch resumen computation | Feed mock cobros list, verify CarteraResumen totals |
| Widget | CarteraScreen renders BlocBuilder | Pump with BlocProvider, verify filter chips and list appear |
| Widget | ResidenteInlineSheet form validation | Pump sheet, tap submit empty, verify snackbar error |
| Widget | ConflictHandler alert dialog | Trigger conflict stream, verify dialog appears |
| Integration | Sync flow: offline payment -> 409 -> conflict marked | Mock ApiClient returning 409, verify pago status in DB |
| Integration | Assignment flow: toggle etapa -> save -> verify | Mock both endpoints, verify PUT called with correct IDs |

## Migration / Rollout

No data migration required. Feature rollout:

1. **Phase 1**: Fix sync 409 bug (critical, no new features)
2. **Phase 2**: ConflictHandler + alert dialog (depends on Phase 1)
3. **Phase 3**: AsignacionEtapas backend DELETE + mobile Cubit
4. **Phase 4**: CarteraVisual Cubit + calendar + single-fetch
5. **Phase 5**: CarteraConsolidated Cubit
6. **Phase 6**: Registro inline bottom sheet

Each phase is independently deployable. No feature flags needed.

## Threat Matrix

N/A — no routing, shell, subprocess, VCS/PR automation, executable-file classification, or process-integration boundary.

## Open Questions

- [ ] Should table_calendar be added as a dependency, or keep the existing custom calendar widget? (Low risk — custom works, but table_calendar has better gesture support)
- [ ] For the DELETE endpoint: should it require the etapa to exist, or be idempotent? (Recommend idempotent — 200 even if not found)
- [ ] ResidenteInlineSheet: should it support casa selection or just nombre/telefono? (Depends on whether cobrador knows the casa at payment time)
