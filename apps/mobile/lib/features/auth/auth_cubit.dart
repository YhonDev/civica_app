import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../core/network/auth_api.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/base_url.dart';
import '../../core/network/local_cache_repository.dart';
import '../../core/network/realtime_socket_service.dart';

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
        super(const AuthState.initial()) {
    ApiClient.instance.onUnauthorized = () {
      logout();
    };
  }

  void _initRealtimeSocket(Map<String, dynamic> user) async {
    try {
      final tenantId = user['tenantId'] as String? ?? '00000000-0000-0000-0000-000000000001';
      final userId = user['id'] as String? ?? '';
      final residenteId = user['residenteId'] as String?;
      final token = await ApiClient.instance.tokenStorage.getAccessToken();

      final wsUrl = detectWsUrl();
      debugPrint('[AuthCubit] WebSocket URL: $wsUrl');

      RealtimeSocketService.instance.init(
        serverUrl: wsUrl,
        tenantId: tenantId,
        userId: userId,
        token: token,
        residenteId: residenteId,
      );
    } catch (e) {
      debugPrint('[AuthCubit] RealtimeSocket init skipped: $e');
    }
  }

  /// Verifica si hay sesión activa (al iniciar la app).
  Future<void> checkSession() async {
    emit(const AuthState.loading());
    try {
      final hasTokens = await _authApi.isLoggedIn();
      if (!hasTokens) {
        emit(const AuthState.unauthenticated());
        return;
      }

      final cachedUser = await _authApi.getCachedUser();
      final isAccessValid = await _authApi.isAccessTokenValid();

      if (isAccessValid && cachedUser != null) {
        _initRealtimeSocket(cachedUser);
        emit(AuthState.authenticated(cachedUser));
        return;
      }

      try {
        final user = await _authApi.refreshSession();
        if (user != null) {
          _initRealtimeSocket(user);
          emit(AuthState.authenticated(user));
          return;
        }
        await logout();
      } on NetworkException catch (e) {
        if (cachedUser != null) {
          debugPrint('[AuthCubit] Modo offline activo: ${e.message}');
          _initRealtimeSocket(cachedUser);
          emit(AuthState.authenticated(cachedUser));
          return;
        }
        await logout();
      } on AuthException catch (_) {
        await logout();
      }
    } catch (_) {
      await logout();
    }
  }

  /// Inicia sesión con username y contraseña.
  Future<void> login({
    required String username,
    required String password,
    String? deviceId,
    String? deviceName,
  }) async {
    emit(const AuthState.loading());
    try {
      LocalCacheRepository.instance.invalidateAll();
      final result = await _authApi.login(
        username: username,
        password: password,
        deviceId: deviceId,
        deviceName: deviceName,
      );
      _initRealtimeSocket(result.usuario);
      emit(AuthState.authenticated(result.usuario));
    } on AuthException catch (e) {
      final msg = (e.message.isNotEmpty && !e.message.startsWith('Sesión expirada'))
          ? e.message
          : 'Credenciales inválidas';
      emit(AuthState.error(msg));
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
      RealtimeSocketService.instance.disconnect();
      LocalCacheRepository.instance.invalidateAll();
      await _authApi.logout();
    } catch (_) {
      // Ignorar errores en logout
    }
    emit(const AuthState.unauthenticated());
  }
}
