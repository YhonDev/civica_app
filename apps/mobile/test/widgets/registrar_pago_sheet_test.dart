import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/features/auth/auth_cubit.dart';
import 'package:civica_pago_mobile/features/cartera/models/cartera_models.dart';
import 'package:civica_pago_mobile/features/cartera/widgets/registrar_pago_bottom_sheet.dart';

import 'fake_repositories.dart';

/// Texto real del campo de monto (lo que el cobrador ve, ya agrupado).
String _fieldText(WidgetTester tester) {
  final field = tester.widget<TextField>(
    find
        .descendant(
          of: find.byType(RegistrarPagoBottomSheet),
          matching: find.byType(TextField),
        )
        .first,
  );
  return field.controller!.text;
}

/// Último chip de la fila 1x/2x/3x/4x/Total es siempre "Total".
ChoiceChip _totalChip(WidgetTester tester) =>
    tester.widget<ChoiceChip>(find.byType(ChoiceChip).last);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.init(baseUrl: 'http://test.local');
  });

  Future<void> pumpSheet(
    WidgetTester tester, {
    CobroItem? cobro,
  }) async {
    // Viewport de un teléfono real: en el default del tester (800x600) el
    // sheet usa la rama tablet y otros rows se comportan distinto.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final authCubit = AuthCubit();
    addTearDown(authCubit.close);
    authCubit.emit(
      const AuthState.authenticated({
        'nombre': 'Admin Test',
        'rol': 'ADMIN',
        'email': 'admin@test.com',
        'tenantId': 't1',
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: Scaffold(
            body: RegistrarPagoBottomSheet(
              cobro:
                  cobro ??
                  FakeCarteraData.cobro(
                    id: 'C1',
                    nombre: 'Carlos Pendiente',
                    estado: 'Pendiente',
                    saldo: 60000,
                  ),
              // Los chips 1x/2x/3x/4x/Total solo se montan en modo
              // "Ver Deuda"; el modo rápido no los renderiza.
              initialQuickMode: false,
              onSuccess: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('abre prellenado con la primera cuota en formato global', (
    tester,
  ) async {
    await pumpSheet(tester);

    // Sin cuotas del backend, el sheet las deriva del saldo: 60.000 con la
    // cuota por defecto (40.000) genera 2 cuotas de 30.000 y preselecciona
    // la primera → el campo abre mostrando $ 30.000.
    expect(_fieldText(tester), '30.000');
  });

  testWidgets('escribir 10000 muestra 10.000 y deja Total sin seleccionar', (
    tester,
  ) async {
    await pumpSheet(tester);
    final montoField = find.byType(TextField).first;

    await tester.enterText(montoField, '10000');
    await tester.pump();

    // La máscara agrupa en vivo: el cobrador ve $ 10.000.
    expect(_fieldText(tester), '10.000');

    // 10.000 no coincide con ninguna selección derivada del saldo → el chip
    // Total queda sin seleccionar (el sheet se reconstruye en vivo vía
    // listener del controlador).
    expect(_totalChip(tester).selected, isFalse);
  });

  testWidgets('escribir el saldo exacto auto-selecciona el chip Total', (
    tester,
  ) async {
    await pumpSheet(tester);
    final montoField = find.byType(TextField).first;

    await tester.enterText(montoField, '60000');
    await tester.pump();

    expect(_fieldText(tester), '60.000');
    expect(_totalChip(tester).selected, isTrue);
  });

  testWidgets('tocar el chip Total escribe el saldo formateado en el campo', (
    tester,
  ) async {
    await pumpSheet(tester);

    await tester.tap(find.byType(ChoiceChip).last);
    await tester.pump();

    expect(_fieldText(tester), '60.000');
    expect(_totalChip(tester).selected, isTrue);
  });
}
