import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/features/auth/auth_cubit.dart';
import 'package:civica_pago_mobile/core/network/auth_api.dart';
import 'package:civica_pago_mobile/core/network/api_exceptions.dart';
/// Fake [AuthApi] that returns configurable results for testing.
class FakeAuthApi extends AuthApi {
  final LoginResult? loginResult;
  final Object? loginError;
  final Object? logoutError;

  bool logoutCalled = false;

  // Controles para checkSession / refreshSession.
  bool hasTokens = false;
  bool accessValid = false;
  Map<String, dynamic>? cachedUser;
  Object? refreshError;
  Map<String, dynamic>? refreshResult;

  FakeAuthApi({
    this.loginResult,
    this.loginError,
    this.logoutError,
  }) : super(null);

  @override
  Future<bool> isLoggedIn() async => hasTokens;

  @override
  Future<bool> isAccessTokenValid() async => accessValid;

  @override
  Future<Map<String, dynamic>?> getCachedUser() async => cachedUser;

  @override
  Future<Map<String, dynamic>?> refreshSession() async {
    if (refreshError != null) throw refreshError!;
    return refreshResult;
  }

  @override
  Future<LoginResult> login({
    required String username,
    required String password,
    String? deviceId,
    String? deviceName,
  }) async {
    if (loginError != null) throw loginError!;
    return loginResult ?? LoginResult(
      accessToken: 'mock-token',
      refreshToken: 'mock-refresh',
      usuario: const {'nombre': 'Test', 'rol': 'ADMIN'},
    );
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    if (logoutError != null) throw logoutError!;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.init(baseUrl: 'http://test.local');
  });

  group('AuthState', () {
    test('initial tiene status initial', () {
      const state = AuthState();
      expect(state.status, AuthStatus.initial);
      expect(state.isAuthenticated, false);
      expect(state.errorMessage, isNull);
      expect(state.usuario, isNull);
    });

    test('AuthState.initial() equals AuthState()', () {
      const a = AuthState();
      const b = AuthState.initial();
      expect(a, equals(b));
    });

    test('AuthState.loading() tiene status loading', () {
      const state = AuthState.loading();
      expect(state.status, AuthStatus.loading);
      expect(state.isAuthenticated, false);
    });

    test('AuthState.authenticated() tiene usuario', () {
      const usuario = {'nombre': 'Admin', 'rol': 'ADMIN'};
      final state = AuthState.authenticated(usuario);
      expect(state.status, AuthStatus.authenticated);
      expect(state.isAuthenticated, true);
      expect(state.usuario, usuario);
    });

    test('AuthState.unauthenticated() tiene status unauthenticated', () {
      const state = AuthState.unauthenticated();
      expect(state.status, AuthStatus.unauthenticated);
    });

    test('AuthState.error() tiene mensaje', () {
      const state = AuthState.error('Error');
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, 'Error');
    });

    test('Equatable — igualdad por valor', () {
      const a = AuthState.authenticated({'nombre': 'A'});
      const b = AuthState.authenticated({'nombre': 'A'});
      const c = AuthState.authenticated({'nombre': 'B'});
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('AuthCubit.checkSession', () {
    test('emite loading → unauthenticated cuando no hay tokens', () async {
      final api = FakeAuthApi();
      final cubit = AuthCubit(authApi: api);
      addTearDown(() => cubit.close());

      expect(cubit.state, const AuthState.initial());
      await cubit.checkSession();
      expect(cubit.state.status, AuthStatus.unauthenticated);
    });

    test('unauthenticated incluso si logout falla', () async {
      final api = FakeAuthApi(logoutError: Exception('falló'));
      final cubit = AuthCubit(authApi: api);
      addTearDown(() => cubit.close());

      await cubit.checkSession();
      expect(cubit.state.status, AuthStatus.unauthenticated);
    });

    test('forceRestore con usuario en caché entra autenticado y refresca en background', () async {
      final api = FakeAuthApi()
        ..hasTokens = true
        ..accessValid = false
        ..cachedUser = const {'nombre': 'Cobrador', 'rol': 'COBRADOR'}
        ..refreshResult = const {'nombre': 'Cobrador', 'rol': 'COBRADOR'};
      final cubit = AuthCubit(authApi: api);
      addTearDown(() => cubit.close());

      await cubit.checkSession(forceRestore: true);
      expect(cubit.state.status, AuthStatus.authenticated);

      // El refresh en background resuelve y re-emite autenticado.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.status, AuthStatus.authenticated);
      expect(api.logoutCalled, false);
    });

    test('forceRestore + refresh con AuthException → logout (sesión revocada)', () async {
      // Storage en memoria: sin plataforma, determinista.
      ApiClient.init(
        baseUrl: 'http://test.local',
        storage: InMemorySecureStorage(),
      );
      final api = FakeAuthApi()
        ..hasTokens = true
        ..accessValid = false
        ..cachedUser = const {'nombre': 'Cobrador', 'rol': 'COBRADOR'}
        ..refreshError = const AuthException(message: 'Sesión expirada');
      final cubit = AuthCubit(authApi: api);
      addTearDown(() => cubit.close());

      await cubit.checkSession(forceRestore: true);
      // Entra autenticado con datos locales (desbloqueo biométrico).
      expect(cubit.state.status, AuthStatus.authenticated);

      // El refresh falla con AuthException → debe cerrar sesión.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.status, AuthStatus.unauthenticated);
      expect(api.logoutCalled, true);
    });
  });

  group('AuthCubit.login', () {
    test('exitoso → authenticated', () async {
      const usuario = {'nombre': 'Admin', 'rol': 'ADMIN'};
      final api = FakeAuthApi(loginResult: const LoginResult(
        accessToken: 't1', refreshToken: 'r1', usuario: usuario,
      ));
      final cubit = AuthCubit(authApi: api);
      addTearDown(() => cubit.close());

      await cubit.login(username: 'a@b.com', password: 'p');
      expect(cubit.state.status, AuthStatus.authenticated);
      expect(cubit.state.usuario, usuario);
    });

    test('AuthException → "Credenciales inválidas"', () async {
      final api = FakeAuthApi(loginError: const AuthException());
      final cubit = AuthCubit(authApi: api);
      addTearDown(() => cubit.close());

      await cubit.login(username: 'bad@test.com', password: 'wrong');
      expect(cubit.state.status, AuthStatus.error);
      expect(cubit.state.errorMessage, 'Credenciales inválidas');
    });

    test('NetworkException → "Sin conexión a internet"', () async {
      final api = FakeAuthApi(loginError: const NetworkException());
      final cubit = AuthCubit(authApi: api);
      addTearDown(() => cubit.close());

      await cubit.login(username: 'a@b.com', password: 'p');
      expect(cubit.state.status, AuthStatus.error);
      expect(cubit.state.errorMessage, 'Sin conexión a internet');
    });

    test('ApiException genérico → mensaje del error', () async {
      final api = FakeAuthApi(
        loginError: const ApiException(message: 'Error 500', statusCode: 500),
      );
      final cubit = AuthCubit(authApi: api);
      addTearDown(() => cubit.close());

      await cubit.login(username: 'a@b.com', password: 'p');
      expect(cubit.state.status, AuthStatus.error);
      expect(cubit.state.errorMessage, 'Error 500');
    });

    test('error genérico → mensaje por defecto', () async {
      final api = FakeAuthApi(loginError: Exception('Algo falló'));
      final cubit = AuthCubit(authApi: api);
      addTearDown(() => cubit.close());

      await cubit.login(username: 'a@b.com', password: 'p');
      expect(cubit.state.status, AuthStatus.error);
      expect(cubit.state.errorMessage, 'Algo falló');
    });

    test('error técnico DioException se sanitiza a mensaje seguro de red', () async {
      final api = FakeAuthApi(loginError: Exception('DioException [bad response]: 500'));
      final cubit = AuthCubit(authApi: api);
      addTearDown(() => cubit.close());

      await cubit.login(username: 'a@b.com', password: 'p');
      expect(cubit.state.status, AuthStatus.error);
      expect(cubit.state.errorMessage, 'No se pudo conectar con el servidor. Verifica tu conexión a internet.');
    });
  });

  group('AuthCubit.logout', () {
    test('cierra sesión → unauthenticated', () async {
      final api = FakeAuthApi();
      final cubit = AuthCubit(authApi: api);
      addTearDown(() => cubit.close());

      await cubit.login(username: 'a@b.com', password: 'p');
      expect(cubit.state.isAuthenticated, true);

      await cubit.logout();
      expect(cubit.state.status, AuthStatus.unauthenticated);
      expect(api.logoutCalled, true);
    });

    test('ignora errores de la API', () async {
      final api = FakeAuthApi(logoutError: Exception('falló'));
      final cubit = AuthCubit(authApi: api);
      addTearDown(() => cubit.close());

      await cubit.logout();
      expect(cubit.state.status, AuthStatus.unauthenticated);
      expect(api.logoutCalled, true);
    });
  });
}
