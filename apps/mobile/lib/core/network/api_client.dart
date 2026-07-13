import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart' show debugPrint;

import 'api_exceptions.dart';

// ──────────────────────────────────────────────
// Token Storage — SharedPreferences wrapper
// ──────────────────────────────────────────────

class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userKey = 'usuario_info';

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, access);
    await prefs.setString(_refreshKey, refresh);
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_userKey);
  }

  Future<bool> hasTokens() async {
    final access = await getAccessToken();
    return access != null;
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
    // Solo intentamos refresh en 401
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) {
      await _tokenStorage.clearTokens();
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

// ──────────────────────────────────────────────
// ApiClient — singleton que expone métodos HTTP
// ──────────────────────────────────────────────

class ApiClient {
  static ApiClient? _instance;

  late final Dio _dio;
  late final TokenStorage tokenStorage;
  late final AuthInterceptor _authInterceptor;

  ApiClient._({
    required String baseUrl,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 15),
  }) {
    tokenStorage = TokenStorage();

    // Dio para refresh (sin interceptors para evitar loops)
    final dioForRefresh = Dio(_baseOptions(baseUrl, connectTimeout, receiveTimeout));

    _authInterceptor = AuthInterceptor(
      dioForRefresh: dioForRefresh,
      tokenStorage: tokenStorage,
    );

    _dio = Dio(_baseOptions(baseUrl, connectTimeout, receiveTimeout));
    _dio.interceptors.add(_authInterceptor);
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (o) => debugPrint('[API] $o'),
    ));
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
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 15),
  }) {
    _instance = ApiClient._(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
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
