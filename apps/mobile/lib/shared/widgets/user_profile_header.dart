import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Atomic User Profile Header (`UserProfileHeader`).
///
/// Shared across Residente, Cobrador, Admin profile & configuration views.
/// Renders Avatar circle + Initials, Display Name, and Role Badge Pill.
class UserProfileHeader extends StatelessWidget {
  final String nombre;
  final String rol;

  const UserProfileHeader({
    super.key,
    required this.nombre,
    required this.rol,
  });

  @override
  Widget build(BuildContext context) {
    final initials = nombre.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join();
    final rolLabel = _rolName(rol);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Text(
            initials.isNotEmpty ? initials : 'U',
            style: AppTypography.title.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          nombre,
          style: AppTypography.subtitle.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            rolLabel,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  String _rolName(String rol) {
    switch (rol.toUpperCase()) {
      case 'ADMIN':
        return 'Administrador';
      case 'COBRADOR':
        return 'Cobrador';
      case 'PROPIETARIO':
      case 'RESIDENTE':
        return 'Residente';
      default:
        return rol;
    }
  }
}
