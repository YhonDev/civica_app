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

  FakeAuthApi({
    this.loginResult,
    this.loginError,
    this.logoutError,
  }) : super(null);

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
      expect(cubit.state.errorMessage, contains('Algo falló'));
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
