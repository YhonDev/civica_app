import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/screens/auth/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:civica_pago_mobile/features/dashboard_propietario/propietario_dashboard_screen.dart';

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
      child: const PropietarioDashboardScreen(),
    ),
  );
}

/// Sets up mock API responses on the given [MockHttpAdapter].
///
/// Backend returns `proximoCobro` as a date string, `proximoPago` as a
/// complex object, and `ultimoPago` as a {monto, fecha} map.
void _mockDashboardApi(MockHttpAdapter adapter, {
  bool summarySuccess = true,
  bool timelineSuccess = true,
}) {
  if (summarySuccess) {
    adapter.onGet('/dashboard/propietario', {
      'saldo': 120000,
      'status': 'AL_DIA',
      'proximoCobro': '2026-08-01',   // string — just the date
      'proximoPago': null,
      'tarifaActual': {'cuotaMensual': 40000, 'montoSegunFrecuencia': 40000, 'frecuencia': 'MENSUAL'},
      'ultimoPago': {'monto': 40000, 'fecha': '2026-07-01'},
      'movimientos': [],
      'propietarioInfo': {'nombre': 'Juan Perez', 'casaDireccion': 'Casa 101', 'etapaNombre': 'Etapa Alfa'},
    });
  } else {
    adapter.onGet('/dashboard/propietario', {'message': 'Server error'}, statusCode: 500);
  }

  if (timelineSuccess) {
    adapter.onGet('/dashboard/propietario/timeline', {
      'items': [
        {
          'id': 'pago-1',
          'type': 'PAGO',
          'date': '2026-07-15',
          'monto': 400,
          'description': 'Pago de cuota',
          'estado': 'PAGADO',
        },
        {
          'id': 'sol-1',
          'type': 'SOLICITUD',
          'date': '2026-07-10T14:00:00Z',
          'monto': null,
          'description': 'Solicita cobro en casa',
          'estado': 'EN_REVISION',
        },
      ],
      'hasMore': false,
    });
  } else {
    adapter.onGet('/dashboard/propietario/timeline', {'message': 'Server error'}, statusCode: 500);
  }
}

void main() {
  late MockHttpAdapter mockAdapter;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.init(baseUrl: 'http://test.local');
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

    testWidgets('shows propietario address from API response', (tester) async {
      _mockDashboardApi(mockAdapter);
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(find.text('Casa 101'), findsOneWidget);
      expect(find.text('Etapa Alfa'), findsOneWidget);
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
      // Solicitud item should be rendered
      expect(find.textContaining('Solicita cobro en casa'), findsOneWidget);
    });
  });

  group('PropietarioDashboardScreen — error and empty states', () {
    testWidgets('shows empty state when timeline returns no items', (tester) async {
      mockAdapter.onGet('/dashboard/propietario', {
        'saldo': 0,
        'status': 'AL_DIA',
        'proximoCobro': null,
        'proximoPago': null,
        'tarifaActual': null,
        'ultimoPago': null,
        'movimientos': [],
        'propietarioInfo': {'nombre': 'Test', 'casaDireccion': '', 'etapaNombre': ''},
      });
      mockAdapter.onGet('/dashboard/propietario/timeline', {
        'items': [],
        'hasMore': false,
      });

      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      expect(find.text('Sin actividad reciente'), findsOneWidget);
    });

    testWidgets('handles API failure gracefully — no crash', (tester) async {
      _mockDashboardApi(mockAdapter, summarySuccess: false, timelineSuccess: false);
      await tester.pumpWidget(buildTestScreen());
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      // Screen should still be rendered (not crashed)
      expect(find.byType(PropietarioDashboardScreen), findsOneWidget);
    });
  });
}
