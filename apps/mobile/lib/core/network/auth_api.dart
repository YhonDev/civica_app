import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_exceptions.dart';

/// Resultado de un login exitoso.
class LoginResult {
  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> usuario;

  const LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.usuario,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      usuario: json['usuario'] as Map<String, dynamic>,
    );
  }
}

/// API de autenticación.
/// Se apoya en [ApiClient] para el manejo automático de tokens.
class AuthApi {
  final ApiClient _client;

  AuthApi([ApiClient? client]) : _client = client ?? ApiClient.instance;

  /// Inicia sesión con username y contraseña.
  /// En caso de éxito, [ApiClient] guarda los tokens automáticamente.
  Future<LoginResult> login({
    required String username,
    required String password,
    String? deviceId,
    String? deviceName,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
          'deviceId': deviceId,
          'deviceName': deviceName,
        },
      );

      final data = response.data;
      if (data == null) {
        throw const ApiException(message: 'Respuesta de login vacía');
      }

      final result = LoginResult.fromJson(data);

      await _client.tokenStorage.saveTokens(
        result.accessToken,
        result.refreshToken,
      );
      await _client.tokenStorage.saveUser(result.usuario);

      return result;
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Error inesperado durante la autenticación: $e');
    }
  }

  /// Registra un nuevo usuario (solo ADMIN).
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String nombre,
    required String rol,
    required String tenantId,
    String? residenteId,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'username': username,
          'password': password,
          'nombre': nombre,
          'rol': rol,
          'tenantId': tenantId,
          'residenteId': residenteId,
        },
      );

      return response.data ?? {};
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Cierra sesión y limpia tokens.
  Future<void> logout() async {
    try {
      final refreshToken = await _client.tokenStorage.getRefreshToken();
      if (refreshToken != null) {
        await _client.post('/auth/logout', data: {'refreshToken': refreshToken});
      }
    } catch (_) {
      // Ignorar errores de red en logout — siempre limpiar local
    }
    await _client.logout();
  }

  /// Intenta refrescar la sesión con el refresh token guardado.
  /// Lanza [NetworkException] si hay falla de conexión offline, o [AuthException] si el token expiró/revocó.
  Future<Map<String, dynamic>?> refreshSession() async {
    final refreshToken = await _client.tokenStorage.getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final data = response.data;
      if (data == null) return null;

      final newAccess = data['accessToken'] as String?;
      final newRefresh = data['refreshToken'] as String?;
      if (newAccess == null || newRefresh == null) return null;

      await _client.tokenStorage.saveTokens(newAccess, newRefresh);

      final usuario = data['usuario'] as Map<String, dynamic>?;
      if (usuario != null) {
        await _client.tokenStorage.saveUser(usuario);
        return usuario;
      }

      return await _client.tokenStorage.getUser();
    } on DioException catch (e) {
      final mapped = mapDioError(e);
      if (mapped is AuthException) {
        throw mapped;
      }
      throw NetworkException(message: 'Error de conexión al refrescar sesión: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(message: 'Error de red inesperado al refrescar sesión: $e');
    }
  }

  /// Verifica si el access token actual aún es válido localmente.
  Future<bool> isAccessTokenValid() => _client.tokenStorage.isAccessTokenValid();

  /// Obtiene la información del usuario en caché.
  Future<Map<String, dynamic>?> getCachedUser() => _client.tokenStorage.getUser();

  /// Verifica si hay una sesión activa.
  Future<bool> isLoggedIn() => _client.isLoggedIn();
}
