import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/features/auth/auth_cubit.dart';
import 'package:civica_pago_mobile/features/cartera/cartera_screen.dart';
import 'fake_repositories.dart';

Widget createCarteraScreen({FakeCarteraRepository? repository}) {
  final authCubit = AuthCubit();
  authCubit.emit(AuthState.authenticated({
    'nombre': 'Admin Test', 'rol': 'ADMIN', 'email': 'admin@test.com',
    'tenantId': 't1',
  }));
  return MaterialApp(
    home: BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: CarteraScreen(repository: repository),
    ),
  );
}

/// _loadData() has 2 awaits (getCarteraResumen + getCobros)
/// plus setState + sliver rendering needs extra pumps.
/// _loadData() has 2 awaits (getCarteraResumen + getCobros)
/// plus setState + sliver rendering needs extra pumps.
Future<void> pumpFully(WidgetTester tester) async {
  await tester.pump(); // 1st microtask: getCarteraResumen
  await tester.pump(); // 2nd microtask: getCobros
  await tester.pump(); // setState
  await tester.pump(const Duration(milliseconds: 200)); // sliver layout
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.init(baseUrl: 'http://test.local');
    initializeDateFormatting('es');
    initializeDateFormatting('es_CO');
  });

  group('CarteraScreen — loaded state', () {
    testWidgets('header metrics', (tester) async {
      final repo = FakeCarteraData.conTresCuotas();
      await tester.pumpWidget(createCarteraScreen(repository: repo));
      await pumpFully(tester);

      // "Mora" may appear in BOTH the header and the filter chips
      expect(find.text('Por cobrar'), findsOneWidget);
      expect(find.text('Mora'), findsAtLeastNWidgets(1));
      expect(find.text('Recaudado'), findsOneWidget);
    });

    testWidgets('filter chips', (tester) async {
      final repo = FakeCarteraData.conTresCuotas();
      await tester.pumpWidget(createCarteraScreen(repository: repo));
      await pumpFully(tester);

      expect(find.textContaining('Pendientes'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Mora'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Pagadas'), findsOneWidget);
      // "Todas" aparece en 3 chips: "Todas (N)", "Todas las etapas" y
      // "Todas las manzanas" — se verifica el chip de estado por su Key.
      expect(find.byKey(const Key('filter_chip_TODOS')), findsOneWidget);
    });

    testWidgets('Pendiente filter', (tester) async {
      final repo = FakeCarteraData.conTresCuotas();
      await tester.pumpWidget(createCarteraScreen(repository: repo));
      await pumpFully(tester);

      await tester.tap(find.byKey(const Key('filter_chip_PENDIENTE')));
      await tester.pump();

      expect(find.text('Carlos Pendiente'), findsOneWidget);
      expect(find.text('Juan Pagado'), findsNothing);
      expect(find.text('Maria Mora'), findsNothing);
    });

    testWidgets('Mora filter', (tester) async {
      final repo = FakeCarteraData.conTresCuotas();
      await tester.pumpWidget(createCarteraScreen(repository: repo));
      await pumpFully(tester);

      await tester.tap(find.byKey(const Key('filter_chip_MORA')));
      await tester.pump();
      expect(find.text('Maria Mora'), findsOneWidget);
      expect(find.text('Carlos Pendiente'), findsNothing);
    });

    testWidgets('Todos filter exists and can be tapped', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeCarteraData.conTresCuotas();
      await tester.pumpWidget(createCarteraScreen(repository: repo));
      await pumpFully(tester);

      // Filter chips are rendered
      expect(find.byKey(const Key('filter_chip_PENDIENTE')), findsOneWidget);
      expect(find.byKey(const Key('filter_chip_MORA')), findsOneWidget);
      expect(find.byKey(const Key('filter_chip_PAGADO')), findsOneWidget);
      expect(find.byKey(const Key('filter_chip_TODOS')), findsOneWidget);

      // Can tap Todos filter chip
      await tester.tap(find.byKey(const Key('filter_chip_TODOS')));
      await tester.pump();

      // Todas filter displays all 3
      expect(find.text('Carlos Pendiente'), findsOneWidget);
      expect(find.text('Maria Mora'), findsOneWidget);
      expect(find.text('Juan Pagado'), findsOneWidget);
    });
  });

  group('CarteraScreen — empty state', () {
    testWidgets('EmptyState sin cobros', (tester) async {
      final repo = FakeCarteraData.vacio();
      await tester.pumpWidget(createCarteraScreen(repository: repo));
      await pumpFully(tester);
      expect(find.text('Sin registros'), findsOneWidget);
    });
  });
}
