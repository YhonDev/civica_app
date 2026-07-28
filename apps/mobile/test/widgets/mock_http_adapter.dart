import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

/// A mock [HttpClientAdapter] that returns pre-configured JSON responses
/// based on the request path and method.
///
/// Usage:
/// ```dart
/// final adapter = MockHttpAdapter()
///   ..onGet('/proyectos', () => [{'id': '1', 'nombre': 'Test'}])
///   ..onPost('/residentes', () => {'usuario': {...}, 'credenciales': {...}});
///
/// ApiClient.setHttpClientAdapter(adapter);
/// ```
class MockHttpAdapter implements HttpClientAdapter {
  final Map<String, _RouteHandler> _handlers = {};
  int _statusCode = 200;

  /// Registers a handler for GET [path].
  void onGet(String path, _DataBuilder builder) {
    _handlers['GET $path'] = _RouteHandler(builder);
  }

  /// Registers a handler for POST [path].
  void onPost(String path, _DataBuilder builder) {
    _handlers['POST $path'] = _RouteHandler(builder);
  }

  /// Registers a handler for PATCH [path].
  void onPatch(String path, _DataBuilder builder) {
    _handlers['PATCH $path'] = _RouteHandler(builder);
  }

  /// Registers a handler for DELETE [path].
  void onDelete(String path, _DataBuilder builder) {
    _handlers['DELETE $path'] = _RouteHandler(builder);
  }

  /// Overrides the status code for the next response.
  void setStatusCode(int code) {
    _statusCode = code;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    // Extract the path without query parameters
    final uri = Uri.parse(options.path);
    final path = uri.path;
    final key = '${options.method} $path';

    // Also try to match a "catch-all" handler if exact match fails
    final handler = _handlers[key];
    if (handler == null) {
      // Return empty JSON array for unknown GET requests
      return ResponseBody.fromString('[]', 200, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });
    }

    final data = handler.builder();
    final body = jsonEncode(data);

    return ResponseBody.fromString(body, _statusCode, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

typedef _DataBuilder = dynamic Function();

class _RouteHandler {
  final _DataBuilder builder;
  _RouteHandler(this.builder);
}
