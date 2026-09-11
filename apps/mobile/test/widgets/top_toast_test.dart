import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:civica_pago_mobile/core/theme/app_colors.dart';
import 'package:civica_pago_mobile/core/widgets/top_toast.dart';

/// Suite del estándar global de notificaciones (regla 9.8 de guardian).
///
/// Valida que TopToast sea EL estándar: variantes con estilo tokenizado,
/// auto-cierre, un solo slot (sin pilas), tap para cerrar, acción opcional
/// y dismissal explícito.
void main() {
  // Duración corta para probar el auto-cierre sin esperar 3s reales.
  const fastDuration = Duration(milliseconds: 300);

  Future<void> showToast(
    WidgetTester tester, {
    ToastType type = ToastType.success,
    String message = 'Mensaje de prueba',
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = fastDuration,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => TopToast.show(
                  context,
                  message: message,
                  title: title,
                  type: type,
                  actionLabel: actionLabel,
                  onAction: onAction,
                  duration: duration,
                ),
                child: const Text('mostrar'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('mostrar'));
    await tester.pump(); // inserta el OverlayEntry
    await tester.pump(); // primer frame de la animación
  }

  group('TopToast — variantes y estilo tokenizado', () {
    testWidgets('success muestra el mensaje con superficie del token',
        (tester) async {
      await showToast(tester, type: ToastType.success);
      expect(find.text('Mensaje de prueba'), findsOneWidget);
      // El color de fondo de la tarjeta es el token global (no un hex local).
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Mensaje de prueba'),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.toastSurface);
    });

    testWidgets('cada variante usa su icono semántico', (tester) async {
      const expected = {
        ToastType.success: Icons.check_circle_rounded,
        ToastType.error: Icons.error_rounded,
        ToastType.warning: Icons.warning_rounded,
        ToastType.info: Icons.info_rounded,
      };
      for (final entry in expected.entries) {
        await showToast(tester, type: entry.key, message: 'v-${entry.key.name}');
        expect(
          find.byIcon(entry.value),
          findsOneWidget,
          reason: 'variante ${entry.key.name} debe mostrar ${entry.value}',
        );
        // retira el toast para la siguiente iteración
        TopToast.dismissCurrent();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('muestra el título cuando se provee', (tester) async {
      await showToast(tester, title: 'Título');
      expect(find.text('Título'), findsOneWidget);
      expect(find.text('Mensaje de prueba'), findsOneWidget);
    });

    testWidgets('muestra error con mensaje sanitizado por el call site',
        (tester) async {
      // El estándar: la UI pasa por sanitizeApiError antes de llamar.
      await showToast(tester, type: ToastType.error, message: 'Error al sincronizar: sin conexión');
      expect(find.textContaining('Error al sincronizar'), findsOneWidget);
    });
  });

  group('TopToast — comportamiento', () {
    testWidgets('auto-cierre tras la duración', (tester) async {
      await showToast(tester, duration: const Duration(milliseconds: 100));
      expect(find.text('Mensaje de prueba'), findsOneWidget);

      // Espera duración + animación de salida (380ms) + margen.
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Mensaje de prueba'), findsNothing);
    });

    testWidgets('un solo slot: el segundo toast reemplaza al primero',
        (tester) async {
      // Dos botones con parámetros distintos (un solo onPressed cerraría
      // siempre el mismo toast). Duración larga: que NO auto-cierre durante
      // el settle; el reemplazo debe venir del single-slot, no del timer.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () => TopToast.show(
                        context,
                        message: 'Primero',
                        type: ToastType.info,
                        duration: const Duration(seconds: 30),
                      ),
                      child: const Text('mostrar A'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => TopToast.show(
                        context,
                        message: 'Segundo',
                        type: ToastType.success,
                        duration: const Duration(seconds: 30),
                      ),
                      child: const Text('mostrar B'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('mostrar A'));
      await tester.pumpAndSettle();
      expect(find.text('Primero'), findsOneWidget);

      // Mostrar el segundo SIN retirar el primero manualmente: no se apilan.
      await tester.tap(find.text('mostrar B'));
      await tester.pumpAndSettle();

      expect(find.text('Primero'), findsNothing);
      expect(find.text('Segundo'), findsOneWidget);
    });

    testWidgets('tap sobre la tarjeta lo cierra (con animación de salida)',
        (tester) async {
      // Duración larga: el cierre debe venir del TAP, no del timer.
      await showToast(tester, duration: const Duration(seconds: 30));
      await tester.pumpAndSettle(); // que la tarjeta esté en su posición final
      expect(find.text('Mensaje de prueba'), findsOneWidget);

      await tester.tap(find.text('Mensaje de prueba'));
      await tester.pumpAndSettle();
      expect(find.text('Mensaje de prueba'), findsNothing);
    });

    testWidgets('acción opcional: se ejecuta y el toast se cierra',
        (tester) async {
      var actionFired = false;
      await showToast(
        tester,
        actionLabel: 'Deshacer',
        onAction: () => actionFired = true,
        duration: const Duration(seconds: 30),
      );
      await tester.pumpAndSettle();
      expect(find.text('Deshacer'), findsOneWidget);

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();

      expect(actionFired, isTrue);
      expect(find.text('Mensaje de prueba'), findsNothing);
    });

    testWidgets('dismissCurrent retira el toast inmediatamente',
        (tester) async {
      await showToast(tester);
      expect(find.text('Mensaje de prueba'), findsOneWidget);

      TopToast.dismissCurrent();
      await tester.pump();

      expect(find.text('Mensaje de prueba'), findsNothing);
    });

    testWidgets('dismissCurrent sin toast visible no lanza',
        (tester) async {
      TopToast.dismissCurrent(); // nunca se mostró nada
      await showToast(tester);
      TopToast.dismissCurrent();
      TopToast.dismissCurrent(); // doble dismissal idempotente
      await tester.pump();
      expect(find.text('Mensaje de prueba'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
