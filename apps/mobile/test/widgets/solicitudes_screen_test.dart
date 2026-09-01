import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/features/auth/auth_cubit.dart';
import 'package:civica_pago_mobile/features/solicitudes/solicitudes_screen.dart';
import 'fake_repositories.dart';

AuthCubit _authCubitAdmin() {
  final cubit = AuthCubit();
  cubit.emit(AuthState.authenticated({
    'nombre': 'Admin Test', 'rol': 'ADMIN', 'email': 'admin@test.com',
    'tenantId': 't1',
  }));
  return cubit;
}

Widget createSolicitudesScreen({
  required AuthCubit authCubit,
  FakeSolicitudesRepository? repository,
}) {
  return MaterialApp(
    home: BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: SolicitudesScreen(repository: repository),
    ),
  );
}

/// Pumps enough for _loadSolicitudes (1 await) + stagger animations (3×80ms + 250ms).
Future<void> pumpFully(WidgetTester tester) async {
  await tester.pump(); // Process getSolicitudes + setState
  await tester.pump(const Duration(milliseconds: 500)); // Let stagger complete
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.init(baseUrl: 'http://test.local');
    initializeDateFormatting('es');
    initializeDateFormatting('es_CO');
  });

  group('SolicitudesScreen — loaded state', () {
    testWidgets('filter chips', (tester) async {
      final repo = FakeSolicitudesData.conTresSolicitudes();
      final auth = _authCubitAdmin();

      await tester.pumpWidget(createSolicitudesScreen(authCubit: auth, repository: repo));
      await pumpFully(tester);

      // Some labels appear in BOTH MiniStatCards and filter chips
      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Pendientes'), findsAtLeastNWidgets(1));
      expect(find.text('Resueltas'), findsAtLeastNWidgets(1));
      expect(find.text('Rechazadas'), findsAtLeastNWidgets(1));
    });

    testWidgets('Todas filter exists and can be tapped', (tester) async {
      final repo = FakeSolicitudesData.conTresSolicitudes();
      final auth = _authCubitAdmin();

      await tester.pumpWidget(createSolicitudesScreen(authCubit: auth, repository: repo));
      await pumpFully(tester);

      // Filter chips are rendered
      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Pendientes'), findsAtLeastNWidgets(1));
      expect(find.text('Resueltas'), findsAtLeastNWidgets(1));
      expect(find.text('Rechazadas'), findsAtLeastNWidgets(1));

      // Can tap Todas and Resueltas filter chips
      await tester.tap(find.text('Todas').last);
      await tester.pump();
      await tester.tap(find.text('Resueltas').last);
      await tester.pump();

      expect(find.text('Todas'), findsOneWidget);
      expect(find.text('Resueltas'), findsAtLeastNWidgets(1));
    });
  });

  group('SolicitudesScreen — empty state', () {
    testWidgets('muestra EmptyState sin solicitudes', (tester) async {
      final repo = FakeSolicitudesData.vacio();
      final auth = _authCubitAdmin();

      await tester.pumpWidget(createSolicitudesScreen(authCubit: auth, repository: repo));
      await pumpFully(tester);

      expect(find.text('No hay solicitudes'), findsOneWidget);
    });
  });

  group('SolicitudesScreen — error state', () {
    testWidgets('muestra EmptyState cuando falla API', (tester) async {
      final repo = FakeSolicitudesData.error();
      final auth = _authCubitAdmin();

      await tester.pumpWidget(createSolicitudesScreen(authCubit: auth, repository: repo));
      await pumpFully(tester);

      expect(find.text('No hay solicitudes'), findsOneWidget);
    });
  });
}
