import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../models/platform_models.dart';

/// Service responsible for communicating with the `/platform/*` endpoints.
///
/// Protected exclusively by `PlatformAdminGuard` on the backend.
class PlatformApiService {
  final ApiClient? _client;

  PlatformApiService([ApiClient? client]) : _client = client;

  ApiClient get _apiClient => _client ?? ApiClient.instance;

  /// Retrieves global aggregated KPIs and health for the platform overview.
  Future<PlatformOverviewData> getOverview() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/platform/overview');
      final data = response.data;
      if (data == null) {
        throw const ApiException(message: 'Respuesta vacía del overview de plataforma');
      }
      return PlatformOverviewData.fromJson(data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Lists tenants with optional status filtering and pagination.
  Future<({List<PlatformTenantSummary> data, int total, int page, int limit})> listTenants({
    int page = 1,
    int limit = 25,
    TenantStatus? status,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (status != null) {
        query['status'] = status.toApiString();
      }

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/platform/tenants',
        queryParameters: query,
      );
      final data = response.data;
      if (data == null) {
        return (data: <PlatformTenantSummary>[], total: 0, page: page, limit: limit);
      }

      final rawList = data['data'] as List<dynamic>? ?? [];
      final list = rawList
          .map((item) => PlatformTenantSummary.fromJson(item as Map<String, dynamic>))
          .toList();
      final total = (data['total'] as num?)?.toInt() ?? 0;

      return (data: list, total: total, page: page, limit: limit);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Creates a new tenant in Cuentiva Platform.
  Future<PlatformTenantSummary> createTenant({
    required String name,
    TenantStatus status = TenantStatus.active,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/platform/tenants',
        data: {
          'name': name.trim(),
          'status': status.toApiString(),
        },
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(message: 'Error al crear tenant: respuesta vacía');
      }
      return PlatformTenantSummary.fromJson(data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Retrieves full details of a specific tenant including projects, admins, and stats.
  Future<TenantDetailData> getTenantDetail(String tenantId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/platform/tenants/$tenantId');
      final data = response.data;
      if (data == null) {
        throw const ApiException(message: 'No se encontraron datos del tenant');
      }
      return TenantDetailData.fromJson(data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Updates the status of a tenant (ACTIVE, SUSPENDED, MAINTENANCE, ARCHIVED).
  Future<PlatformTenantSummary> updateTenantStatus(
    String tenantId,
    TenantStatus status,
  ) async {
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '/platform/tenants/$tenantId/status',
        data: {'status': status.toApiString()},
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(message: 'Error al actualizar estado del tenant');
      }
      return PlatformTenantSummary.fromJson(data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Issues a single-use cryptographic invitation for a new tenant administrator.
  Future<TenantInvitationItem> createInvitation(
    String tenantId, {
    required String email,
    required String name,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/platform/tenants/$tenantId/invitations',
        data: {
          'email': email.trim().toLowerCase(),
          'name': name.trim(),
        },
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException(message: 'Error al generar invitación: respuesta vacía');
      }
      return TenantInvitationItem.fromJson(data);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Lists administrator invitations for a specific tenant.
  Future<List<TenantInvitationItem>> listInvitations(String tenantId) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/platform/tenants/$tenantId/invitations',
      );
      final data = response.data ?? [];
      return data
          .map((item) => TenantInvitationItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Revokes a pending administrator invitation.
  Future<void> revokeInvitation(String invitationId) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '/platform/invitations/$invitationId/revoke',
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Retrieves paginated immutable audit logs from the platform.
  Future<({List<PlatformAuditEventItem> data, int total, int page, int limit})> getAuditEvents({
    int page = 1,
    int limit = 25,
    String? action,
    String? resource,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (action != null && action.isNotEmpty) query['action'] = action;
      if (resource != null && resource.isNotEmpty) query['resource'] = resource;

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/platform/audit',
        queryParameters: query,
      );
      final data = response.data;
      if (data == null) {
        return (data: <PlatformAuditEventItem>[], total: 0, page: page, limit: limit);
      }

      final rawList = data['data'] as List<dynamic>? ?? [];
      final list = rawList
          .map((item) => PlatformAuditEventItem.fromJson(item as Map<String, dynamic>))
          .toList();
      final total = (data['total'] as num?)?.toInt() ?? 0;

      return (data: list, total: total, page: page, limit: limit);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
