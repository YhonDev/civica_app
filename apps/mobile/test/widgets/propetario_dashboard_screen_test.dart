import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/core/network/local_cache_repository.dart';
import 'package:civica_pago_mobile/features/auth/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:civica_pago_mobile/features/dashboard_residente/residente_dashboard_screen.dart';

import '../unit/repositories/mock_http_adapter.dart';

/// Helper: build the screen wrapped in MaterialApp + AuthCubit
Widget buildTestScreen({String nombre = 'Juan Perez', String rol = 'PROPIETARIO'}) {
  final authCubit = AuthCubit();
  authCubit.emit(AuthState.authenticated({
    'id': 'user-1',
    'nombre': nombre,
    'rol': rol,
    'email': 'juan@test.com',
  }));
  return MaterialApp(
    home: BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: const ResidenteDashboardScreen(),
    ),
  );
}

/// Sets up mock API responses on the given [MockHttpAdapter].
///
/// Backend returns `proximoCobro` as a date string, `proximoPago` as a
/// complex object, and `ultimoPago` as a {monto, fecha} map.
void _mockDashboardApi(MockHttpAdapter adapter, {
  bool summarySuccess = true,
}) {
  adapter.onGet('/solicitudes', []);
  if (summarySuccess) {
    adapter.onGet('/dashboard/residente', {
      'saldo': 120000,
      'status': 'AL_DIA',
      'proximoCobro': '2026-08-01T00:00:00.000Z',
      'proximoPago': null,
      'tarifaActual': {'cuotaMensual': 40000, 'montoSegunFrecuencia': 40000, 'modalidad': 'MENSUAL'},
      'movimientos': [
        {
          'id': 'pago-1',
          'tipo': 'pago',
          'fecha': '2026-07-15T10:00:00Z',
          'monto': 40000,
          'concepto': 'Pago de cuota',
        },
      ],
    });
  } else {
    adapter.onGet('/dashboard/residente', {'message': 'Server error'}, statusCode: 500);
  }
}

void main() {
  late MockHttpAdapter mockAdapter;

  setUp(() {
    // Aislar el cache SWR (singleton global) entre tests
    LocalCacheRepository.instance.invalidateAll();
    ApiClient.init(
      baseUrl: 'http://test.local',
      connectTimeout: Duration.zero,
      receiveTimeout: Duration.zero,
      tokenStorage: TokenStorage(storage: InMemorySecureStorage()),
    );
    initializeDateFormatting('es');
    initializeDateFormatting('es_CO');

    // Replace the real HTTP adapter with our mock
    mockAdapter = MockHttpAdapter();
    ApiClient.setHttpClientAdapter(mockAdapter);
  });

  group('PropietarioDashboardScreen — header', () {
    testWidgets('displays user name from auth state', (tester) async {
      _mockDashboardApi(mockAdapter);
      await tester.pumpWidget(buildTestScreen(nombre: 'Maria Garcia'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Maria Garcia'), findsOneWidget);
    });

    testWidgets('displays single name correctly', (tester) async {
      _mockDashboardApi(mockAdapter);
      await tester.pumpWidget(buildTestScreen(nombre: 'Carlos'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Carlos'), findsOneWidget);
    });
  });

  group('PropietarioDashboardScreen — summary card', () {
    testWidgets('shows status badge from API response', (tester) async {
      _mockDashboardApi(mockAdapter);
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      // StatusBadge renders "Al día" for AL_DIA
      expect(find.text('Al día'), findsOneWidget);
    });

    testWidgets('shows header address from user data', (tester) async {
      _mockDashboardApi(mockAdapter);
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(find.text('Urbanización'), findsOneWidget);
    });
  });

  group('PropietarioDashboardScreen — timeline', () {
    testWidgets('shows timeline items from API response', (tester) async {
      _mockDashboardApi(mockAdapter);
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      // Pago item should be rendered
      expect(find.textContaining('Pago de cuota'), findsOneWidget);
    });
  });

  group('PropietarioDashboardScreen — error and empty states', () {
    testWidgets('handles API failure gracefully — no crash', (tester) async {
      _mockDashboardApi(mockAdapter, summarySuccess: false);
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      // Screen should render error state button
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });
}
