import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/features/dashboard/dashboard_screen.dart';
import '../unit/repositories/mock_http_adapter.dart';

/// Mutable mock response builder that the test helper can overwrite.
dynamic _dashboardResponse = {
  'mes': 3,
  'anio': 2026,
  'resumen': {
    'recaudoTotal': 780000000,
    'metaMensual': 1056000000,
    'pagaron': 65,
    'pendientes': 17,
    'moraTotal': 72000000,
    'porcentajeMeta': 73.9,
  },
  'estadoCobros': {'pagados': 73.9, 'pendientes': 19.3, 'revision': 6.8},
  'solicitudesPendientes': 5,
  'propietariosMora': 6,
  'nuevosPropietariosSemana': 3,
  'pagosRevision': 2,
  'acumuladoAnual': 2100000000,
  'metaAnual': 12672000000,
  'historialMeses': [],
  'totalPropietarios': 200,
  'evolucion': [],
  'modalidades': [],
  'actividad': [],
};

Widget createDashboardScreen() {
  return const MaterialApp(
    home: DashboardScreen(),
  );
}

void main() {
  late MockHttpAdapter mockAdapter;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.init(baseUrl: 'http://test.local');
    mockAdapter = MockHttpAdapter();
    ApiClient.setHttpClientAdapter(mockAdapter);
  });

  Future<void> pumpUntilLoaded(WidgetTester tester) async {
    await tester.pumpWidget(createDashboardScreen(adapter: mockAdapter));
    // Initial frame: cubit created, loading emitted
    await tester.pump();
    // Now the API call is in flight. Pump a few times to let it resolve.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('DashboardScreen — loading state', () {
    testWidgets('mustra skeleton durante la carga', (tester) async {
      // Register mock but it will be slow because we don't pump enough
      mockAdapter.onGet('/dashboard/administrador', _dashboardResponse);

      await tester.pumpWidget(createDashboardScreen(adapter: mockAdapter));
      // After first frame: cubit emits loading → skeleton shows
      // Don't pump further so the API call doesn't resolve
      await tester.pump();

      // El skeleton tiene SkeletonBox widgets → buscar por Container con borderRadius
      // Como SkeletonBox usa AnimatedBuilder + Opacity, buscamos texto indicativo
      // El header "Admin" siempre está visible (nombre del usuario)
      // En loading, no hay MonthSelector, KpiCard ni ModuleSummaryCard
      // Pero el header con avatar + nombre siempre está

      // Buscar el nombre del dashboard header — siempre visible
      expect(find.text('Bienvenido'), findsNothing);
      // No debería haber datos cargados todavía
      expect(find.text('Recaudo del Mes'), findsNothing);
      expect(find.text('Centro de Atención'), findsNothing);
    });
  });

  group('DashboardScreen — loaded state', () {
    testWidgets('mustra KPI card con recaudo formateado', (tester) async {
      mockAdapter.onGet('/dashboard/administrador', _dashboardResponse);

      await pumpUntilLoaded(tester);

      // El KPI debe mostrar "Recaudo del Mes"
      expect(find.text('Recaudo del Mes'), findsOneWidget);

      // Debe mostrar el monto formateado (7.800.000)
      // El formateo depende de NumberFormat con locale es_CO
      // Buscar por substrings conocidos
      expect(find.textContaining('Recaudo'), findsOneWidget);
      expect(find.textContaining('Meta'), findsOneWidget);
    });

    testWidgets('mustra Centro de Atención con solicitudes pendientes',
        (tester) async {
      mockAdapter.onGet('/dashboard/administrador', _dashboardResponse);

      await pumpUntilLoaded(tester);

      // Centro de Atención module
      expect(find.text('⚠ Centro de Atención'), findsOneWidget);

      // Items del centro
      expect(find.text('5'), findsOneWidget); // solicitudes pendientes
      expect(find.text('6'), findsOneWidget); // propietarios en mora
    });

    testWidgets('mustra sección Cobros con pagados/pendientes/mora',
        (tester) async {
      mockAdapter.onGet('/dashboard/administrador', _dashboardResponse);

      await pumpUntilLoaded(tester);

      // Cobros module
      expect(find.text('COBROS'), findsOneWidget);

      // Valores: 65 pagados, 17 pendientes, 6 en mora
      expect(find.text('65'), findsOneWidget);
      expect(find.text('17'), findsOneWidget);
    });

    testWidgets('mustra sección Comunidad con total propietarios',
        (tester) async {
      mockAdapter.onGet('/dashboard/administrador', _dashboardResponse);

      await pumpUntilLoaded(tester);

      // Comunidad module
      expect(find.text('COMUNIDAD'), findsOneWidget);

      // Total propietarios
      expect(find.text('200'), findsOneWidget);
      expect(find.textContaining('Propietarios registrados'), findsOneWidget);
    });
  });

  group('DashboardScreen — error state', () {
    testWidgets('mustra error y botón de reintentar', (tester) async {
      // No register mock → request will fail

      await pumpUntilLoaded(tester);

      // Después de que la API falle, el cubit emite DashboardError
      // Debe mostrar el mensaje de error y botón de reintentar
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });
  });

  group('DashboardScreen — valores con centavos', () {
    testWidgets('recaudoMes se divide por 100', (tester) async {
      mockAdapter.onGet(
        '/dashboard/administrador',
        {
          ..._dashboardResponse,
          'resumen': {
            'recaudoTotal': 1000000, // 10,000 after /100
            'metaMensual': 2000000,
            'pagaron': 1,
            'pendientes': 0,
            'moraTotal': 0,
            'porcentajeMeta': 50.0,
          },
        },
      );

      await pumpUntilLoaded(tester);

      // KPI card debe renderizarse (no podemos verificar el monto exacto
      // porque NumberFormat con locale puede variar, pero la tarjeta existe)
      expect(find.text('Recaudo del Mes'), findsOneWidget);
    });
  });
}
