import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/features/cartera/cartera_screen.dart';
import 'fake_repositories.dart';

Widget createCarteraScreen({FakeCarteraRepository? repository}) {
  return MaterialApp(
    home: CarteraScreen(repository: repository),
  );
}

/// _loadData() has 2 awaits (getCarteraResumen + getCobros).
/// Each await + setState rebuild needs a pump.
Future<void> pumpFully(WidgetTester tester) async {
  await tester.pump(); // 1st microtask: getCarteraResumen
  await tester.pump(); // 2nd microtask: getCobros + setState + rebuild
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

      // "Mora" appears in BOTH the header and the filter chips
      // Use atLeast to handle the multi-match
      expect(find.text('Por cobrar'), findsOneWidget);
      expect(find.text('Mora'), findsAtLeastNWidgets(1));
      expect(find.text('Recaudado'), findsOneWidget);
    });

    testWidgets('filter chips', (tester) async {
      final repo = FakeCarteraData.conTresCuotas();
      await tester.pumpWidget(createCarteraScreen(repository: repo));
      await pumpFully(tester);

      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.text('Mora'), findsAtLeastNWidgets(1)); // header + chip
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

    testWidgets('Todos filter', (tester) async {
      final repo = FakeCarteraData.conTresCuotas();
      await tester.pumpWidget(createCarteraScreen(repository: repo));
      await pumpFully(tester);

      await tester.tap(find.text('Todos').last);
      await tester.pump();
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
