import 'package:flutter_test/flutter_test.dart';
import 'package:civica_pago_mobile/core/network/api_client.dart';

void main() {
  group('redactSensitiveData', () {
    test('redacts password and currentPassword in request map', () {
      final input = {
        'username': 'carlos_admin',
        'password': 'SuperSecretPassword123!',
        'currentPassword': 'OldPassword456!',
        'newPassword': 'BrandNewPassword789!',
      };

      final result = redactSensitiveData(input) as Map<String, dynamic>;

      expect(result['username'], equals('carlos_admin'));
      expect(result['password'], equals('[REDACTED]'));
      expect(result['currentPassword'], equals('[REDACTED]'));
      expect(result['newPassword'], equals('[REDACTED]'));
    });

    test('redacts accessToken and refreshToken in response map', () {
      final input = {
        'accessToken': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
        'refreshToken': 'def456...',
        'usuario': {
          'id': 'user-1',
          'nombre': 'Carlos Cobrador',
          'passwordHash': 'hashed_value',
        },
      };

      final result = redactSensitiveData(input) as Map<String, dynamic>;

      expect(result['accessToken'], equals('[REDACTED]'));
      expect(result['refreshToken'], equals('[REDACTED]'));
      final nested = result['usuario'] as Map<String, dynamic>;
      expect(nested['id'], equals('user-1'));
      expect(nested['nombre'], equals('Carlos Cobrador'));
      expect(nested['passwordHash'], equals('[REDACTED]'));
    });

    test('handles nested lists and non-map data smoothly', () {
      final input = [
        {'id': 1, 'token': 'abc'},
        {'id': 2, 'safe': 'xyz'},
      ];

      final result = redactSensitiveData(input) as List;

      expect(result[0]['token'], equals('[REDACTED]'));
      expect(result[1]['safe'], equals('xyz'));
    });
  });
}
