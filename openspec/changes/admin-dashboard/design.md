# Admin Dashboard — Design

## Backend Architecture

### New Files

```
src/ledger/application/queries/dashboard.query.ts
src/ledger/application/dtos/dashboard.dto.ts
src/ledger/infrastructure/controllers/dashboard.controller.ts
src/notifications/domain/actividad.entity.ts
src/notifications/domain/actividad.repository.ts
src/notifications/infrastructure/actividad.repository.impl.ts
src/shared/common/decorators/registrar-actividad.decorator.ts
```

### DashboardQuery

Use case que recibe `(mes, anio, tenantId)` y retorna `DashboardResponse`.

**Resumen**: 
- `recaudoTotal`: `SUM(pago.monto)` WHERE pago.fechaPago BETWEEN mes
- `metaMensual`: `SUM(cuota.monto)` WHERE cuota.pertenece al período
- `pagaron`: COUNT DISTINCT propietarioId con pagos en el mes
- `pendientes`: COUNT DISTINCT propietarioId con cuotas activas sin pago completo
- `moraTotal`: SUM(cuota.saldo) WHERE cuota.estado = VENCIDA

**Evolución**: `GROUP BY fechaPago::date ORDER BY fechaPago`

**Modalidades**: JOIN tarifa ON cuota.tarifaId, agrupar por frecuencia

**Estado cobros**: Porcentaje cuotas PAGADA / PARCIAL+PENDIENTE / VENCIDA

### Actividad Table

Entidad TypeORM con migración. Se inserta automáticamente desde use cases clave mediante decorador o servicio.

### Decorador @RegistrarActividad

```typescript
@RegistrarActividad({ tipo: 'PAGO', descripcion: (result) => `${result.usuario} registró un pago` })
```

Usar un decorador de método o un EventSubscriber en los use cases.

---

## Flutter Architecture

### New Files

```
lib/core/theme/app_theme.dart
lib/core/theme/app_colors.dart
lib/core/theme/app_typography.dart
lib/core/theme/app_spacing.dart
lib/shared/widgets/kpi_card.dart
lib/shared/widgets/mini_stat_card.dart
lib/shared/widgets/timeline_widget.dart
lib/shared/widgets/donut_chart.dart
lib/shared/widgets/line_chart.dart
lib/shared/widgets/month_selector.dart
lib/shared/widgets/action_card.dart
lib/features/dashboard/dashboard_screen.dart
lib/features/dashboard/dashboard_cubit.dart
lib/features/dashboard/dashboard_repository.dart
lib/features/dashboard/widgets/resumen_section.dart
lib/features/dashboard/widgets/evolucion_section.dart
lib/features/dashboard/widgets/modalidades_section.dart
lib/features/dashboard/widgets/estado_cobros_section.dart
lib/features/dashboard/widgets/actividad_section.dart
lib/features/dashboard/widgets/acciones_rapidas_section.dart
```

### Component Tree

```
DashboardScreen
├── MonthSelector (◄ Agosto 2026 ►)
├── SingleChildScrollView
│   ├── ResumenSection
│   │   ├── KpiCard (Recaudo del Mes)
│   │   └── Row
│   │       ├── MiniStatCard (Pagaron)
│   │       ├── MiniStatCard (Pendientes)
│   │       └── MiniStatCard (Mora)
│   ├── EvolucionSection
│   │   └── LineChart
│   ├── Row
│   │   ├── ModalidadesSection
│   │   │   └── ListView de ModalidadCard
│   │   └── EstadoCobrosSection
│   │       └── DonutChart
│   ├── ActividadSection
│   │   └── TimelineWidget
│   └── AccionesRapidasSection
│       └── ListView de ActionCard
```

### State Management (Cubit)

```
DashboardCubit
├── loadDashboard(mes, anio)
├── changeMonth(mes, anio)
├── state: DashboardState
│   ├── loading
│   ├── loaded(DashboardData)
│   └── error(String)
```

### Repository

```
DashboardRepository
├── getDashboard(mes, anio) → Future<DashboardResponse>
└── httpClient: ApiClient
```

### Charts

**LineChart**: Custom painter minimalista. Una línea azul. Ejes simples. Sin grid pesado.

**DonutChart**: Custom painter. Arcos con colores semánticos. Porcentaje en el centro.

### Theme Integration

```dart
ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,     // #2563EB
      surface: AppColors.background,  // #F8FAFC
      // ...
    ),
    textTheme: AppTypography.textTheme,
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      // ...
    ),
  );
}
```
