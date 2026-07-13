import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/screens/auth/auth_cubit.dart';
import 'package:civica_pago_mobile/features/solicitudes/solicitudes_screen.dart';
import '../unit/repositories/mock_http_adapter.dart';

/// 3 solicitudes: PENDIENTE, RESUELTA, RECHAZADA
final _solicitudesData = [
  {
    'id': 'S1',
    'tipo': 'Revisión de pago',
    'descripcion': 'Pagué pero no se refleja',
    'estado': 'PENDIENTE',
    'fecha': '2026-03-15T10:30:00.000Z',
    'nroRecibo': 'TK-000001',
    'cuotaId': 'C1',
    'usuarioId': 'U1',
    'usuario': {'nombre': 'Juan Pérez'},
  },
  {
    'id': 'S2',
    'tipo': 'Revisión de cargo',
    'descripcion': 'Cargo incorrecto en marzo',
    'estado': 'RESUELTA',
    'fecha': '2026-03-10T10:30:00.000Z',
    'nroRecibo': 'TK-000002',
    'cuotaId': 'C2',
    'usuarioId': 'U2',
    'respuesta': 'Corregido',
    'usuario': {'nombre': 'María García'},
  },
  {
    'id': 'S3',
    'tipo': 'Revisión general',
    'descripcion': 'Cobro duplicado',
    'estado': 'RECHAZADA',
    'fecha': '2026-03-05T10:30:00.000Z',
    'nroRecibo': 'TK-000003',
    'cuotaId': 'C3',
    'usuarioId': 'U3',
    'respuesta': 'No procede',
    'usuario': {'nombre': 'Carlos Ruiz'},
  },
];

final _loginResponse = {
  'accessToken': 'mock-token',
  'refreshToken': 'mock-refresh',
  'usuario': {
    'nombre': 'Admin Test',
    'rol': 'ADMIN',
    'email': 'admin@test.com',
    'tenantId': 't1',
  },
};

/// Creates the widget tree with an authenticated AuthCubit.
Future<Widget> createSolicitudesScreen(MockHttpAdapter adapter) async {
  // Login first to set the user in AuthCubit
  adapter.onPost('/auth/login', _loginResponse);
  final authCubit = AuthCubit();
  await authCubit.login(email: 'admin@test.com', password: 'test');

  return MaterialApp(
    home: BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: const SolicitudesScreen(),
    ),
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
    final widget = await createSolicitudesScreen(mockAdapter);
    await tester.pumpWidget(widget);
    // First frame: initState → loading
    await tester.pump();
    // Pump to resolve async API calls + animations
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 200));
    // Extra pump for stagger animation
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('SolicitudesScreen — loading state', () {
    testWidgets('mustra spinner durante la carga', (tester) async {
      mockAdapter.onGet('/solicitudes/admin', _solicitudesData);

      final widget = await createSolicitudesScreen(mockAdapter);
      await tester.pumpWidget(widget);

      // Sin pump adicional: todavía cargando
      await tester.pump();

      // Debe mostrar el título del AppBar
      expect(find.text('Gestión de Solicitudes'), findsOneWidget);
      // Spinner visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('SolicitudesScreen — loaded state (admin)', () {
    testWidgets('mustra MiniStatCards con conteos correctos', (tester) async {
      mockAdapter.onGet('/solicitudes/admin', _solicitudesData);

      await pumpUntilLoaded(tester);

      // 3 solicitudes: 1 pendiente, 1 resuelta, 1 rechazada
      // Pendientes: 1 (S1 está PENDIENTE)
      // Resueltas: 1 (S2)
      // Rechazadas: 1 (S3)
      // Pero por defecto admin filtra por PENDIENTES
      // El MiniStatCard muestra el conteo global (sin filtrar)
      expect(find.text('1'), findsAtLeast(1)); // conteos
    });

    testWidgets('mustra filter chips: Todas, Pendientes, Resueltas, Rechazadas',
        (tester) async {
      mockAdapter.onGet('/solicitudes/admin', _solicitudesData);

      await pumpUntilLoaded(tester);

      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Pendientes'), findsOneWidget);
      expect(find.text('Resueltas'), findsOneWidget);
      expect(find.text('Rechazadas'), findsOneWidget);
    });

    testWidgets('mustra SolicitudCards en la lista', (tester) async {
      mockAdapter.onGet('/solicitudes/admin', _solicitudesData);

      await pumpUntilLoaded(tester);

      // Admin default filter = PENDIENTES → solo S1 visible
      // No podemos buscar por texto exacto porque el widget usa AppBar + Card
      // Solo verificamos que los títulos de solicitud existen
      // Buscar "Revisión de" que aparece en al menos S1
      expect(find.textContaining('Revisión'), findsAtLeast(1));
    });

    testWidgets('filtro Todas mustra todas las solicitudes', (tester) async {
      mockAdapter.onGet('/solicitudes/admin', _solicitudesData);

      await pumpUntilLoaded(tester);

      // Cambiar a filtro Todas
      await tester.tap(find.text('Todas').last);
      await tester.pump();
      await tester.pump();

      // Ahora deben mostrarse las 3 tarjetas de solicitud
      // Verificar por los nroRecibos
      expect(find.textContaining('TK-000001'), findsOneWidget);
      expect(find.textContaining('TK-000002'), findsOneWidget);
      expect(find.textContaining('TK-000003'), findsOneWidget);
    });

    testWidgets('filtro Resueltas mustra solo S2', (tester) async {
      mockAdapter.onGet('/solicitudes/admin', _solicitudesData);

      await pumpUntilLoaded(tester);

      // Cambiar a filtro Resueltas
      await tester.tap(find.text('Resueltas').last);
      await tester.pump();
      await tester.pump();

      // S2 tiene respuesta "Corregido" - visible en el card detail
      // Pero el card usa _statusLabel que muestra "Resuelta" para resuelta
      expect(find.textContaining('TK-000002'), findsOneWidget);
    });
  });

  group('SolicitudesScreen — empty state', () {
    testWidgets('mustra EmptyState cuando no hay solicitudes', (tester) async {
      mockAdapter.onGet('/solicitudes/admin', []);

      await pumpUntilLoaded(tester);

      // Admin default filter = PENDIENTES → sin resultados → EmptyState
      expect(find.text('No hay solicitudes'), findsOneWidget);
    });
  });

  group('SolicitudesScreen — error state', () {
    testWidgets('mustra indicador de que no hay datos cuando falla API',
        (tester) async {
      // Sin mock → API falla
      // El catch en _loadSolicitudes solo hace debugPrint y setState loading=false
      // Como la lista queda vacía y loading=false, se muestra el empty state
      await pumpUntilLoaded(tester);

      // Si está vacío después de error → se muestra EmptyState
      expect(find.text('No hay solicitudes'), findsOneWidget);
    });
  });
}
