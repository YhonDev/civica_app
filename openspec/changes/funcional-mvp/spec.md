# Delta for funcional-mvp

## MODIFIED Requirements

### Requirement: Role-Based Cuota Access

(Previously: basic role gating, no filters)

`GET /cuotas` SHALL accept optional `etapaId`, `manzana`, `status` params. COBRADOR results SHALL be scoped to assigned etapas.

- Admin filtered: `GET /cuotas?etapaId=X&status=vencido` returns matching cuotas.
- Cobrador scoped: assigned to [A,B] → only A,B cuotas returned.

### Requirement: Role-Aware Frontend Routing

(Previously: no view options)

`CarteraScreen` SHALL offer calendar/list toggle. Calendar uses `table_calendar` with green/yellow/red status badges. List sorts by `fechaVencimiento`. Toggling SHALL NOT trigger extra API calls.

---

## ADDED Requirements

### Requirement: Sync Conflict Detection

HTTP 409 during sync SHALL call `PagoDao.marcarConflicto()` and set `syncStatus=CONFLICTO`. 409 SHALL NOT be treated as success. Network errors SHALL NOT stop processing remaining payments in the queue.

- 409 → local status becomes CONFLICTO, not synchronized.
- Network error on payment #1 → #2 and #3 still attempted; errors reported in SyncResult.

### Requirement: Conflict Alert and Retry

A conflict alert SHALL display count + retry button. Retry SHALL use exponential backoff: 1s→2s→4s→8s→16s, max 5 attempts.

- Alert shown when CONFLICTO payments exist.
- Retry respects backoff schedule; stops after 5 attempts.

### Requirement: Etapa Assignment Management

`DELETE /usuarios/:id/etapas/:etapaId` removes assignment (soft delete). `POST /usuarios/:id/etapas` accepts `{etapaIds:[]}` for batch. Mobile admin exposes multi-select etapa screen.

- Remove: cobrador loses access to removed etapa's cuotas.
- Batch assign: cobrador gains access to all listed etapas.
- Mobile UI: multi-select toggles per etapa, save triggers batch endpoint.

### Requirement: Residente Inline Registration

Bottom sheet during payment flow when casa has no residente. Fields: `nombre` (required), `telefono` (required), `email` (optional), `modalidadPago` (required). After creation, flow continues with new residente.

- Empty required fields → inline validation errors, no API call.
- Successful submit → residente created, payment flow resumes.

### Requirement: Cartera Consolidated View

Unified view shows all residents + payment status. Admin sees all; cobrador sees assigned etapas. Summary metrics at top. Filters: etapa, manzana, status.

- Admin: all residents + statuses with metrics.
- Cobrador: only assigned-etapa residents.
- Status filter: e.g. "Vencido" shows only overdue.

## Data Model

No new DB schema — `CobroTable` already has `periodoInicio`/`fechaVencimiento`. SyncStatus enum adds `conflicto`. New `ConflictoRetryQueue` for backoff.

## API Changes

| Endpoint | Change |
|----------|--------|
| `GET /cuotas` | +`etapaId`, `manzana`, `status` query params |
| `DELETE /usuarios/:id/etapas/:etapaId` | New |
| `POST /usuarios/:id/etapas` | New — `{etapaIds: []}` |
| `GET /cartera/consolidated` | New — unified view |

## UI Changes

| Screen | Change |
|--------|--------|
| CarteraScreen | Calendar/list toggle + colored badges |
| AsignacionEtapaScreen | New — admin etapa management |
| ResidenteInlineSheet | New — bottom sheet registration |
| CarteraConsolidatedScreen | New — unified admin/cobrador view |
| SyncStatusView | Conflict alert + retry button |

## Dependencies

1. `table_calendar` package (check compatibility)
2. CobroItem model must expose `fechaVencimiento`/`periodoInicio`
3. Asignación etapas before consolidated filtering
4. Sync fix before reliable online payments
