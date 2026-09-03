import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;

import 'api_exceptions.dart';

// ──────────────────────────────────────────────
// Secure Storage Interface (testeable)
// ──────────────────────────────────────────────

/// Abstraction over secure storage to enable dependency injection in tests.
abstract class SecureStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Production implementation backed by [FlutterSecureStorage].
class FlutterSecureStorageAdapter implements SecureStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// In-memory implementation for testing.
@visibleForTesting
class InMemorySecureStorage implements SecureStorage {
  final _store = <String, String>{};

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }
}

// ──────────────────────────────────────────────
// Token Storage — SecureStorage wrapper
// ──────────────────────────────────────────────

class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userKey = 'usuario_info';

  final SecureStorage _storage;

  TokenStorage({SecureStorage? storage})
      : _storage = storage ?? FlutterSecureStorageAdapter();

  Future<String?> getAccessToken() async {
    return _storage.read(_accessKey);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(_refreshKey);
  }

  Future<void> saveTokens(String access, String refresh) async {
    await Future.wait([
      _storage.write(_accessKey, access),
      _storage.write(_refreshKey, refresh),
    ]);
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    await _storage.write(_userKey, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final raw = await _storage.read(_userKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(_accessKey),
      _storage.delete(_refreshKey),
      _storage.delete(_userKey),
    ]);
  }

  Future<bool> hasTokens() async {
    final access = await getAccessToken();
    return access != null;
  }

  Future<bool> isAccessTokenValid({int bufferSeconds = 60}) async {
    final token = await getAccessToken();
    if (token == null) return false;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final normalized = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(payloadString) as Map<String, dynamic>;
      final exp = payload['exp'] as int?;
      if (exp == null) return false;
      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return nowSeconds < (exp - bufferSeconds);
    } catch (_) {
      return false;
    }
  }
}

// ──────────────────────────────────────────────
// Auth Interceptor — añade JWT + refresh on 401
// ──────────────────────────────────────────────

class AuthInterceptor extends Interceptor {
  final Dio _dioForRefresh; // Dio sin el interceptor auth
  final TokenStorage _tokenStorage;

  bool _isRefreshing = false;
  final _pendingRequests = <_PendingRequest>[];

  AuthInterceptor({
    required this._dioForRefresh,
    required this._tokenStorage,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final path = err.requestOptions.path;
    final isAuthEndpoint = path.contains('/auth/login') || path.contains('/auth/refresh');

    // Solo intentamos refresh en 401 que no corresponda a un endpoint de autenticación
    if (err.response?.statusCode != 401 || isAuthEndpoint) {
      handler.next(err);
      return;
    }

    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) {
      await _tokenStorage.clearTokens();
      ApiClient.instance.onUnauthorized?.call();
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const AuthException(),
          response: err.response,
          type: DioExceptionType.badResponse,
        ),
      );
      return;
    }

    if (!_isRefreshing) {
      _isRefreshing = true;

      try {
        final refreshResponse = await _dioForRefresh.post<Map<String, dynamic>>(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
        );

        final data = refreshResponse.data;
        if (data == null) {
          throw const AuthException(message: 'Respuesta de refresh inválida');
        }

        final newAccess = data['accessToken'] as String;
        final newRefresh = data['refreshToken'] as String;

        await _tokenStorage.saveTokens(newAccess, newRefresh);

        // Reintentar petición original
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
        try {
          final retryResponse = await _dioForRefresh.fetch(err.requestOptions);
          handler.resolve(retryResponse);
        } catch (retryErr) {
          handler.reject(retryErr as DioException);
        }

        // Reintentar peticiones encoladas
        _flushPendingRequests(newAccess);
      } catch (e) {
        await _tokenStorage.clearTokens();
        ApiClient.instance.onUnauthorized?.call();
        _rejectAllPending(err.requestOptions);

        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const AuthException(),
            response: err.response,
            type: DioExceptionType.badResponse,
          ),
        );
      } finally {
        _isRefreshing = false;
      }
    } else {
      // Ya hay un refresh en progreso → encolamos
      _pendingRequests.add(_PendingRequest(
        options: err.requestOptions,
        handler: handler,
      ));
    }
  }

  void _flushPendingRequests(String newAccessToken) {
    for (final pending in _pendingRequests) {
      pending.options.headers['Authorization'] = 'Bearer $newAccessToken';
      _dioForRefresh
          .fetch(pending.options)
          .then((r) => pending.handler.resolve(r))
          .catchError((e) => pending.handler.reject(e as DioException));
    }
    _pendingRequests.clear();
  }

  void _rejectAllPending(RequestOptions originalOptions) {
    for (final pending in _pendingRequests) {
      pending.handler.reject(
        DioException(
          requestOptions: pending.options,
          error: const AuthException(),
          type: DioExceptionType.badResponse,
        ),
      );
    }
    _pendingRequests.clear();
  }
}

class _PendingRequest {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;

  _PendingRequest({required this.options, required this.handler});
}

/// Pure sanitization function for logging. Replaces sensitive keys
/// (password, currentPassword, newPassword, accessToken, refreshToken) with [REDACTED].
dynamic redactSensitiveData(dynamic data) {
  if (data is Map) {
    final copy = <String, dynamic>{};
    for (final entry in data.entries) {
      final key = entry.key.toString();
      final lowerKey = key.toLowerCase();
      if (lowerKey.contains('password') ||
          lowerKey.contains('token') ||
          lowerKey.contains('secret') ||
          lowerKey.contains('authorization')) {
        copy[key] = '[REDACTED]';
      } else {
        copy[key] = redactSensitiveData(entry.value);
      }
    }
    return copy;
  } else if (data is List) {
    return data.map((item) => redactSensitiveData(item)).toList();
  }
  return data;
}

// ──────────────────────────────────────────────
// ApiClient — singleton que expone métodos HTTP
// ──────────────────────────────────────────────

class ApiClient {
  static ApiClient? _instance;

  late final Dio _dio;
  late final TokenStorage tokenStorage;
  late final AuthInterceptor _authInterceptor;

  /// Callback triggered when authorization fails (401) and session cannot be refreshed.
  void Function()? onUnauthorized;

  ApiClient._({
    required String baseUrl,
    bool enableLogging = true,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 15),
    TokenStorage? tokenStorage,
    SecureStorage? storage,
  }) : tokenStorage = tokenStorage ?? TokenStorage(storage: storage) {
    // Dio para refresh (sin interceptors para evitar loops)
    final dioForRefresh = Dio(_baseOptions(baseUrl, connectTimeout, receiveTimeout));

    _authInterceptor = AuthInterceptor(
      dioForRefresh: dioForRefresh,
      tokenStorage: this.tokenStorage,
    );

    _dio = Dio(_baseOptions(baseUrl, connectTimeout, receiveTimeout));
    _dio.interceptors.add(_authInterceptor);

    // Solo agregar logging en desarrollo, redactando datos sensibles
    if (enableLogging) {
      _dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          final sanitized = redactSensitiveData(options.data);
          debugPrint('[API] *** Request ***');
          debugPrint('[API] uri: ${options.uri}');
          debugPrint('[API] method: ${options.method}');
          if (sanitized != null) {
            debugPrint('[API] data: $sanitized');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          final sanitized = redactSensitiveData(response.data);
          debugPrint('[API] *** Response ***');
          debugPrint('[API] uri: ${response.requestOptions.uri}');
          debugPrint('[API] statusCode: ${response.statusCode}');
          if (sanitized != null) {
            debugPrint('[API] Response Text: $sanitized');
          }
          handler.next(response);
        },
        onError: (err, handler) {
          debugPrint('[API] *** DioException ***: ${err.message}');
          handler.next(err);
        },
      ));
    }
  }

  BaseOptions _baseOptions(
    String baseUrl,
    Duration connectTimeout,
    Duration receiveTimeout,
  ) {
    return BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Inicializa la instancia singleton.
  /// Debe llamarse una vez al iniciar la app (ej: en main).
  static void init({
    required String baseUrl,
    bool enableLogging = false,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 15),
    TokenStorage? tokenStorage,
    SecureStorage? storage,
  }) {
    _instance = ApiClient._(
      baseUrl: baseUrl,
      enableLogging: enableLogging,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      tokenStorage: tokenStorage,
      storage: storage,
    );
  }

  /// Acceso a la instancia singleton.
  static ApiClient get instance {
    if (_instance == null) {
      throw StateError(
        'ApiClient no inicializado. Llama ApiClient.init() primero.',
      );
    }
    return _instance!;
  }

  /// Reemplaza el adaptador HTTP interno con uno mock para testing.
  /// Solo afecta al Dio de la instancia actual.
  @visibleForTesting
  static void setHttpClientAdapter(HttpClientAdapter adapter) {
    if (_instance == null) return;
    _instance!._dio.httpClientAdapter = adapter;
  }

  // ── Métodos HTTP expuestos ──────────────────

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put<T>(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.patch<T>(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  /// Cierra sesión: limpia tokens y cache
  Future<void> logout() async {
    await tokenStorage.clearTokens();
  }

  /// Verifica si hay una sesión activa (tokens guardados)
  Future<bool> isLoggedIn() => tokenStorage.hasTokens();
}

// ──────────────────────────────────────────────
// Helper: mapea errores Dio a excepciones de dominio
// ──────────────────────────────────────────────

ApiException mapDioError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return NetworkException(message: 'Error de conexión: ${error.message}');

    case DioExceptionType.cancel:
      return const NetworkException(message: 'Petición cancelada');

    case DioExceptionType.badResponse:
      final status = error.response?.statusCode;
      final data = error.response?.data;

      if (status == 401) {
        final path = error.requestOptions.path;
        if (path.contains('/auth/login')) {
          return ApiException(
            message: _extractMessage(data) ?? 'Usuario o contraseña incorrectos',
            statusCode: 401,
            data: data,
          );
        }
        return const AuthException();
      }
      if (status == 409) {
        return ConflictException(
          message: _extractMessage(data) ?? 'Conflicto en el servidor',
          serverId: _extractServerId(data),
        );
      }
      if (status == 422) {
        return ValidationException(
          message: _extractMessage(data) ?? 'Error de validación',
          errors: _extractErrors(data),
        );
      }
      if (status != null && status >= 500) {
        return ServerException(
          message: _extractMessage(data) ?? 'Error interno del servidor',
        );
      }
      return ApiException(
        message: _extractMessage(data) ?? 'Error ${status ?? "desconocido"}',
        statusCode: status,
        data: data,
      );

    case DioExceptionType.badCertificate:
      return const NetworkException(message: 'Error de certificado SSL');

    case DioExceptionType.transformTimeout:
      return const NetworkException(message: 'Tiempo de transformación agotado');

    case DioExceptionType.unknown:
      if (error.error is ApiException) {
        return error.error as ApiException;
      }
      return NetworkException(
        message: 'Error inesperado: ${error.message}',
      );
  }
}

String? _extractMessage(dynamic data) {
  if (data is Map) {
    final msg = data['message'];
    return msg is String ? msg : data['error']?.toString();
  }
  if (data is String) return data;
  return null;
}

String? _extractServerId(dynamic data) {
  if (data is Map) {
    final id = data['serverId'] ?? data['existingId'];
    return id?.toString();
  }
  return null;
}

Map<String, List<String>>? _extractErrors(dynamic data) {
  if (data is Map && data['errors'] is Map) {
    final raw = data['errors'] as Map;
    return raw.map((k, v) => MapEntry(k.toString(), List<String>.from(v)));
  }
  return null;
}
