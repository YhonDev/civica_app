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

  /// Inicia sesión con email y contraseña.
  /// En caso de éxito, [ApiClient] guarda los tokens automáticamente.
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    final data = response.data;
    if (data == null) {
      throw const ApiException(message: 'Respuesta de login vacía');
    }

    final result = LoginResult.fromJson(data);

    // Guardar tokens en el storage
    await _client.tokenStorage.saveTokens(
      result.accessToken,
      result.refreshToken,
    );
    await _client.tokenStorage.saveUser(result.usuario);

    return result;
  }

  /// Registra un nuevo usuario (solo ADMIN).
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String nombre,
    required String rol,
    required String tenantId,
    String? propietarioId,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'nombre': nombre,
        'rol': rol,
        'tenantId': tenantId,
        // ignore: use_null_aware_elements
        if (propietarioId != null) 'residenteId': propietarioId,
      },
    );

    return response.data ?? {};
  }

  /// Cierra sesión y limpia tokens.
  Future<void> logout() async {
    await _client.logout();
  }

  /// Verifica si hay una sesión activa.
  Future<bool> isLoggedIn() => _client.isLoggedIn();
}
