import 'package:flutter_test/flutter_test.dart';
import 'package:civica_pago_mobile/features/platform/models/platform_models.dart';

void main() {
  group('TenantStatus', () {
    test('parses status strings correctly', () {
      expect(TenantStatus.fromString('ACTIVE'), equals(TenantStatus.active));
      expect(TenantStatus.fromString('suspended'), equals(TenantStatus.suspended));
      expect(TenantStatus.fromString('MAINTENANCE'), equals(TenantStatus.maintenance));
      expect(TenantStatus.fromString('archived'), equals(TenantStatus.archived));
      expect(TenantStatus.fromString(null), equals(TenantStatus.active));
      expect(TenantStatus.fromString('UNKNOWN'), equals(TenantStatus.active));
    });

    test('converts to api strings properly', () {
      expect(TenantStatus.active.toApiString(), equals('ACTIVE'));
      expect(TenantStatus.suspended.toApiString(), equals('SUSPENDED'));
      expect(TenantStatus.maintenance.toApiString(), equals('MAINTENANCE'));
      expect(TenantStatus.archived.toApiString(), equals('ARCHIVED'));
    });

    test('returns correct localized labels', () {
      expect(TenantStatus.active.label, equals('Activo'));
      expect(TenantStatus.suspended.label, equals('Suspendido'));
      expect(TenantStatus.maintenance.label, equals('Mantenimiento'));
      expect(TenantStatus.archived.label, equals('Archivado'));
    });
  });

  group('PlatformTenantSummary', () {
    test('deserializes JSON properly', () {
      final json = {
        'id': 'tenant-123',
        'name': 'Altos del Bosque',
        'status': 'ACTIVE',
        'createdAt': '2026-09-14T20:00:00.000Z',
        'updatedAt': '2026-09-14T21:00:00.000Z',
        'users': 25,
        'projects': 2,
        'residents': 24,
        'houses': 30,
      };

      final summary = PlatformTenantSummary.fromJson(json);

      expect(summary.id, equals('tenant-123'));
      expect(summary.name, equals('Altos del Bosque'));
      expect(summary.status, equals(TenantStatus.active));
      expect(summary.users, equals(25));
      expect(summary.projects, equals(2));
      expect(summary.residents, equals(24));
      expect(summary.houses, equals(30));
    });
  });

  group('PlatformOverviewData', () {
    test('deserializes aggregated metrics and status counts', () {
      final json = {
        'tenants': {
          'total': 4,
          'byStatus': [
            {'status': 'ACTIVE', 'count': 3},
            {'status': 'SUSPENDED', 'count': 1},
          ],
        },
        'activeUsers': 185,
        'projects': 5,
        'residents': 180,
      };

      final data = PlatformOverviewData.fromJson(json);

      expect(data.totalTenants, equals(4));
      expect(data.tenantsByStatus[TenantStatus.active], equals(3));
      expect(data.tenantsByStatus[TenantStatus.suspended], equals(1));
      expect(data.tenantsByStatus[TenantStatus.maintenance], equals(0));
      expect(data.activeUsers, equals(185));
      expect(data.projects, equals(5));
      expect(data.residents, equals(180));
    });
  });

  group('TenantInvitationItem', () {
    test('computes status flags correctly', () {
      final pendingInv = TenantInvitationItem.fromJson({
        'id': 'inv-1',
        'tenantId': 'tenant-1',
        'email': 'admin@demo.com',
        'name': 'Admin Demo',
        'status': 'PENDING',
        'expiresAt': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
        'createdBy': 'superadmin-1',
        'createdAt': DateTime.now().toIso8601String(),
        'invitationToken': 'test-invitation-token',
      });

      expect(pendingInv.isPending, isTrue);
      expect(pendingInv.isAccepted, isFalse);
      expect(pendingInv.isRevoked, isFalse);
      expect(pendingInv.isExpired, isFalse);
      expect(pendingInv.invitationToken, equals('test-invitation-token'));

      final expiredInv = TenantInvitationItem.fromJson({
        'id': 'inv-2',
        'tenantId': 'tenant-1',
        'email': 'expired@demo.com',
        'name': 'Expired Admin',
        'status': 'PENDING',
        'expiresAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        'createdBy': 'superadmin-1',
        'createdAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      });

      expect(expiredInv.isExpired, isTrue);
    });
  });

  group('PlatformAuditEventItem', () {
    test('deserializes audit record with metadata', () {
      final json = {
        'id': 'audit-1',
        'actorId': 'actor-999',
        'action': 'TENANT_CREATED',
        'resource': 'tenant',
        'resourceId': 'tenant-123',
        'requestId': 'req-abc',
        'ipAddress': '192.168.1.1',
        'metadata': {'name': 'Altos del Bosque', 'status': 'ACTIVE'},
        'createdAt': '2026-09-14T20:00:00.000Z',
      };

      final event = PlatformAuditEventItem.fromJson(json);

      expect(event.id, equals('audit-1'));
      expect(event.actorId, equals('actor-999'));
      expect(event.action, equals('TENANT_CREATED'));
      expect(event.resource, equals('tenant'));
      expect(event.resourceId, equals('tenant-123'));
      expect(event.metadata?['name'], equals('Altos del Bosque'));
    });
  });
}
