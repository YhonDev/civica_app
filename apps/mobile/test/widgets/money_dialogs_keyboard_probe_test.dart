import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/features/residentes/montos_screen.dart';
import 'package:civica_pago_mobile/features/residentes/tarifas_screen.dart';
import 'package:civica_pago_mobile/shared/widgets/solicitud_bottom_sheet.dart';
import 'package:civica_pago_mobile/shared/widgets/solicitud_card.dart';

import 'mock_http_adapter.dart';
import 'probe_helpers.dart';

/// Sonda de teclado para los diálogos de dinero: con el teclado abierto,
/// cada diálogo debe mantenerse sin overflow y con su campo + botón de
/// guardar alcanzables (el contenido se desplaza, no se recorta).
///
/// Un fallo aquí significa que el diálogo desborda verticalmente cuando el
/// teclado reduce el espacio (defecto ya encontrado en el sheet de pago).
void main() {
  MockHttpAdapter mockAdapter() => MockHttpAdapter()
      ..onGet('/solicitudes/sol-1/detalle-resolucion', () => {
            'pago': {'monto': 2000000, 'metodo': 'Efectivo'},
            'cobro': {'concepto': 'Septiembre - Cuota 1'},
            'ticket': {'numero': 'TK-777'},
          })
      ..onGet('/montos-predefinidos', () => [
            {'id': 'm1', 'monto': 1000000},
          ])
      ..onGet('/proyectos', () => [
            {'id': 'p1', 'nombre': 'Proyecto Test'},
          ])
      ..onGet('/tarifas/vigentes', () => {
            'tarifas': {
              'MENSUAL': {'id': 't1', 'montoPesos': 40000},
            },
          });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // InMemorySecureStorage: el flutter_secure_storage real no responde su
    // platform channel en tests y cuelga AuthInterceptor para siempre.
    ApiClient.init(
      baseUrl: 'http://test.local',
      connectTimeout: Duration.zero,
      receiveTimeout: Duration.zero,
      tokenStorage: TokenStorage(storage: InMemorySecureStorage()),
    );
    ApiClient.setHttpClientAdapter(mockAdapter());
    initializeDateFormatting('es');
  });

  SolicitudData solicitud() => SolicitudData(
        id: 'sol-1',
        cobroId: 'c-1',
        nroRecibo: 'TK-777',
        tipo: 'solicitud_revision_pago',
        descripcion:
            'Adjunto comprobante de pago de la cuota de septiembre, revisar por favor.',
        estado: SolicitudEstado.enRevision,
        fecha: DateTime(2026, 9, 9, 10, 30),
        residenteNombre: 'Carlos Pendiente',
      );

  void setViewport(WidgetTester tester, Size screen, {bool keyboard = false}) {
    setProbeViewport(tester, screen, keyboard: keyboard);
  }

  /// Abre el sheet de solicitud vía path real de showModalBottomSheet.
  Future<void> pumpSolicitudSheet(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: FilledButton(
              onPressed: () => SolicitudBottomSheet.show(
                context,
                solicitud(),
                isAdmin: true,
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  /// Verifica que un diálogo bajo teclado no desborde y que sus campos y
  /// botones de acción sigan siendo tocables tras hacer scroll del contenido.
  Future<void> expectDialogUsableUnderKeyboard(
    WidgetTester tester, {
    required String actionLabel,
  }) async {
    final err = tester.takeException();
    expect(err, isNull);
    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);

    // Con scrollable:true el contenido se desplaza: traer el campo a la
    // vista antes de afirmar que es tocable. Los finders se acotan al
    // diálogo: las rutas de abajo (sheet) también tienen TextFields.
    final field = find.descendant(of: dialog, matching: find.byType(TextField)).first;
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    expect(find.descendant(of: dialog, matching: find.byType(TextField)).hitTestable(), findsWidgets,
        reason: 'el campo no es alcanzable con el teclado abierto');
    expect(find.descendant(of: dialog, matching: find.text(actionLabel)).hitTestable(), findsOneWidget,
        reason: 'el botón "$actionLabel" no es alcanzable con el teclado abierto');
  }

  testWidgets('[solicitud · sheet] con teclado no desborda (regresión)', (
    tester,
  ) async {
    setViewport(tester, const Size(390, 844), keyboard: true);
    await pumpSolicitudSheet(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(SolicitudBottomSheet), findsOneWidget);

    // El contenido se desplaza (no se recorta): el scroll debe poder traer
    // las acciones administrativas a la vista.
    await tester.ensureVisible(find.text('Corregir Valor del Pago'));
    await tester.pumpAndSettle();
    expect(find.text('Corregir Valor del Pago').hitTestable(), findsOneWidget,
        reason: 'las acciones del sheet quedan inalcanzables tras scroll');
  });

  testWidgets('[solicitud · Corregir Valor] teclado + viewport estrecho', (
    tester,
  ) async {
    setViewport(tester, const Size(390, 560), keyboard: true);
    await pumpSolicitudSheet(tester);

    await tester.ensureVisible(find.text('Corregir Valor del Pago'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Corregir Valor del Pago'));
    await tester.pumpAndSettle();

    await expectDialogUsableUnderKeyboard(tester, actionLabel: 'Guardar Corrección');
    // El monto llega prellenado ya formateado con la máscara global.
    final field = tester.widget<TextField>(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          )
          .first,
    );
    expect(field.controller!.text, '20.000');
  });

  testWidgets('[solicitud · Revertir Pago] teclado + viewport estrecho', (
    tester,
  ) async {
    setViewport(tester, const Size(390, 560), keyboard: true);
    await pumpSolicitudSheet(tester);

    await tester.ensureVisible(find.text('Revertir Pago (Liberar Cuota)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Revertir Pago (Liberar Cuota)'));
    await tester.pumpAndSettle();

    await expectDialogUsableUnderKeyboard(tester, actionLabel: 'Confirmar Reversión');
  });

  testWidgets('[montos · Nuevo Monto] teclado + viewport estrecho', (
    tester,
  ) async {
    setViewport(tester, const Size(390, 560), keyboard: true);
    await tester.pumpWidget(const MaterialApp(home: MontosScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nuevo Monto'));
    await tester.pumpAndSettle();

    await expectDialogUsableUnderKeyboard(tester, actionLabel: 'Guardar');
  });

  testWidgets('[tarifas · Crear/Editar] teclado + viewport estrecho', (
    tester,
  ) async {
    setViewport(tester, const Size(390, 560), keyboard: true);
    await tester.pumpWidget(const MaterialApp(home: TarifasScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Crear/Configurar Tarifa'));
    await tester.pumpAndSettle();

    await expectDialogUsableUnderKeyboard(tester, actionLabel: 'Guardar Cambios');
    // Prefill formateado: el diálogo edita la tarifa de 40000.
    final field = tester.widget<TextField>(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          )
          .first,
    );
    expect(field.controller!.text, '40.000');
  });
}
