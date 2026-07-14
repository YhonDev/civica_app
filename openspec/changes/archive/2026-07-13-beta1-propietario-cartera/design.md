# Design: beta1-propietario-cartera

## Technical Approach

Four surgical changes to make the mobile app functional for Beta1: inject real propietario data into the dashboard, open cuota endpoints to COBRADOR/PROPIETARIO roles, make the frontend router and repository role-aware, and fix historial access. No database migrations. All changes follow existing NestJS + Flutter patterns.

## Architecture Decisions

### Decision: PropietarioInfo data source

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Raw SQL in DashboardController | Fast, no DI changes, but breaks pattern | ✗ |
| New method in PropietarioRepository | Clean DI, but adds to community module | ✓ |
| Reuse CuotaRepository `findByPropietario` | Already loads propietario, but no tenencias relations | ✗ |

**Choice**: Add `findByIdWithRelations(id)` to PropietarioRepository (loads tenencias→casa→manzana→etapa). Inject PropietarioRepository into DashboardController.

**Rationale**: Follows existing repository pattern. DashboardController already uses DataSource for raw queries, but a repository method is cleaner and reusable.

### Decision: CarteraRepository role dispatch

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Inject AuthCubit into repository | Tight coupling to Flutter Bloc | ✗ |
| Static global user state (like ComunidadRepository) | Existing pattern, but implicit | ✓ |
| Pass role/propietarioId as method params | Explicit, but changes all call sites | ✗ |

**Choice**: Accept `role` and `propietarioId` as optional constructor params on CarteraRepository. CarteraScreen reads from AuthCubit and passes them.

**Rationale**: Explicit over implicit. Keeps repository testable. Minimal call-site changes (only CarteraScreen constructor).

### Decision: Endpoint role gating

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Separate endpoints per role | Clean separation, more routes | ✗ |
| Add roles to existing endpoints | Minimal change, single endpoint | ✓ |

**Choice**: Add `@Roles(RolUsuario.COBRADOR)` to `GET /cuotas` and `@Roles(RolUsuario.PROPIETARIO)` to `GET /cuotas/propietario/:id`.

**Rationale**: Matches spec. Cobrador sees all cuotas (same as admin). Propietario sees only their own.

## Data Flow

### PropietarioInfo flow:

```
AuthCubit.state.usuario['propietarioId']
    │
    ▼
GET /dashboard/propietario
    │
    ▼
DashboardController.getDashboardPropietario()
    │
    ├── PropietarioRepository.findByIdWithRelations(propietarioId)
    │       └── Returns: Propietario { tenencias: [{ casa: { manzana: { etapa } } }] }
    │
    └── Returns: { saldo, status, ..., propietarioInfo: { nombre, casaDireccion, etapaNombre } }
                │
                ▼
mi_estado_screen.dart parses propietarioInfo
    └── Replaces hardcoded 'Urb. San Sebastián', 'Mz. A, Casa 1', 'Casa 101'
```

### Cartera role-aware flow:

```
AuthCubit.state.usuario['rol'] + ['propietarioId']
    │
    ▼
CarteraScreen (reads AuthCubit)
    │
    ▼
CarteraRepository(role: rol, propietarioId: propId)
    │
    ├── PROPIETARIO → GET /cuotas/propietario/:id
    └── COBRADOR/ADMIN → GET /cuotas
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `apps/backend/src/community/infrastructure/propietario.repository.ts` | Modify | Add `findByIdWithRelations(id)` method loading tenencias→casa→manzana→etapa |
| `apps/backend/src/ledger/infrastructure/controllers/dashboard.controller.ts` | Modify | Inject PropietarioRepository, add `propietarioInfo` to propietario dashboard response |
| `apps/backend/src/ledger/infrastructure/controllers/cuotas.controller.ts` | Modify | Add `COBRADOR` role to `GET /cuotas`, add `PROPIETARIO` role to `GET /cuotas/propietario/:id` |
| `apps/mobile/lib/features/cartera/cartera_repository.dart` | Modify | Add role/propietarioId constructor params, branch endpoint selection by role |
| `apps/mobile/lib/features/cartera/cartera_screen.dart` | Modify | Read role/propietarioId from AuthCubit, pass to CarteraRepository |
| `apps/mobile/lib/features/dashboard_propietario/mi_estado_screen.dart` | Modify | Parse `propietarioInfo` from API response, replace 3 hardcoded strings |

## Interfaces / Contracts

### Backend: New PropietarioRepository method

```typescript
async findByIdWithRelations(id: string): Promise<Propietario | null> {
  return this.repo.findOne({
    where: { id },
    relations: {
      tenencias: {
        casa: {
          manzana: {
            etapa: true,
          },
        },
      },
    },
  });
}
```

### Backend: New propietarioInfo in dashboard response

```typescript
// Added to GET /dashboard/propietario return object
propietarioInfo: {
  nombre: propietario?.nombre ?? '',
  casaDireccion: casa ? `${casa.direccionInterna}, Mz. ${manzana.nombre}` : '',
  etapaNombre: etapa?.nombre ?? '',
}
```

### Frontend: CarteraRepository constructor change

```dart
CarteraRepository({
  ApiClient? apiClient,
  String? role,
  String? propietarioId,
})
```

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Unit | CarteraRepository role dispatch | Mock ApiClient, verify correct endpoint called for each role |
| Integration | Dashboard propietarioInfo | Seed DB with propietario+tenencia+casa, call endpoint, assert fields |
| Integration | Cuotas endpoint role gating | Authenticate as each role, verify 200/403 responses |
| E2E | Full propietario flow | Login as PROPIETARIO, navigate dashboard → verify real address shown |
| E2E | Full cobrador cartera flow | Login as COBRADOR, navigate to cartera → verify cuotas load |

## Migration / Rollout

No migration required. All changes are API contract additions and frontend routing fixes. Backend responses add new fields (non-breaking). Role changes are additive (expand access, don't restrict).

## Open Questions

- [ ] Should `CarteraScreen` subtitle text change based on role? (e.g., "Tus cuotas" for PROPIETARIO vs "Administración de cobros" for COBRADOR/ADMIN)
- [ ] Should the PROPIETARIO cartera view hide the "Registrar Pago" action since propietarios don't collect payments?
