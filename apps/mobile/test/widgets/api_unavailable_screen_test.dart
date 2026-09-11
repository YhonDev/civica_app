import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:civica_pago_mobile/core/network/api_health_service.dart';
import 'package:civica_pago_mobile/features/setup/api_unavailable_screen.dart';

/// Adaptador configurable: responde exito o falla según [fallar].
class _AdapterControlado implements HttpClientAdapter {
  _AdapterControlado({required this.fallar});

  bool fallar;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (fallar) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'connection refused',
      );
    }
    return ResponseBody.fromBytes('{"status":"ok"}'.codeUnits, 200);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('muestra mensaje de API no disponible y botón Reintentar',
      (tester) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
      ..httpClientAdapter = _AdapterControlado(fallar: true);
    final service = ApiHealthService(dio: dio);

    await tester.pumpWidget(
      MaterialApp(home: ApiUnavailableScreen(healthService: service)),
    );

    expect(find.text('API no disponible'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
  });

  testWidgets('Reintentar con API disponible llama onAvailable',
      (tester) async {
    final control = _AdapterControlado(fallar: true);
    final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
      ..httpClientAdapter = control;
    final service = ApiHealthService(dio: dio);

    var disponibleLlamado = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ApiUnavailableScreen(
          healthService: service,
          onAvailable: () => disponibleLlamado = true,
        ),
      ),
    );

    control.fallar = false; // ahora la API "responde"

    await tester.tap(find.text('Reintentar'));
    await tester.pump(); // procesa el tap
    await tester.pump(const Duration(milliseconds: 100)); // resuelve el future

    expect(disponibleLlamado, isTrue);
  });

  testWidgets('Reintentar con API caída muestra SnackBar y sigue en pantalla',
      (tester) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
      ..httpClientAdapter = _AdapterControlado(fallar: true);
    final service = ApiHealthService(dio: dio);

    var disponibleLlamado = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ApiUnavailableScreen(
          healthService: service,
          onAvailable: () => disponibleLlamado = true,
        ),
      ),
    );

    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400)); // SnackBar visible

    expect(disponibleLlamado, isFalse);
    expect(find.text('API no disponible'), findsOneWidget);
    expect(
      find.text('Sigue sin responder. Verifica que el backend esté corriendo.'),
      findsOneWidget,
    );
  });
}
