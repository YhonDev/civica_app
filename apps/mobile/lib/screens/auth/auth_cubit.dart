import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../core/network/auth_api.dart';
import '../../core/network/api_exceptions.dart';

// ════════════════════════════════════════════════════════════
// STATE
// ════════════════════════════════════════════════════════════

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? usuario;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.usuario,
  });

  const AuthState.initial() : this();

  const AuthState.loading() : this(status: AuthStatus.loading);

  const AuthState.authenticated(Map<String, dynamic> usuario)
      : this(
          status: AuthStatus.authenticated,
          usuario: usuario,
        );

  const AuthState.unauthenticated()
      : this(status: AuthStatus.unauthenticated);

  const AuthState.error(String message)
      : this(
          status: AuthStatus.error,
          errorMessage: message,
        );

  bool get isAuthenticated => status == AuthStatus.authenticated;

  @override
  List<Object?> get props => [status, errorMessage, usuario];
}

// ════════════════════════════════════════════════════════════
// CUBIT
// ════════════════════════════════════════════════════════════

class AuthCubit extends Cubit<AuthState> {
  final AuthApi _authApi;

  AuthCubit({AuthApi? authApi})
      : _authApi = authApi ?? AuthApi(),
        super(const AuthState.initial());

  /// Verifica si hay sesión activa (al iniciar la app).
  Future<void> checkSession() async {
    emit(const AuthState.loading());
    try {
      final hasTokens = await _authApi.isLoggedIn();
      if (!hasTokens) {
        emit(const AuthState.unauthenticated());
        return;
      }

      // Intentar refrescar el access token con el refresh token guardado.
      // Si el refresh es válido → sesión restaurada. Si no → login obligatorio.
      // refreshSession() ya retorna el usuario directo (AuthApi.refreshSession
      // devuelve `usuario` o lo que hubiera guardado); NO es un mapa con clave 'usuario'.
      final user = await _authApi.refreshSession();
      if (user != null) {
        emit(AuthState.authenticated(user));
        return;
      }
      // Refresh falló → sesión expirada, limpiar y pedir login
      await _authApi.logout();
      emit(const AuthState.unauthenticated());
    } catch (_) {
      await _authApi.logout();
      emit(const AuthState.unauthenticated());
    }
  }

  /// Inicia sesión con username y contraseña.
  Future<void> login({
    required String username,
    required String password,
  }) async {
    emit(const AuthState.loading());
    try {
      final result = await _authApi.login(
        username: username,
        password: password,
      );
      emit(AuthState.authenticated(result.usuario));
    } on AuthException {
      emit(const AuthState.error('Credenciales inválidas'));
    } on NetworkException {
      emit(const AuthState.error('Sin conexión a internet'));
    } on ApiException catch (e) {
      emit(AuthState.error(e.message));
    } catch (e) {
      emit(AuthState.error('Error al iniciar sesión: $e'));
    }
  }

  /// Cierra sesión.
  Future<void> logout() async {
    try {
      await _authApi.logout();
    } catch (_) {
      // Ignorar errores en logout
    }
    emit(const AuthState.unauthenticated());
  }
}
