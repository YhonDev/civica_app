import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../core/network/auth_api.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/base_url.dart';
import '../../core/network/error_messages.dart';
import '../../core/network/local_cache_repository.dart';
import '../../core/network/realtime_socket_service.dart';
import '../../core/security/biometric_auth_service.dart';

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
      if (token == null || token.isEmpty) {
        debugPrint('[AuthCubit] RealtimeSocket init skipped: no access token');
        return;
      }

      final wsUrl = detectWsUrl();
      debugPrint('[AuthCubit] Initializing realtime connection');

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
  Future<void> checkSession({bool forceRestore = false}) async {
    emit(const AuthState.loading());
    try {
      final hasTokens = await _authApi.isLoggedIn();
      if (!hasTokens) {
        emit(const AuthState.unauthenticated());
        return;
      }

      // Si la biometría está habilitada y es arranque en frío, abrimos en LoginScreen
      // para permitir al usuario ingresar mediante huella dactilar o contraseña
      final isBioEnabled = await BiometricAuthService.instance.isBiometricsEnabled();
      if (isBioEnabled && !forceRestore) {
        debugPrint('[AuthCubit] Cold start con biometría activa: mostrando LoginScreen');
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

      // Si se solicita forceRestore (autenticación biométrica exitosa) y tenemos
      // el usuario en caché, entramos inmediatamente sin bloquear por arranque en frío
      if (forceRestore && cachedUser != null) {
        _initRealtimeSocket(cachedUser);
        emit(AuthState.authenticated(cachedUser));
        unawaited(_authApi.refreshSession().then((user) {
          if (user != null) {
            emit(AuthState.authenticated(user));
          }
        }).catchError((e) {
          debugPrint('[AuthCubit] Background refresh after biometric unlock: $e');
          // Refresh token revocado/expirado: la sesión ya no es válida.
          // Cerrar sesión en vez de permanecer "autenticado" con datos locales.
          if (e is AuthException) {
            unawaited(logout());
          }
        }));
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
      emit(AuthState.error(_sanitizeErrorMessage(e.message)));
    } catch (e, stack) {
      debugPrint('[AuthCubit] Error inesperado en login: $e\n$stack');
      emit(AuthState.error(_sanitizeErrorMessage(e)));
    }
  }

  /// Delega en el sanitizador compartido (core/network/error_messages.dart).
  /// Pasa el OBJETO del error (no toString): el sanitizador distingue tipos
  /// y evita filtrar diagnostics técnicos en la UI.
  String _sanitizeErrorMessage(Object error) => sanitizeApiError(error);

  /// Limpia cualquier mensaje de error en la pantalla de login.
  void clearError() {
    if (state.errorMessage != null) {
      emit(const AuthState.unauthenticated());
    }
  }

  /// Cierra sesión.
  Future<void> logout() async {
    try {
      RealtimeSocketService.instance.disconnect();
    } catch (_) {}
    try {
      LocalCacheRepository.instance.invalidateAll();
    } catch (_) {}
    try {
      await BiometricAuthService.instance.clearBiometricCredentials();
      await BiometricAuthService.instance.setBiometricsEnabled(false);
    } catch (_) {}
    try {
      await _authApi.logout();
    } catch (_) {
      // Ignorar errores de red o API en logout
    }
    emit(const AuthState.unauthenticated());
  }
}
