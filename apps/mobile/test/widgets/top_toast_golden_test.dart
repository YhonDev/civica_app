import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:civica_pago_mobile/core/theme/app_colors.dart';
import 'package:civica_pago_mobile/core/theme/app_theme.dart';
import 'package:civica_pago_mobile/core/widgets/top_toast.dart';

/// Capturas reales del estándar de notificaciones (TopToast).
///
/// Genera un PNG por variante × modo (claro/oscuro) en
/// test/widgets/goldens/, renderizados por el motor Flutter real —
/// es el equivalente a una screenshot de la app.
///
/// Regenerar:  flutter test --update-goldens test/widgets/top_toast_golden_test.dart
/// Verificar:  flutter test test/widgets/top_toast_golden_test.dart
void main() {
  // flutter_test carga MaterialIcons automáticamente en widget tests.

  const Map<String, (ToastType, String, String)> cases = {
    'success': (ToastType.success, 'Pago registrado',
        'El cobro quedó registrado y sincronizado.'),
    'error': (ToastType.error, 'Error',
        'No se pudo sincronizar. Intenta de nuevo.'),
    'info': (ToastType.info, 'En segundo plano',
        'La sincronización continúa en segundo plano.'),
    'warning': (ToastType.warning, 'Atención',
        'Quedan pocos reintentos disponibles.'),
  };

  const modes = <String, bool>{'light': false, 'dark': true};

  for (final entry in modes.entries) {
    final modeName = entry.key;
    final isDark = entry.value;
    group('TopToast goldens — modo $modeName', () {
      for (final e in cases.entries) {
        testWidgets('${e.key} renderiza con sus tokens', (tester) async {
          final type = e.value.$1;
          final title = e.value.$2;
          final message = e.value.$3;
          AppColors.setDarkMode(isDark);

          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData(padding: EdgeInsets.only(top: 24)),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: isDark ? buildDarkTheme() : buildLightTheme(),
                home: const Scaffold(body: SizedBox.expand()),
              ),
            ),
          );

          final context = tester.state(find.byType(Scaffold)).context;
          TopToast.show(
            context,
            type: type,
            title: title,
            message: message,
            duration: const Duration(seconds: 60),
          );
          await tester.pump(); // inserta overlay
          await tester.pumpAndSettle(); // entrada elástica completa

          // Aserciones visuales del estándar (por celda).
          expect(find.text(title), findsOneWidget);
          expect(find.text(message), findsOneWidget);
          final icon = switch (type) {
            ToastType.success => Icons.check_circle_rounded,
            ToastType.error => Icons.error_rounded,
            ToastType.warning => Icons.warning_rounded,
            ToastType.info => Icons.info_rounded,
          };
          expect(find.byIcon(icon), findsOneWidget);

          // El color de la tarjeta SIEMPRE es el token global (en ambos modos).
          final container = tester.widget<Container>(
            find
                .ancestor(
                  of: find.text(message),
                  matching: find.byType(Container),
                )
                .first,
          );
          expect(
            (container.decoration! as BoxDecoration).color,
            AppColors.toastSurface,
          );

          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/toast_${e.key}_$modeName.png'),
          );

          // Cierre natural: disparar el timer (60s) y dejar correr la
          // animación de salida hasta que el OverlayEntry se retire. Así no
          // quedan timers pendientes al desmontar el árbol.
          await tester.pump(const Duration(seconds: 61));
          await tester.pumpAndSettle();
          expect(find.text(message), findsNothing);
        });
      }
    });
  }

  // Sanity: los 8 PNG existen tras la generación.
  test('los 8 goldens del estándar existen en disco', () {
    for (final mode in modes.keys) {
      for (final v in cases.keys) {
        final f = File('test/widgets/goldens/toast_${v}_$mode.png');
        expect(f.existsSync(), isTrue, reason: 'falta ${f.path}');
      }
    }
  });
}
