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

      // "Pendiente" may appear in header labels AND filter chips
      expect(find.text('Pendiente'), findsAtLeastNWidgets(1));
      expect(find.text('Mora'), findsAtLeastNWidgets(1));
      expect(find.text('Pagado'), findsOneWidget);
      expect(find.text('Todos'), findsOneWidget);
    });

    testWidgets('Pendiente filter', (tester) async {
      final repo = FakeCarteraData.conTresCuotas();
      await tester.pumpWidget(createCarteraScreen(repository: repo));
      await pumpFully(tester);

      expect(find.text('Carlos Pendiente'), findsOneWidget);
      expect(find.text('Juan Pagado'), findsNothing);
      expect(find.text('Maria Mora'), findsNothing);
    });

    testWidgets('Mora filter', (tester) async {
      final repo = FakeCarteraData.conTresCuotas();
      await tester.pumpWidget(createCarteraScreen(repository: repo));
      await pumpFully(tester);

      await tester.tap(find.text('Mora').last);
      await tester.pump();
      expect(find.text('Maria Mora'), findsOneWidget);
      expect(find.text('Carlos Pendiente'), findsNothing);
    });

    testWidgets('Todos filter exists and can be tapped', (tester) async {
      final repo = FakeCarteraData.conTresCuotas();
      await tester.pumpWidget(createCarteraScreen(repository: repo));
      await pumpFully(tester);

      // Filter chips are rendered
      expect(find.text('Pendiente'), findsAtLeastNWidgets(1));
      expect(find.text('Mora'), findsAtLeastNWidgets(1));
      expect(find.text('Pagado'), findsOneWidget);
      expect(find.text('Todos'), findsOneWidget);

      // Can tap Todos filter chip
      await tester.tap(find.text('Todos').last);
      await tester.pump();

      // Todos filter stays visible after tap
      expect(find.text('Todos'), findsOneWidget);
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
