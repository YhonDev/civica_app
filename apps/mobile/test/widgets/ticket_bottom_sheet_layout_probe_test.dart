import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/features/auth/auth_cubit.dart';
import 'package:civica_pago_mobile/shared/widgets/ticket_bottom_sheet.dart';

/// Sonda de diseño del Recibo Digital: mide la geometría real del sheet
/// en teléfono, tablet y desktop (ancho de contenido, centrado, gutters)
/// a través del path real de showModalBottomSheet.
///
/// Un fallo aquí significa que el contrato visual del ticket se rompió:
/// contenido > maxFormWidth, fuera de centro, gutters desiguales o datos
/// clave invisibles.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.init(baseUrl: 'http://test.local');
    initializeDateFormatting('es');
  });

  Future<void> pumpViaShow(
    WidgetTester tester, {
    required Size screen,
    String rol = 'COBRADOR',
  }) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1.0;
    // reset() revierte physicalSize y dpr de una sola vez.
    addTearDown(tester.view.reset);

    final authCubit = AuthCubit();
    addTearDown(authCubit.close);
    authCubit.emit(AuthState.authenticated({
      'nombre': 'Cobrador Test',
      'rol': rol,
      'id': 'u1',
      'tenantId': 't1',
    }));

    // El provider vive sobre MaterialApp: showModalBottomSheet usa el
    // navigator raíz, cuyo contexto no ve providers dentro de `home`.
    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: authCubit,
        child: const MaterialApp(
          home: Scaffold(body: SizedBox.expand()),
        ),
      ),
    );

    // Path real de presentación (modal), no montaje directo del widget.
    final context = tester.element(find.byType(Scaffold));
    // ignore: unawaited_futures
    TicketBottomSheet.show(
      context,
      TicketData(
        numero: 'TK-000123',
        fecha: DateTime(2026, 9, 9, 14, 30),
        residente: 'Carlos Pendiente',
        casa: 'Casa 101 · Manzana A · Etapa 1',
        monto: 45000,
        metodo: 'Efectivo',
        estado: 'EMITIDO',
        cobrador: 'Luis Pérez Cobrador',
        concepto: 'Cuota 1 — Septiembre',
      ),
    );
    await tester.pumpAndSettle();
  }

  Rect contentRect(WidgetTester tester) => tester.getRect(find.descendant(
        of: find.byType(TicketBottomSheet),
        matching: find.byType(Column),
      ).first);

  /// (nombre, tamaño de pantalla, gutter izquierdo esperado)
  final cases = <(String, Size, double)>[
    ('teléfono', const Size(390, 844), 20),
    ('tablet (820px)', const Size(820, 1180), (820 - 440) / 2),
    ('desktop (1440px)', const Size(1440, 900), (1440 - 440) / 2),
  ];

  for (final (nombre, screen, expectedLeft) in cases) {
    testWidgets('[$nombre] contenido ≤ 440, centrado y datos visibles', (
      tester,
    ) async {
      await pumpViaShow(tester, screen: screen);

      final content = contentRect(tester);
      expect(content.width, lessThanOrEqualTo(440.0),
          reason: '$nombre: el contenido se estira más allá de maxFormWidth');

      final left = content.left;
      final right = screen.width - content.right;
      expect(left, closeTo(expectedLeft, 0.5),
          reason: '$nombre: gutter izquierdo $left ≠ esperado $expectedLeft');
      expect(right, closeTo(left, 0.5),
          reason: '$nombre: asimétrico — izq $left vs der $right');
      expect(left, greaterThanOrEqualTo(20.0),
          reason: '$nombre: el modal pega el contenido al borde');

      // Datos clave del ticket visibles (monto, estado, cobrador, cierre).
      expect(find.textContaining('45.000'), findsWidgets,
          reason: '$nombre: el monto no es visible');
      expect(find.text('EMITIDO'), findsOneWidget,
          reason: '$nombre: el estado no es visible');
      expect(find.text('Luis Pérez Cobrador'), findsOneWidget,
          reason: '$nombre: el cobrador no es visible');
      expect(find.text('Cerrar'), findsOneWidget,
          reason: '$nombre: el botón de cierre no es visible');
    });
  }

  testWidgets('[desktop] monto y chip de estado centrados sobre el contenido', (
    tester,
  ) async {
    await pumpViaShow(tester, screen: const Size(1440, 900));

    final content = contentRect(tester);
    final amountCenter = tester.getCenter(find.textContaining('45.000').first);
    // El chip es el Container más cercano al texto; su Text interno queda
    // 9px a la izquierda del centro del chip por el icono + gap.
    final chipCenter = tester.getCenter(find
        .ancestor(
          of: find.text('EMITIDO'),
          matching: find.byType(Container),
        )
        .first);

    expect((amountCenter.dx - content.center.dx).abs(), lessThan(2.0),
        reason: 'el monto protagonista no está centrado sobre el contenido');
    expect((chipCenter.dx - content.center.dx).abs(), lessThan(2.0),
        reason: 'el chip de estado no está centrado sobre el contenido');
  });

  testWidgets('[tablet] rol RESIDENTE muestra Revisar pago + Cerrar', (
    tester,
  ) async {
    await pumpViaShow(tester, screen: const Size(820, 1180), rol: 'RESIDENTE');

    expect(find.text('Revisar pago'), findsOneWidget);
    expect(find.text('Cerrar'), findsOneWidget);

    // Ambos botones caben dentro del contenido acotado (sin overflow:
    // pumpAndSettle habría propagado la excepción).
    final content = contentRect(tester);
    final buttonsRect = tester.getRect(find.text('Revisar pago'));
    expect(buttonsRect.left, greaterThanOrEqualTo(content.left));
    expect(buttonsRect.right, lessThanOrEqualTo(content.right));
  });
}
