import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:civica_pago_mobile/core/security/biometric_auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BiometricAuthService Preference Tests', () {
    late BiometricAuthService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = BiometricAuthService.instance;
    });

    test('isBiometricsEnabled returns false by default', () async {
      final enabled = await service.isBiometricsEnabled();
      expect(enabled, isFalse);
    });

    test('setBiometricsEnabled updates preference', () async {
      await service.setBiometricsEnabled(true);
      final enabled = await service.isBiometricsEnabled();
      expect(enabled, isTrue);
    });

    // ── Migración passwordless (v2) ──────────────────────────────
    // La v1 guardaba la contraseña en secure storage para re-login
    // biométrico. Desde la migración solo se restauran sesiones con el
    // refresh token y las claves legacy se borran una única vez.

    test('migración legacy: isBiometricsEnabled completa sin lanzar', () async {
      // En entorno de test no hay plataforma secure-storage; la limpieza
      // legacy debe degradar con gracia (try/catch) y no afectar la lectura.
      final enabled = await service.isBiometricsEnabled();
      expect(enabled, isFalse);

      // Segunda llamada: el flag estático evita repetir la limpieza.
      final enabledAgain = await service.isBiometricsEnabled();
      expect(enabledAgain, isFalse);
    });

    test('clearBiometricCredentials es idempotente y no lanza', () async {
      // Llamarla dos veces seguidas (p.ej. doble logout) no debe fallar.
      await service.clearBiometricCredentials();
      await service.clearBiometricCredentials();
    });
  });
}
