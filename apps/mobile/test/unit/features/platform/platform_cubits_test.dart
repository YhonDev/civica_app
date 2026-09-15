import 'package:flutter_test/flutter_test.dart';
import 'package:civica_pago_mobile/features/platform/cubits/platform_overview_cubit.dart';
import 'package:civica_pago_mobile/features/platform/cubits/platform_tenants_cubit.dart';
import 'package:civica_pago_mobile/features/platform/cubits/tenant_detail_cubit.dart';
import 'package:civica_pago_mobile/features/platform/cubits/platform_audit_cubit.dart';
import 'package:civica_pago_mobile/features/platform/data/platform_api_service.dart';
import 'package:civica_pago_mobile/features/platform/models/platform_models.dart';
import 'package:civica_pago_mobile/core/network/api_client.dart';

class FakePlatformApiService extends PlatformApiService {
  PlatformOverviewData? overviewToReturn;
  List<PlatformTenantSummary> tenantsToReturn = [];
  TenantDetailData? detailToReturn;
  List<TenantInvitationItem> invitationsToReturn = [];
  List<PlatformAuditEventItem> auditEventsToReturn = [];

  bool shouldThrow = false;

  @override
  Future<PlatformOverviewData> getOverview() async {
    if (shouldThrow) throw Exception('Network failure');
    return overviewToReturn ??
        const PlatformOverviewData(
          totalTenants: 2,
          tenantsByStatus: {TenantStatus.active: 2},
          activeUsers: 50,
          projects: 2,
          residents: 48,
        );
  }

  @override
  Future<({List<PlatformTenantSummary> data, int total, int page, int limit})> listTenants({
    int page = 1,
    int limit = 25,
    TenantStatus? status,
  }) async {
    if (shouldThrow) throw Exception('API Error');
    return (data: tenantsToReturn, total: tenantsToReturn.length, page: page, limit: limit);
  }

  @override
  Future<PlatformTenantSummary> createTenant({
    required String name,
    TenantStatus status = TenantStatus.active,
  }) async {
    if (shouldThrow) throw Exception('Creation failed');
    final created = PlatformTenantSummary(
      id: 'new-id',
      name: name,
      status: status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      users: 0,
      projects: 0,
      residents: 0,
      houses: 0,
    );
    tenantsToReturn.add(created);
    return created;
  }

  @override
  Future<PlatformTenantSummary> updateTenantStatus(
    String tenantId,
    TenantStatus status,
  ) async {
    if (shouldThrow) throw Exception('Update failed');
    return PlatformTenantSummary(
      id: tenantId,
      name: 'Updated Tenant',
      status: status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      users: 5,
      projects: 1,
      residents: 4,
      houses: 10,
    );
  }

  @override
  Future<TenantDetailData> getTenantDetail(String tenantId) async {
    if (shouldThrow) throw Exception('Not found');
    return detailToReturn ??
        TenantDetailData(
          tenant: PlatformTenantSummary(
            id: tenantId,
            name: 'Demo Tenant',
            status: TenantStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            users: 10,
            projects: 1,
            residents: 9,
            houses: 12,
          ),
          projects: [
            TenantDetailProject(
              id: 'p-1',
              nombre: 'Etapa Bosque',
              createdAt: DateTime(2026),
              etapas: 1,
              casas: 12,
            ),
          ],
          administrators: [
            TenantDetailAdmin(
              id: 'u-1',
              email: 'admin@demo.com',
              nombre: 'Admin Demo',
              activo: true,
              createdAt: DateTime(2026),
            ),
          ],
          summary: const TenantDetailSummary(
            users: 10,
            residents: 9,
            projects: 1,
          ),
        );
  }

  @override
  Future<List<TenantInvitationItem>> listInvitations(String tenantId) async {
    if (shouldThrow) throw Exception('Invitation error');
    return invitationsToReturn;
  }

  @override
  Future<TenantInvitationItem> createInvitation(
    String tenantId, {
    required String email,
    required String name,
  }) async {
    if (shouldThrow) throw Exception('Failed to invite');
    final item = TenantInvitationItem(
      id: 'inv-new',
      tenantId: tenantId,
      email: email,
      name: name,
      status: 'PENDING',
      expiresAt: DateTime.now().add(const Duration(hours: 48)),
      createdBy: 'superadmin',
      createdAt: DateTime.now(),
      invitationToken: 'secret-token-hex',
    );
    invitationsToReturn.add(item);
    return item;
  }

  @override
  Future<void> revokeInvitation(String invitationId) async {
    if (shouldThrow) throw Exception('Revoke failed');
    invitationsToReturn.removeWhere((inv) => inv.id == invitationId);
  }

  @override
  Future<({List<PlatformAuditEventItem> data, int total, int page, int limit})> getAuditEvents({
    int page = 1,
    int limit = 25,
    String? action,
    String? resource,
  }) async {
    if (shouldThrow) throw Exception('Audit error');
    return (data: auditEventsToReturn, total: auditEventsToReturn.length, page: page, limit: limit);
  }
}

void main() {
  late FakePlatformApiService fakeApi;

  setUpAll(() {
    ApiClient.init(
      baseUrl: 'https://api.cuentiva.test',
      storage: InMemorySecureStorage(),
    );
  });

  setUp(() {
    fakeApi = FakePlatformApiService();
  });

  group('PlatformOverviewCubit', () {
    test('emits Loaded when loadOverview succeeds', () async {
      final cubit = PlatformOverviewCubit(fakeApi);
      expect(cubit.state, isA<PlatformOverviewInitial>());

      await cubit.loadOverview();

      expect(cubit.state, isA<PlatformOverviewLoaded>());
      final loaded = cubit.state as PlatformOverviewLoaded;
      expect(loaded.data.totalTenants, equals(2));
      expect(loaded.data.activeUsers, equals(50));
    });

    test('emits Error when loadOverview fails', () async {
      fakeApi.shouldThrow = true;
      final cubit = PlatformOverviewCubit(fakeApi);

      await cubit.loadOverview();

      expect(cubit.state, isA<PlatformOverviewError>());
    });
  });

  group('PlatformTenantsCubit', () {
    test('loads tenants and filters by search query locally', () async {
      fakeApi.tenantsToReturn = [
        PlatformTenantSummary(
          id: 't-1',
          name: 'Villa Campestre',
          status: TenantStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          users: 10,
          projects: 1,
          residents: 8,
          houses: 12,
        ),
        PlatformTenantSummary(
          id: 't-2',
          name: 'Altos del Bosque',
          status: TenantStatus.suspended,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          users: 2,
          projects: 1,
          residents: 2,
          houses: 4,
        ),
      ];

      final cubit = PlatformTenantsCubit(fakeApi);
      await cubit.loadTenants();

      expect(cubit.state.tenants.length, equals(2));
      expect(cubit.state.filteredTenants.length, equals(2));

      // Filter by search query
      cubit.updateSearchQuery('Altos');
      expect(cubit.state.filteredTenants.length, equals(1));
      expect(cubit.state.filteredTenants.first.name, equals('Altos del Bosque'));
    });

    test('creates tenant and appends to local list', () async {
      final cubit = PlatformTenantsCubit(fakeApi);
      final ok = await cubit.createTenant(
        name: 'Nuevo Proyecto',
        status: TenantStatus.active,
      );

      expect(ok, isTrue);
      expect(cubit.state.tenants.length, equals(1));
      expect(cubit.state.tenants.first.name, equals('Nuevo Proyecto'));
      expect(cubit.state.successMessage, contains('Nuevo Proyecto'));
    });
  });

  group('TenantDetailCubit', () {
    test('loads tenant details and invitations', () async {
      final cubit = TenantDetailCubit(fakeApi);
      await cubit.loadDetail('tenant-123');

      expect(cubit.state.data, isNotNull);
      expect(cubit.state.data!.tenant.id, equals('tenant-123'));
      expect(cubit.state.data!.projects.length, equals(1));
      expect(cubit.state.data!.administrators.length, equals(1));
    });

    test('creates cryptographic invitation and holds lastCreatedInvitation', () async {
      final cubit = TenantDetailCubit(fakeApi);
      await cubit.loadDetail('tenant-123');

      final inv = await cubit.createInvitation(
        tenantId: 'tenant-123',
        email: 'nuevo@admin.com',
        name: 'Nuevo Admin',
      );

      expect(inv, isNotNull);
      expect(inv!.invitationToken, equals('secret-token-hex'));
      expect(cubit.state.lastCreatedInvitation, equals(inv));
      expect(cubit.state.invitations.length, equals(1));
    });

    test('revokes invitation successfully', () async {
      fakeApi.invitationsToReturn = [
        TenantInvitationItem(
          id: 'inv-to-cancel',
          tenantId: 'tenant-123',
          email: 'cancel@me.com',
          name: 'Cancel Me',
          status: 'PENDING',
          expiresAt: DateTime.now().add(const Duration(hours: 48)),
          createdBy: 'superadmin',
          createdAt: DateTime.now(),
        ),
      ];

      final cubit = TenantDetailCubit(fakeApi);
      await cubit.loadDetail('tenant-123');
      expect(cubit.state.invitations.length, equals(1));

      final ok = await cubit.revokeInvitation(
        tenantId: 'tenant-123',
        invitationId: 'inv-to-cancel',
      );

      expect(ok, isTrue);
      expect(cubit.state.invitations.isEmpty, isTrue);
    });
  });

  group('PlatformAuditCubit', () {
    test('loads audit events successfully', () async {
      fakeApi.auditEventsToReturn = [
        PlatformAuditEventItem(
          id: 'ev-1',
          action: 'PLATFORM_LOGIN',
          resource: 'platform_session',
          createdAt: DateTime.now(),
        ),
      ];

      final cubit = PlatformAuditCubit(fakeApi);
      await cubit.loadEvents();

      expect(cubit.state.events.length, equals(1));
      expect(cubit.state.events.first.action, equals('PLATFORM_LOGIN'));
    });
  });
}
