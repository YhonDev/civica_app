import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:civica_pago_mobile/core/network/api_health_service.dart';

/// Adaptador HTTP falso que responde según la configuración.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      handler(options);
}

void main() {
  group('ApiHealthService.isApiReachable()', () {
    test('devuelve true cuando /health responde 200', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
        ..httpClientAdapter = _FakeAdapter(
          (options) async => ResponseBody.fromBytes(
            '{"status":"ok"}'.codeUnits,
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          ),
        );

      final service = ApiHealthService(dio: dio);
      expect(await service.isApiReachable(), isTrue);
    });

    test('devuelve true incluso si /health responde 404 (hay conexión)', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
        ..httpClientAdapter = _FakeAdapter(
          (options) async => ResponseBody.fromBytes(
            'not found'.codeUnits,
            404,
          ),
        );

      final service = ApiHealthService(dio: dio);
      expect(await service.isApiReachable(), isTrue);
    });

    test('devuelve false cuando la conexión es rechazada', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
        ..httpClientAdapter = _FakeAdapter(
          (options) async =>
              throw DioException.connectionError(
                requestOptions: options,
                reason: 'connection refused',
              ),
        );

      final service = ApiHealthService(dio: dio);
      expect(await service.isApiReachable(), isFalse);
    });

    test('devuelve false cuando hay timeout de conexión', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
        ..httpClientAdapter = _FakeAdapter(
          (options) async => throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionTimeout,
          ),
        );

      final service = ApiHealthService(dio: dio);
      expect(await service.isApiReachable(), isFalse);
    });

    test('devuelve false ante errores inesperados (no DioException)', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
        ..httpClientAdapter = _FakeAdapter(
          (options) async => throw StateError('boom'),
        );

      final service = ApiHealthService(dio: dio);
      expect(await service.isApiReachable(), isFalse);
    });
  });
}
