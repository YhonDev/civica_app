/// Strongly-typed user roles for Cuentiva.
///
/// Ensures explicit role resolution and eliminates insecure fallbacks (e.g. `default: ADMIN`).
enum UserRole {
  superadmin,
  admin,
  cobrador,
  residente,
  unauthorized;

  /// Parses a raw role string into a strongly-typed [UserRole].
  ///
  /// Maps recognized operational roles explicitly.
  /// Any unknown, null, or empty string maps strictly to [UserRole.unauthorized].
  static UserRole fromString(String? raw) {
    if (raw == null) return UserRole.unauthorized;
    final normalized = raw.trim().toUpperCase();
    switch (normalized) {
      case 'SUPERADMIN':
        return UserRole.superadmin;
      case 'ADMIN':
        return UserRole.admin;
      case 'COBRADOR':
        return UserRole.cobrador;
      case 'PROPIETARIO': // Backend retrocompatibility alias
      case 'RESIDENTE':
        return UserRole.residente;
      default:
        return UserRole.unauthorized;
    }
  }

  /// Human-readable label for UI display.
  String get label {
    switch (this) {
      case UserRole.superadmin:
        return 'Superadministrador';
      case UserRole.admin:
        return 'Administrador';
      case UserRole.cobrador:
        return 'Cobrador';
      case UserRole.residente:
        return 'Residente';
      case UserRole.unauthorized:
        return 'Sin acceso';
    }
  }

  bool get isSuperAdmin => this == UserRole.superadmin;
  bool get isAdmin => this == UserRole.admin;
  bool get isCobrador => this == UserRole.cobrador;
  bool get isResidente => this == UserRole.residente;
  bool get isAuthorized => this != UserRole.unauthorized && this != UserRole.superadmin;
}
