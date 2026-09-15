import 'package:equatable/equatable.dart';

/// Lifecycle statuses for a tenant in Cuentiva Platform.
enum TenantStatus {
  active,
  suspended,
  maintenance,
  archived;

  static TenantStatus fromString(String? raw) {
    if (raw == null) return TenantStatus.active;
    switch (raw.trim().toUpperCase()) {
      case 'ACTIVE':
        return TenantStatus.active;
      case 'SUSPENDED':
        return TenantStatus.suspended;
      case 'MAINTENANCE':
        return TenantStatus.maintenance;
      case 'ARCHIVED':
        return TenantStatus.archived;
      default:
        return TenantStatus.active;
    }
  }

  String toApiString() {
    switch (this) {
      case TenantStatus.active:
        return 'ACTIVE';
      case TenantStatus.suspended:
        return 'SUSPENDED';
      case TenantStatus.maintenance:
        return 'MAINTENANCE';
      case TenantStatus.archived:
        return 'ARCHIVED';
    }
  }

  String get label {
    switch (this) {
      case TenantStatus.active:
        return 'Activo';
      case TenantStatus.suspended:
        return 'Suspendido';
      case TenantStatus.maintenance:
        return 'Mantenimiento';
      case TenantStatus.archived:
        return 'Archivado';
    }
  }
}

/// Summary item for tenant inventory in platform administration.
class PlatformTenantSummary extends Equatable {
  final String id;
  final String name;
  final TenantStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int users;
  final int projects;
  final int residents;
  final int houses;

  const PlatformTenantSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.users,
    required this.projects,
    required this.residents,
    required this.houses,
  });

  factory PlatformTenantSummary.fromJson(Map<String, dynamic> json) {
    return PlatformTenantSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Sin nombre',
      status: TenantStatus.fromString(json['status'] as String?),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      users: (json['users'] as num?)?.toInt() ?? 0,
      projects: (json['projects'] as num?)?.toInt() ?? 0,
      residents: (json['residents'] as num?)?.toInt() ?? 0,
      houses: (json['houses'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        status,
        createdAt,
        updatedAt,
        users,
        projects,
        residents,
        houses,
      ];
}

/// Aggregated KPIs for Cuentiva Platform Overview.
class PlatformOverviewData extends Equatable {
  final int totalTenants;
  final Map<TenantStatus, int> tenantsByStatus;
  final int activeUsers;
  final int projects;
  final int residents;

  const PlatformOverviewData({
    required this.totalTenants,
    required this.tenantsByStatus,
    required this.activeUsers,
    required this.projects,
    required this.residents,
  });

  factory PlatformOverviewData.fromJson(Map<String, dynamic> json) {
    final tenantsMap = <TenantStatus, int>{
      TenantStatus.active: 0,
      TenantStatus.suspended: 0,
      TenantStatus.maintenance: 0,
      TenantStatus.archived: 0,
    };

    final tenantsObj = json['tenants'] as Map<String, dynamic>? ?? {};
    final byStatusList = tenantsObj['byStatus'] as List<dynamic>? ?? [];
    for (final item in byStatusList) {
      if (item is Map<String, dynamic>) {
        final status = TenantStatus.fromString(item['status'] as String?);
        final count = (item['count'] as num?)?.toInt() ?? 0;
        tenantsMap[status] = count;
      }
    }

    final int calculatedTotal = tenantsMap.values.fold<int>(0, (int sum, int count) => sum + count);
    final int totalTenants = (tenantsObj['total'] as num?)?.toInt() ?? calculatedTotal;

    return PlatformOverviewData(
      totalTenants: totalTenants,
      tenantsByStatus: tenantsMap,
      activeUsers: (json['activeUsers'] as num?)?.toInt() ?? 0,
      projects: (json['projects'] as num?)?.toInt() ?? 0,
      residents: (json['residents'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        totalTenants,
        tenantsByStatus,
        activeUsers,
        projects,
        residents,
      ];
}

/// Project summary inside a tenant detail.
class TenantDetailProject extends Equatable {
  final String id;
  final String nombre;
  final DateTime createdAt;
  final int etapas;
  final int casas;

  const TenantDetailProject({
    required this.id,
    required this.nombre,
    required this.createdAt,
    required this.etapas,
    required this.casas,
  });

  factory TenantDetailProject.fromJson(Map<String, dynamic> json) {
    return TenantDetailProject(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? 'Proyecto',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      etapas: (json['etapas'] as num?)?.toInt() ?? 0,
      casas: (json['casas'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, nombre, createdAt, etapas, casas];
}

/// Tenant administrator entry.
class TenantDetailAdmin extends Equatable {
  final String id;
  final String email;
  final String nombre;
  final bool activo;
  final DateTime createdAt;

  const TenantDetailAdmin({
    required this.id,
    required this.email,
    required this.nombre,
    required this.activo,
    required this.createdAt,
  });

  factory TenantDetailAdmin.fromJson(Map<String, dynamic> json) {
    return TenantDetailAdmin(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      activo: json['activo'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, email, nombre, activo, createdAt];
}

/// Aggregate summary metrics inside tenant detail.
class TenantDetailSummary extends Equatable {
  final int users;
  final int residents;
  final int projects;

  const TenantDetailSummary({
    required this.users,
    required this.residents,
    required this.projects,
  });

  factory TenantDetailSummary.fromJson(Map<String, dynamic> json) {
    return TenantDetailSummary(
      users: (json['users'] as num?)?.toInt() ?? 0,
      residents: (json['residents'] as num?)?.toInt() ?? 0,
      projects: (json['projects'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [users, residents, projects];
}

/// Full detail information of a specific tenant.
class TenantDetailData extends Equatable {
  final PlatformTenantSummary tenant;
  final List<TenantDetailProject> projects;
  final List<TenantDetailAdmin> administrators;
  final TenantDetailSummary summary;

  const TenantDetailData({
    required this.tenant,
    required this.projects,
    required this.administrators,
    required this.summary,
  });

  factory TenantDetailData.fromJson(Map<String, dynamic> json) {
    final tenantJson = json['tenant'] as Map<String, dynamic>? ?? {};
    final projectsList = (json['projects'] as List<dynamic>? ?? [])
        .map((p) => TenantDetailProject.fromJson(p as Map<String, dynamic>))
        .toList();
    final adminsList = (json['administrators'] as List<dynamic>? ?? [])
        .map((a) => TenantDetailAdmin.fromJson(a as Map<String, dynamic>))
        .toList();
    final summaryObj = TenantDetailSummary.fromJson(
      json['summary'] as Map<String, dynamic>? ?? {},
    );

    return TenantDetailData(
      tenant: PlatformTenantSummary.fromJson(tenantJson),
      projects: projectsList,
      administrators: adminsList,
      summary: summaryObj,
    );
  }

  @override
  List<Object?> get props => [tenant, projects, administrators, summary];
}

/// Cryptographic tenant administrator invitation item.
class TenantInvitationItem extends Equatable {
  final String id;
  final String tenantId;
  final String email;
  final String name;
  final String status;
  final DateTime expiresAt;
  final DateTime? acceptedAt;
  final String createdBy;
  final DateTime createdAt;
  final String? invitationToken;

  const TenantInvitationItem({
    required this.id,
    required this.tenantId,
    required this.email,
    required this.name,
    required this.status,
    required this.expiresAt,
    this.acceptedAt,
    required this.createdBy,
    required this.createdAt,
    this.invitationToken,
  });

  bool get isPending => status == 'PENDING';
  bool get isAccepted => status == 'ACCEPTED';
  bool get isRevoked => status == 'REVOKED';
  bool get isExpired => status == 'EXPIRED' || (isPending && DateTime.now().isAfter(expiresAt));

  factory TenantInvitationItem.fromJson(Map<String, dynamic> json) {
    return TenantInvitationItem(
      id: json['id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? '') ?? DateTime.now(),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.tryParse(json['acceptedAt'] as String)
          : null,
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      invitationToken: json['invitationToken'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tenantId,
        email,
        name,
        status,
        expiresAt,
        acceptedAt,
        createdBy,
        createdAt,
        invitationToken,
      ];
}

/// Immutable audit event item for the platform console.
class PlatformAuditEventItem extends Equatable {
  final String id;
  final String? actorId;
  final String action;
  final String resource;
  final String? resourceId;
  final String? requestId;
  final String? ipAddress;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const PlatformAuditEventItem({
    required this.id,
    this.actorId,
    required this.action,
    required this.resource,
    this.resourceId,
    this.requestId,
    this.ipAddress,
    this.metadata,
    required this.createdAt,
  });

  factory PlatformAuditEventItem.fromJson(Map<String, dynamic> json) {
    return PlatformAuditEventItem(
      id: json['id'] as String? ?? '',
      actorId: json['actorId'] as String?,
      action: json['action'] as String? ?? 'UNKNOWN',
      resource: json['resource'] as String? ?? 'UNKNOWN',
      resourceId: json['resourceId'] as String?,
      requestId: json['requestId'] as String?,
      ipAddress: json['ipAddress'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        actorId,
        action,
        resource,
        resourceId,
        requestId,
        ipAddress,
        metadata,
        createdAt,
      ];
}
