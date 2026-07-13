import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

/// Lightweight mock HTTP adapter for Dio.
///
/// Register expected responses via `onGet`, `onPost`, etc.
/// Unregistered paths throw a descriptive error.
class MockHttpAdapter implements HttpClientAdapter {
  final Map<String, _MockResponse> _handlers = {};
  final Map<String, int> _callCount = {};

  void onGet(String path, dynamic data, {int statusCode = 200}) {
    _handlers['GET $path'] = _MockResponse(data, statusCode);
  }

  void onPost(String path, dynamic data, {int statusCode = 201}) {
    _handlers['POST $path'] = _MockResponse(data, statusCode);
  }

  void onPatch(String path, dynamic data, {int statusCode = 200}) {
    _handlers['PATCH $path'] = _MockResponse(data, statusCode);
  }

  void onDelete(String path, dynamic data, {int statusCode = 200}) {
    _handlers['DELETE $path'] = _MockResponse(data, statusCode);
  }

  /// How many times a given method+path was called.
  int calls(String method, String path) =>
      _callCount['$method $path'] ?? 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // Resolver el path base sin query string
    // Dio 5: options.path tiene el path original, options.uri es la URI completa
    final rawPath = options.path;
    // Tomar solo la parte del path (sin query string si el path la incluye)
    final basePath = rawPath.contains('?')
        ? rawPath.substring(0, rawPath.indexOf('?'))
        : rawPath;
    final key = '${options.method} $basePath';

    _callCount[key] = (_callCount[key] ?? 0) + 1;

    final handler = _handlers[key];
    if (handler == null) {
      throw DioException(
        requestOptions: options,
        message: 'MockHttpAdapter: no handler for $key',
        type: DioExceptionType.badResponse,
      );
    }

    final body = jsonEncode(handler.data);
    final headers = <String, List<String>>{
      'content-type': ['application/json'],
    };

    return ResponseBody.fromString(body, handler.statusCode, headers: headers);
  }

  @override
  void close({bool force = false}) {}
}

class _MockResponse {
  final dynamic data;
  final int statusCode;

  const _MockResponse(this.data, this.statusCode);
}
