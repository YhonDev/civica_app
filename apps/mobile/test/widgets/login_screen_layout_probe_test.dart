import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/features/auth/auth_cubit.dart';
import 'package:civica_pago_mobile/features/auth/login_screen.dart';

import 'probe_helpers.dart';

/// Sonda de diseño del Login: mide la geometría real del formulario en
/// teléfono, tablet y desktop (ancho ≤ maxFormWidth, centrado, gutters)
/// y verifica que, con teclado abierto, el CTA siga alcanzable con scroll.
///
/// Un fallo aquí significa que el contrato visual del login se rompió:
/// formulario > 440px, fuera de centro, gutters desiguales o CTA inalcanzable.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.init(baseUrl: 'http://test.local');
  });

  Future<void> pumpLogin(
    WidgetTester tester, {
    required Size screen,
    bool keyboard = false,
  }) async {
    setProbeViewport(tester, screen, keyboard: keyboard);

    final authCubit = AuthCubit();
    addTearDown(authCubit.close);

    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: authCubit,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Rect formRect(WidgetTester tester) => tester.getRect(find
      .descendant(
        of: find.byType(Form),
        matching: find.byType(Column),
      )
      .first);

  /// (nombre, tamaño de pantalla, gutter izquierdo esperado)
  final cases = <(String, Size, double)>[
    ('teléfono', const Size(390, 844), 32),
    ('tablet (820px)', const Size(820, 1180), (820 - 440) / 2),
    ('desktop (1440px)', const Size(1440, 900), (1440 - 440) / 2),
  ];

  for (final (nombre, screen, expectedLeft) in cases) {
    testWidgets('[$nombre] formulario ≤ 440, centrado y campos visibles', (
      tester,
    ) async {
      await pumpLogin(tester, screen: screen);

      final form = formRect(tester);
      expectCenteredContentGeometry(
        form,
        screenWidth: screen.width,
        expectedLeft: expectedLeft,
        label: nombre,
      );

      // Elementos clave visibles (sin overflow: pumpAndSettle habría
      // propagado la excepción).
      expect(find.text('Iniciar sesión'), findsOneWidget,
          reason: '$nombre: el botón de login no es visible');
      expect(find.text('Nombre de usuario'), findsOneWidget,
          reason: '$nombre: el campo de usuario no es visible');
      expect(find.text('Contraseña'), findsOneWidget,
          reason: '$nombre: el campo de contraseña no es visible');
    });
  }

  testWidgets(
      '[teléfono + teclado] el CTA de login sigue alcanzable con scroll', (
    tester,
  ) async {
    await pumpLogin(tester, screen: const Size(390, 844), keyboard: true);

    // Sin overflow de layout.
    expect(find.text('Iniciar sesión'), findsOneWidget);

    // El scroll debe poder llevar el CTA completamente a la vista.
    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    final screenBottom =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final buttonRect = tester.getRect(find.text('Iniciar sesión'));
    expect(buttonRect.bottom, lessThanOrEqualTo(screenBottom),
        reason: 'con teclado abierto, el CTA queda cortado aun tras scroll');
    expect(buttonRect.top, greaterThanOrEqualTo(0.0),
        reason: 'con teclado abierto, el CTA queda por encima del viewport');
  });

  testWidgets('[desktop + teclado] el formulario permanece montado y centrado',
      (tester) async {
    await pumpLogin(tester, screen: const Size(1440, 900), keyboard: true);

    final form = formRect(tester);
    final right = 1440 - form.right;
    expect(form.width, lessThanOrEqualTo(440.0),
        reason: 'con teclado, el formulario supera maxFormWidth');
    expect(right, closeTo(form.left, 0.5),
        reason: 'con teclado, el formulario queda descentrado');

    expect(find.text('Iniciar sesión'), findsOneWidget,
        reason: 'con teclado, el botón de login desapareció');
  });
}
