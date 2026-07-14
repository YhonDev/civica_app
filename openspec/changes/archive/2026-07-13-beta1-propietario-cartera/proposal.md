# Proposal: Beta1 Propietario & Cartera

## Intent

The mobile app has hardcoded addresses and role-gated screens that block Beta1. Propietarios see fake addresses; Cobradores and Propietarios cannot access Cartera or Historial. This change makes the app functional for all three user roles.

## Scope

### In Scope
1. **Dynamic propietario info** — backend dashboard returns `nombre`, `casaDireccion`, `etanaNombre`; frontend reads from response instead of hardcoded strings
2. **Cartera for Cobrador** — add `COBRADOR` role to `GET /cuotas`; wire router to `CarteraScreen`
3. **Cartera for Propietario** — add `PROPIETARIO` role to `GET /cuotas/propietario/:id`; make `CarteraRepository` role-aware (call `/cuotas/propietario/{id}` when PROPIETARIO)
4. **Historial for Propietario** — add `PROPIETARIO` role to `GET /cuotas/propietario/:id` (already covered by #3)

### Out of Scope
- Filtering cuotas by etapa for Cobrador (showing ALL, same as ADMIN)
- New Historial features or UI changes
- Propietario info editing or profile management
- Any other role permission changes

## Capabilities

### New Capabilities
- `propietario-info`: Dashboard endpoint returns personal info (nombre, casa direccion, etapa) for propietario views

### Modified Capabilities
- `cartera`: Role access expanded from ADMIN-only to ADMIN + COBRADOR + PROPIETARIO; propietario uses filtered endpoint
- `historial`: Role access expanded to include PROPIETARIO (permission-only, no behavior change)

## Approach

**Backend**: Inject `PropietarioRepository` into `DashboardController`, load propietario→tenencia→casa chain, return `propietarioInfo` in dashboard response. Add `@Roles(COBRADOR)` and `@Roles(PROPIETARIO)` decorators to cuotas endpoints.

**Frontend**: `MiEstadoScreen` reads `propietarioInfo` from dashboard state. `CarteraRepository` checks user role: PROPIETARIO calls `/cuotas/propietario/{id}`, others call `/cuotas`. Router maps `/cartera` for COBRADOR and PROPIETARIO to `CarteraScreen`.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `apps/backend/src/ledger/infrastructure/controllers/dashboard.controller.ts` | Modified | Inject PropietarioRepository, return propietarioInfo |
| `apps/backend/src/ledger/infrastructure/controllers/cuotas.controller.ts` | Modified | Add COBRADOR + PROPIETARIO roles |
| `apps/mobile/lib/features/dashboard_propietario/mi_estado_screen.dart` | Modified | Replace 3 hardcoded strings with propietarioInfo |
| `apps/mobile/lib/app_router.dart` | Modified | Wire COBRADOR and PROPIETARIO to CarteraScreen |
| `apps/mobile/lib/features/cartera/cartera_repository.dart` | Modified | Role-aware endpoint selection |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Propietario without Tenencia/Casa (orphan data) | Low | Return null/empty strings; frontend handles gracefully |
| Role decorator conflicts with existing guards | Low | Test each role independently; existing ADMIN path unchanged |

## Rollback Plan

- Backend: revert `dashboard.controller.ts` and `cuotas.controller.ts` changes (git revert)
- Frontend: revert `mi_estado_screen.dart`, `app_router.dart`, `cartera_repository.dart`
- No database migrations involved — pure code changes

## Dependencies

- None (all changes use existing repositories and widgets)

## Success Criteria

- [ ] Propietario sees their real name and address in Mi Estado
- [ ] Cobrador can access Cartera and sees all cuotas
- [ ] Propietario can access Cartera and sees only their own cuotas
- [ ] Propietario can access Historial
- [ ] Admin flow remains unchanged
