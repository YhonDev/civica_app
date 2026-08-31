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
  });
}
