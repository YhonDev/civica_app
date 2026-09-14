import 'package:flutter_test/flutter_test.dart';
import 'package:civica_pago_mobile/core/auth/user_role.dart';

void main() {
  group('UserRole Enum Tests', () {
    test('parses ADMIN correctly and case-insensitively', () {
      expect(UserRole.fromString('ADMIN'), equals(UserRole.admin));
      expect(UserRole.fromString('admin'), equals(UserRole.admin));
      expect(UserRole.fromString(' Admin '), equals(UserRole.admin));
      expect(UserRole.admin.isAdmin, isTrue);
      expect(UserRole.admin.isAuthorized, isTrue);
      expect(UserRole.admin.label, equals('Administrador'));
    });

    test('parses COBRADOR correctly', () {
      expect(UserRole.fromString('COBRADOR'), equals(UserRole.cobrador));
      expect(UserRole.fromString('cobrador'), equals(UserRole.cobrador));
      expect(UserRole.cobrador.isCobrador, isTrue);
      expect(UserRole.cobrador.isAuthorized, isTrue);
      expect(UserRole.cobrador.label, equals('Cobrador'));
    });

    test('parses RESIDENTE and PROPIETARIO alias correctly', () {
      expect(UserRole.fromString('RESIDENTE'), equals(UserRole.residente));
      expect(UserRole.fromString('PROPIETARIO'), equals(UserRole.residente));
      expect(UserRole.fromString('residente'), equals(UserRole.residente));
      expect(UserRole.residente.isResidente, isTrue);
      expect(UserRole.residente.isAuthorized, isTrue);
      expect(UserRole.residente.label, equals('Residente'));
    });

    test('parses SUPERADMIN explicitly and does NOT fall back to admin', () {
      expect(UserRole.fromString('SUPERADMIN'), equals(UserRole.superadmin));
      expect(UserRole.fromString('superadmin'), equals(UserRole.superadmin));
      expect(UserRole.superadmin.isAdmin, isFalse);
      expect(UserRole.superadmin.isSuperAdmin, isTrue);
      // Operational app does not grant general tenant access to superadmin
      expect(UserRole.superadmin.isAuthorized, isFalse);
      expect(UserRole.superadmin.label, equals('Superadministrador'));
    });

    test('unknown roles strictly map to unauthorized (no default: ADMIN)', () {
      expect(UserRole.fromString(null), equals(UserRole.unauthorized));
      expect(UserRole.fromString(''), equals(UserRole.unauthorized));
      expect(UserRole.fromString('   '), equals(UserRole.unauthorized));
      expect(UserRole.fromString('INVITADO'), equals(UserRole.unauthorized));
      expect(UserRole.fromString('HACKER'), equals(UserRole.unauthorized));
      expect(UserRole.fromString('ROOT'), equals(UserRole.unauthorized));

      expect(UserRole.unauthorized.isAdmin, isFalse);
      expect(UserRole.unauthorized.isCobrador, isFalse);
      expect(UserRole.unauthorized.isResidente, isFalse);
      expect(UserRole.unauthorized.isAuthorized, isFalse);
      expect(UserRole.unauthorized.label, equals('Sin acceso'));
    });
  });
}
