import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/features/auth/auth_cubit.dart';
import 'package:civica_pago_mobile/features/cartera/models/cartera_models.dart';
import 'package:civica_pago_mobile/features/cartera/widgets/registrar_pago_bottom_sheet.dart';

import 'fake_repositories.dart';

/// Sonda de diseño: mide la geometría real del sheet en tablet y desktop
/// (ancho de contenido, centrado, gutters) y verifica la máscara en vivo
/// junto con el chip Total a través del path real de showModalBottomSheet.
///
/// Un fallo aquí significa que el contrato visual del sheet se rompió:
/// contenido > maxFormWidth, fuera de centro, o gutters desiguales.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.init(baseUrl: 'http://test.local');
  });

  ChoiceChip totalChipOf(WidgetTester tester) =>
      tester.widget<ChoiceChip>(find.byType(ChoiceChip).last);

  String montoText(WidgetTester tester) {
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

  Future<void> pumpViaShow(
    WidgetTester tester, {
    required Size screen,
    bool keyboard = false,
    CobroItem? cobro,
  }) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    tester.view.viewInsets = keyboard
        ? const FakeViewPadding(bottom: 280)
        : FakeViewPadding.zero;
    // reset() revierte physicalSize, dpr e insets de una sola vez.
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
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );

    // Path real de presentación (modal), no montaje directo del widget.
    final context = tester.element(find.byType(Scaffold));
    // ignore: unawaited_futures
    RegistrarPagoBottomSheet.show(
      context,
      cobro:
          cobro ??
          FakeCarteraData.cobro(
            id: 'C1',
            nombre: 'Carlos Pendiente',
            estado: 'Pendiente',
            saldo: 60000,
          ),
      initialQuickMode: false,
      onSuccess: () {},
    );
    await tester.pumpAndSettle();
  }

  /// (nombre, tamaño de pantalla, gutter izquierdo esperado)
  final cases = <(String, Size, double)>[
    ('teléfono base', const Size(390, 844), 20),
    ('tablet (820px)', const Size(820, 1180), (820 - 440) / 2),
    ('desktop (1440px)', const Size(1440, 900), (1440 - 440) / 2),
  ];

  for (final (nombre, screen, expectedLeft) in cases) {
    testWidgets('[$nombre] contenido ≤ 440, centrado y máscara viva', (
      tester,
    ) async {
      await pumpViaShow(tester, screen: screen);

      // El contenido interno (Column con header/tabs) no supera 440px.
      final content = tester.getRect(find.descendant(
        of: find.byType(RegistrarPagoBottomSheet),
        matching: find.byType(Column),
      ).first);
      expect(content.width, lessThanOrEqualTo(440.0),
          reason: '$nombre: el contenido se estira más allá de maxFormWidth');

      // Los gutters izquierdo y derecho son simétricos (centrado real),
      // y ≥ 20px (screenPadding) en tablet/desktop.
      final left = content.left;
      final right = screen.width - content.right;
      expect(left, closeTo(expectedLeft, 0.5),
          reason: '$nombre: gutter izquierdo $left ≠ esperado $expectedLeft');
      expect(right, closeTo(left, 0.5),
          reason: '$nombre: asimétrico — izq $left vs der $right');
      expect(left, greaterThanOrEqualTo(20.0),
          reason: '$nombre: el modal pega el contenido al borde');

      // Máscara en vivo: escribir 10000 muestra 10.000.
      final field = find.byType(TextField).first;
      await tester.enterText(field, '10000');
      await tester.pumpAndSettle();
      expect(montoText(tester), '10.000',
          reason: '$nombre: la máscara no agrupa en vivo');

      // El chip Total refleja el monto en vivo (listener del controlador):
      // 10.000 ≠ 60.000 → sin seleccionar.
      expect(totalChipOf(tester).selected, isFalse,
          reason: '$nombre: chip Total inconsistent con 10.000');
    });
  }

  testWidgets('[desktop] máscara + chip Total con teclado visible', (
    tester,
  ) async {
    await pumpViaShow(
      tester,
      screen: const Size(1440, 900),
      keyboard: true,
    );

    final field = find.byType(TextField).first;
    await tester.enterText(field, '60000');
    await tester.pumpAndSettle();

    // Con viewInsets reales, el sheet sigue montado y usable (no lo sepulta
    // el teclado en desktop donde hay espacio).
    final sheet = find.byType(RegistrarPagoBottomSheet);
    expect(sheet, findsOneWidget);
    expect(tester.getRect(sheet).top, greaterThanOrEqualTo(0));
    expect(montoText(tester), '60.000');
    expect(totalChipOf(tester).selected, isTrue,
        reason: 'con teclado: el chip Total no reflejó el monto exacto');
  });

  testWidgets('[tablet] header y tabs no desbordan a 820px', (tester) async {
    await pumpViaShow(tester, screen: const Size(820, 1180));

    // Sin RenderFlex overflow (pumpAndSettle habría propagado la excepción)
    // y el drag handle queda centrado sobre el contenido, no sobre la pantalla.
    final handle = tester.getCenter(find.descendant(
      of: find.byType(RegistrarPagoBottomSheet),
      matching: find.byType(Container),
    ).first);
    final sheet = tester.getCenter(find.byType(RegistrarPagoBottomSheet));
    expect((handle.dx - sheet.dx).abs(), lessThan(2.0),
        reason: 'el drag handle no está centrado sobre el contenido');
  });

  testWidgets('[desktop] nombre largo de residente no desborda el header', (
    tester,
  ) async {
    await pumpViaShow(
      tester,
      screen: const Size(1440, 900),
      cobro: FakeCarteraData.cobro(
        id: 'C2',
        nombre: 'José María de los Dolores González-Revilla Vanguardia',
        estado: 'Pendiente',
        saldo: 60000,
      ),
    );

    // Si el Row del header desbordara, pumpAndSettle ya habría fallado;
    // afirmamos además que la tab sigue tocable con nombre largo.
    await tester.tap(find.text('Ver Deuda'));
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceChip), findsWidgets);
  });
}
