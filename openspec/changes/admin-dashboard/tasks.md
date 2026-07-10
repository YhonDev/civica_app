# Admin Dashboard — Tasks

## Task 1 — Tabla actividad + entidad TypeORM
- Crear migración SQL `005_actividad.sql`
- Crear entidad `Actividad` en `notifications/domain/`
- Crear `ActividadRepository` interface e implementación
- Integrar en módulo de Notifications

## Task 2 — Endpoint GET /dashboard/administrador
- Crear `DashboardQuery` use case con todas las agregaciones
- Crear `DashboardDto` de respuesta
- Crear `DashboardController`
- Registrar en módulo Ledger
- Probar con curl

## Task 3 — Registro automático de actividad
- Crear decorador `@RegistrarActividad`
- Aplicar en use cases: RegistrarPago, CrearPropietario
- Verificar que se insertan registros al hacer acciones

## Task 4 — Tema Flutter (Design System) ✅
- [x] `app_colors.dart`, `app_typography.dart`, `app_spacing.dart`
- [x] `app_theme.dart` con ThemeData personalizado
- [x] Aplicar en `main.dart`

## Task 5 — Componentes compartidos ✅
- [x] `kpi_card.dart` — tarjeta principal con título, monto, progress bar
- [x] `mini_stat_card.dart` — indicador compacto con icono
- [x] `month_selector.dart` — navegación ◄ ► + bottom sheet
- [x] `timeline_widget.dart` — feed vertical con puntos e íconos
- [x] `donut_chart.dart` — gráfico circular minimalista
- [x] `line_chart.dart` — gráfico de línea simple
- [x] `action_card.dart` — botón de acción rápida

## Task 6 — DashboardScreen + Cubit + Repository ✅
- [x] `DashboardRepository` con llamada a API
- [x] `DashboardCubit` con loadDashboard y changeMonth
- [x] `DashboardScreen` con MonthSelector + scroll sections
- [x] Secciones: Resumen, Evolución, Modalidades, EstadoCobros, Actividad, AccionesRápidas
- [ ] Bottom navigation integration (pendiente — depende de navegación general)
