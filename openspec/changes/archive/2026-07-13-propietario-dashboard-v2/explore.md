# Exploration: Propietario Dashboard v2 — Actividades en Vivo

## 1. Current State: AMI Dashboard vs Propietario Today

### AMI Dashboard (`/dashboard/administrador`)

**Endpoint**: `DashboardController.getDashboard` → delegates to `DashboardQuery.execute(mes, anio, tenantId)`

**What it returns**:
- `resumen`: recaudoTotal, metaMensual, porcentajeMeta, pagaron, pendientes, moraTotal
- `evolucion`: daily payment evolution chart data
- `modalidades`: breakdown by payment frequency (MENSUAL, QUINCENAL, etc.)
- `estadoCobros`: pagados/pendientes/revision percentages
- **`actividad[]`**: last 20 activities from `actividadRepo.findByTenant(tenantId, 20)` — ALL system-wide activities
- `solicitudesPendientes`, `nuevosPropietariosSemana`, `propietariosMora`
- `acumuladoAnual`, `metaAnual`, `historialMeses` (12-month trend)
- `cobrosPorSemana`: weekly aggregation

**Key insight**: `actividad` is unfiltered — it shows EVERY activity in the tenant (payments by any cobrador, propietario CRUD, etc.). No per-user filtering exists.

**Frontend**: `ActividadAdminScreen` loads via `DashboardRepository.getDashboard()`, maps to `DashboardData.actividadReciente`, renders via `ActividadSection` widget which has a "Resumen de hoy" block + `TimelineWidget`.

### Propietario Dashboard (`/dashboard/propietario`)

**Endpoint**: `DashboardController.getDashboardPropietario(user, tenantId)`

**What it returns TODAY**:
- `saldo`: total pending balance (cents → COP)
- `status`: AL_DIA / PENDIENTE / MORA
- `proximoCobro`: next payment due date
- `proximoPago`: detailed next payment with breakdown (desglose)
- `tarifaActual`: current tariff info
- `ultimoPago`: most recent payment summary
- `movimientos`: only last 2 items (cuota + pago merged), sliced to `.slice(0, 2)`
- `propietarioInfo`: name, address, etapa

**Frontend**: `MiEstadoScreen` — a state-of-account screen, NOT an activity feed. Shows:
1. Header (name + address)
2. EstadoCuentaCard (balance/status)
3. Proximo Pago (breakdown)
4. Timeline (only 2 "movimientos" — cuota generation + pago)
5. Solicitudes pendientes (conditional)

**DATA GAP**: The propietario dashboard has ZERO activity feed concept. It only shows 2 raw "movimientos" (cuota/pago) — not the rich timeline the AMI has.

---

## 2. Actividad System — Complete Analysis

### Entity: `Actividad` (notifications domain)

```
actividad table:
  id: uuid (PK)
  tenant_id: uuid
  tipo: varchar(50)        -- 'PAGO', 'PROPIETARIO', etc.
  descripcion: text         -- human-readable description
  usuario_nombre: varchar   -- who performed the action
  usuario_id: uuid          -- FK to usuarios.id
  metadata: jsonb           -- flexible additional data
  created_at: timestamptz
```

**Critical finding**: The Actividad entity has `usuario_id` but NO `propietario_id`. Activities are scoped by `tenant_id` only, not by user or propietario.

### How Activities Are Registered

Via `@RegistrarActividad` decorator + `ActividadInterceptor`:

1. **Pago registration** (`PagosController.registrar`):
   ```typescript
   @RegistrarActividad({
     tipo: 'PAGO',
     descripcionFn: (r) => `Pago registrado: $${(r.pago.monto / 100).toFixed(0)} COP (${r.cuotasAfectadas.length} cuota(s))`,
   })
   ```
   The interceptor captures `request.user` (the COBRADOR who registered it), creates `Actividad.crear(tenantId, tipo, desc, user.nombre, user.id)`.

2. **Propietario CRUD** (`PropietariosController`):
   - `.registrar` → tipo: 'PROPIETARIO', desc: `Nuevo propietario registrado: ${result.nombre}`
   - `.actualizar` → tipo: 'PROPIETARIO', desc: `Propietario actualizado`
   - `.eliminar` → tipo: 'PROPIETARIO', desc: `Propietario eliminado`

### ActividadRepository — Limited API

```typescript
abstract class ActividadRepository {
  abstract save(actividad: Actividad): Promise<Actividad>;
  abstract findByTenant(tenantId: string, limit: number): Promise<Actividad[]>;
}
```

**Only 2 methods**: `save` and `findByTenant`. There is NO `findByPropietario`, `findByUsuario`, `findByTipo`, or any filtering method. The `metadata` JSONB field is unused for filtering.

### Activity Types Observed

| tipo | Registered by | Description |
|------|---------------|-------------|
| `PAGO` | PagosController | Payment registered |
| `PROPIETARIO` | PropietariosController | CRUD operations on propietarios |

No activities are registered for: cuota generation, solicitud creation, account activation, tariff changes, etc.

---

## 3. Pago ↔ Cobro Analysis

### The Entity: `Pago`

```
pagos table:
  id: uuid (PK)
  client_payment_id: varchar  -- idempotency key
  tenant_id: uuid
  cuota_id: uuid (nullable)   -- first affected cuota
  monto: integer              -- cents COP
  fecha_pago: date
  cobrador_id: uuid           -- WHO registered the payment (the cobrador)
  propietario_id: uuid        -- WHO the payment is FOR
  fecha_sync: timestamptz
  sync_status: varchar
  created_at / updated_at
```

**Pago has BOTH `cobrador_id` AND `propietario_id`.** This is the single source of truth linking both sides.

### "Pago = Cobro" Resolution

**They are the SAME entity, viewed from different perspectives:**

- **Cobrador perspective**: "Hice un cobro" → `Pago` was created by me (`cobrador_id = my usuario.id`)
- **Propietario perspective**: "Hice un pago" → `Pago` is for me (`propietario_id = my propietario.id`)

**There is NO separate `cobro` entity.** The word "cobro" is purely a UI label. The cobrador dashboard calls them "cobros" (line 111 in dashboard.controller.ts: `ultimosCobros`), but they map to the same `Pago` records.

### Current Linking Gap

When a Pago is registered:
1. An `Actividad` is created with `tipo: 'PAGO'` and `usuario_id` = cobrador's usuario.id
2. The `Actividad.metadata` is empty (`{}`)
3. There is NO `propietario_id` on the Actividad record

**Result**: You CANNOT filter activities by propietario today. The only link is:
- `Pago.propietario_id` exists on the Pago entity
- `Actividad.usuario_id` = the cobrador who made it (NOT the propietario)

### How to Link Pago ↔ Actividad for Propietario Filtering

**Option A: Enrich `Actividad.metadata` at write time**
- In `ActividadInterceptor`, when `tipo === 'PAGO'`, extract `result.pago.propietarioId` and store it in `metadata: { propietarioId: '...' }`
- At query time, filter `WHERE metadata->>'propietarioId' = :propietarioId`
- **Pros**: No schema migration, backward compatible
- **Cons**: JSONB filtering less performant than indexed column

**Option B: Add `propietario_id` column to Actividad entity**
- Migration: `ALTER TABLE actividad ADD COLUMN propietario_id uuid REFERENCES propietarios(id)`
- Modify `Actividad.crear()` to accept optional `propietarioId`
- Add index on `propietario_id`
- At query time: `WHERE propietario_id = :propietarioId`
- **Pros**: Proper relational link, indexable, clean
- **Cons**: Requires DB migration, must update all call sites

**Option C: Query Pago directly instead of Actividad for propietario timeline**
- Skip the Actividad system entirely for propietario
- Build the timeline from `Pago` + `Cuota` records filtered by `propietarioId`
- For "today" summary, query pagos/cuotas with today's date
- **Pros**: No Actividad changes needed, uses existing `findByPropietario`
- **Cons**: Loses the activity types beyond Pago/Cuota (e.g., profile updates, solicitud events); only shows financial events

---

## 4. Affected Areas

### Backend
- `apps/backend/src/notifications/domain/actividad.entity.ts` — needs propietario_id (Option B) or metadata enrichment (Option A)
- `apps/backend/src/notifications/domain/actividad.repository.ts` — needs `findByPropietario()` method
- `apps/backend/src/notifications/infrastructure/actividad.repository.impl.ts` — implement `findByPropietario()`
- `apps/backend/src/shared/common/decorators/registrar-actividad.decorator.ts` — interceptor needs to extract propietarioId
- `apps/backend/src/ledger/infrastructure/controllers/dashboard.controller.ts` — `getDashboardPropietario` needs new activity section
- `apps/backend/src/ledger/application/dtos/dashboard.dto.ts` — new DTO for propietario dashboard response
- Potentially: `apps/backend/src/ledger/application/queries/` — new query class for propietario dashboard

### Frontend
- `apps/mobile/lib/features/dashboard_propietario/mi_estado_screen.dart` — main screen to enhance
- Potentially new: `apps/mobile/lib/features/dashboard_propietario/widgets/actividad_propietario_section.dart`
- Reusable: `apps/mobile/lib/shared/widgets/timeline_widget.dart` (already exists, ready to use)
- Reusable: `apps/mobile/lib/features/dashboard/widgets/actividad_section.dart` (pattern reference)
- `apps/mobile/lib/features/dashboard/models/dashboard_data.dart` — may need new model or extend existing

---

## 5. Approaches

### Approach A: Enrich Metadata + JSONB Filter (Hybrid)

Add `propietarioId` to `Actividad.metadata` at write time, filter via JSONB query.

**Backend changes**:
1. Modify `ActividadInterceptor` to detect PAGO tipo and extract `result.pago.propietarioId` into metadata
2. Add `findByPropietario(tenantId, propietarioId, limit)` to ActividadRepository using `metadata->>'propietarioId'`
3. Add `getActividadesByPropietario()` to DashboardController or a new endpoint
4. Enrich the propietario dashboard response with `actividad[]`

**Frontend changes**:
1. Add activity section to `MiEstadoScreen`
2. Create `ActividadPropietarioSection` widget (or reuse pattern from `ActividadSection`)
3. Add "Resumen de hoy" block filtered to propietario's activities

- **Pros**: No DB migration, metadata is already JSONB, backward compatible
- **Cons**: JSONB filtering slower than indexed column, only works for PAGO activities (not PROPIETARIO updates unless enriched too)
- **Effort**: Medium

### Approach B: Add `propietario_id` Column (Clean Relational)

Add a proper foreign key to the Actividad entity.

**Backend changes**:
1. DB migration: `ALTER TABLE actividad ADD COLUMN propietario_id uuid`
2. Modify `Actividad` entity to include `propietarioId`
3. Modify `Actividad.crear()` to accept optional `propietarioId`
4. Modify `ActividadInterceptor` to pass propietarioId from result when available
5. Add `findByPropietario(tenantId, propietarioId, limit)` with proper WHERE + index
6. Enrich all PAGO and PROPIETARIO activity registrations with propietarioId
7. New propietario dashboard query/endpoint

**Frontend changes**: Same as Approach A

- **Pros**: Clean, indexable, supports all activity types, proper relational model
- **Cons**: Requires DB migration, must update all `Actividad.crear()` call sites
- **Effort**: Medium-High

### Approach C: Query Pago+Cuota Directly (No Actividad Changes)

Skip the Actividad system for propietario timeline entirely. Build from financial records.

**Backend changes**:
1. Add `findRecentByPropietario(propietarioId, limit)` to PagoRepository (already has `findByPropietario`)
2. Combine pagos + cuotas in controller, format as activity items
3. Add today summary from `findByCobradorToday` equivalent for propietario
4. Enrich propietario dashboard response

**Frontend changes**: Same as Approach A

- **Pros**: No Actividad changes, uses existing repository methods, fast queries
- **Cons**: Only shows financial events (pago/cuota), no profile updates or solicitud events in timeline; "Resumen de hoy" limited to pagos
- **Effort**: Low

### Approach D: Hybrid — Financial Events + Enriched Actividad (Recommended)

Combine Approach C for financial timeline with targeted Actividad enrichment for non-financial events.

**Backend changes**:
1. For the main timeline: query Pago + Cuota directly (fast, indexed)
2. Add `propietario_id` column to Actividad (Approach B migration) for non-financial events
3. Enrich PAGO interceptor to include propietarioId
4. Add new activity types for solicitudes (SOLICITUD_CREADA, SOLICITUD_RESUELTA)
5. New propietario dashboard endpoint that merges both sources

**Frontend changes**:
1. New `MiEstadoV2Screen` or enhance existing `MiEstadoScreen`
2. "Resumen de hoy" section: today's pagos + today's solicitudes
3. Full activity timeline: pagos + cuotas + solicitudes + profile changes
4. Reuse `TimelineWidget` and pattern from `ActividadSection`

- **Pros**: Best of both worlds, clean data model, supports all event types, performant
- **Cons**: More work, DB migration needed
- **Effort**: Medium-High

---

## 6. Recommendation

**Approach D (Hybrid)** is recommended because:

1. **Financial events are the core**: Pagos and cuotas dominate the propietario experience. Querying them directly via existing `PagoRepository.findByPropietario()` is fast, clean, and already works.

2. **Non-financial events matter too**: Profile updates, solicitud creation/resolution — these should appear in the timeline. Adding `propietario_id` to Actividad handles these.

3. **"Hoy" summary is straightforward**: Today's pagos + today's solicitudes for this propietario. Both can be queried with date filters.

4. **The `metadata` approach (A) is a hack**: JSONB filtering works but is fragile and non-idiomatic for a relational system.

5. **Approach C is too limited**: Only financial events = incomplete picture.

**However**, if the user wants a faster MVP, **Approach C** is viable as a first pass — it delivers 80% of the value with 30% of the effort. The timeline would show pagos and cuotas (which is what "actividades en vivo" means for a propietario's financial life), and the "Hoy" section would show today's payments.

### Effort Estimate

| Approach | Backend | Frontend | Migration | Total |
|----------|---------|----------|-----------|-------|
| A: Metadata JSONB | Medium | Medium | None | Medium |
| B: Add column | Medium | Medium | Yes | Medium-High |
| C: Direct query | Low | Medium | None | Low-Medium |
| D: Hybrid | High | Medium | Yes | Medium-High |

---

## 7. Risks

1. **Activity registration coverage**: Currently only PAGO and PROPIETARIO activities are registered. Solicitud events, cuota generation, etc. have NO activity records. Even with propietario filtering, the timeline would be sparse until more interceptors are added.

2. **Performance of `findByPropietario`**: For Approach A (JSONB), without an index on `metadata->>'propietarioId'`, query performance degrades at scale. Needs `CREATE INDEX idx_actividad_propietario ON actividad ((metadata->>'propietarioId'))` if using JSONB.

3. **Data migration for existing activities**: If choosing Approach B, existing PAGO activities don't have propietarioId populated. A backfill migration would be needed: `UPDATE actividad SET propietario_id = p.propietario_id FROM pagos p WHERE actividad.tipo = 'PAGO' AND ...` — but there's no direct FK between Actividad and Pago.

4. **Dashboard response size**: Adding an activity array to the propietario endpoint increases response size. Currently the endpoint is lean (saldo, status, proximoPago, 2 movimientos). Adding 20 activities changes the contract.

5. **Frontend screen complexity**: `MiEstadoScreen` is already a "state of account" screen. Adding a full activity feed changes its identity. Consider whether to create a separate screen/tab vs. embedding in the existing one.
