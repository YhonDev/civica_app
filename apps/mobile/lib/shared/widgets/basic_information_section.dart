import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Reusable item definition for Basic Information tiles.
class BasicInfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const BasicInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.trailing,
    this.onTap,
  });
}

/// Atomic Reusable Basic Information Section (`BasicInformationSection`).
///
/// Follows Atomic Design System principles. Shared across Residente, Cobrador, and Admin screens.
/// Dynamic and reactive to real-time profile edits (phone, email, modality, house).
/// Dynamically omits null or empty fields (e.g. email) and uses tokens from AppColors palette.
class BasicInformationSection extends StatelessWidget {
  final Map<String, dynamic>? user;
  final String? proyectoNombre;
  final String? emailOverride;
  final String? telefonoOverride;
  final String? modalidadOverride;
  final String? casaInfoOverride;
  final List<BasicInfoItem>? customItems;

  const BasicInformationSection({
    super.key,
    this.user,
    this.proyectoNombre,
    this.emailOverride,
    this.telefonoOverride,
    this.modalidadOverride,
    this.casaInfoOverride,
    this.customItems,
  });

  @override
  Widget build(BuildContext context) {
    final items = customItems ?? _buildDefaultItems();

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(
            'Información Básica',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 56),
                _InfoTileWidget(item: items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<BasicInfoItem> _buildDefaultItems() {
    final rawEmail = emailOverride ?? user?['email'] as String?;
    final email = (rawEmail != null && rawEmail.trim().isNotEmpty && rawEmail.trim() != 'null')
        ? rawEmail.trim()
        : null;

    final rol = user?['rol'] as String? ?? '';
    final tenantId = user?['tenantId'] as String? ?? '';

    final rawTelefono = telefonoOverride ?? user?['telefono'] as String?;
    final telefono = (rawTelefono != null && rawTelefono.trim().isNotEmpty && rawTelefono.trim() != 'null')
        ? rawTelefono.trim()
        : null;

    final modalidad = modalidadOverride ?? user?['modalidad'] as String? ?? user?['modalidadPago'] as String? ?? '';

    final proyecto = proyectoNombre ??
        ((tenantId.isEmpty || tenantId.contains('-'))
            ? 'Urbanización San Sebastián'
            : tenantId);

    final list = <BasicInfoItem>[];

    // 1. Email (omite si es nulo o vacío) - AppColors.accentPurple
    if (email != null) {
      list.add(
        BasicInfoItem(
          icon: Icons.email_outlined,
          label: 'Correo registrado',
          value: email,
          iconColor: AppColors.accentPurple,
        ),
      );
    }

    // 2. Teléfono (omite si es nulo o vacío) - AppColors.success
    if (telefono != null) {
      list.add(
        BasicInfoItem(
          icon: Icons.phone_outlined,
          label: 'Teléfono de contacto',
          value: telefono,
          iconColor: AppColors.success,
        ),
      );
    }

    // 3. Proyecto / Urbanización - AppColors.primary
    if (proyecto.isNotEmpty) {
      list.add(
        BasicInfoItem(
          icon: Icons.business_outlined,
          label: 'Proyecto / Urbanización',
          value: proyecto,
          iconColor: AppColors.primary,
        ),
      );
    }

    // 4. Modalidad de Pago - AppColors.warning (Ámbar Dorado)
    if (modalidad.isNotEmpty) {
      list.add(
        BasicInfoItem(
          icon: Icons.calendar_today_outlined,
          label: 'Modalidad de Pago',
          value: _formatModalidad(modalidad),
          iconColor: AppColors.warning,
        ),
      );
    }

    // 5. Inmueble / Casa según Rol - AppColors.accentOrange / AppColors.accentTeal
    final casa = casaInfoOverride ?? user?['casaInfo'] as String? ?? user?['casa'] as String? ?? '';
    if (casa.isNotEmpty) {
      list.add(
        BasicInfoItem(
          icon: Icons.home_outlined,
          label: 'Inmueble / Casa',
          value: casa,
          iconColor: AppColors.error,
        ),
      );
    } else if (rol == 'COBRADOR') {
      final zona = user?['zonaAsignada'] as String? ?? 'Ruta Principal';
      list.add(
        BasicInfoItem(
          icon: Icons.map_outlined,
          label: 'Zona de cobro',
          value: zona,
          iconColor: AppColors.accentTeal,
        ),
      );
    }

    return list;
  }

  String _formatModalidad(String val) {
    switch (val.toUpperCase()) {
      case 'SEMANAL':
        return 'Semanal (4 cuotas)';
      case 'QUINCENAL':
        return 'Quincenal (2 cuotas)';
      case 'MENSUAL':
        return 'Mensual (1 cuota)';
      default:
        return val;
    }
  }
}

class _InfoTileWidget extends StatelessWidget {
  final BasicInfoItem item;

  const _InfoTileWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    final themeColor = item.iconColor ?? AppColors.primary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: themeColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(item.icon, color: themeColor, size: 20),
      ),
      title: Text(
        item.label,
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      subtitle: Text(
        item.value,
        style: AppTypography.body.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: item.trailing,
      onTap: item.onTap,
    );
  }
}
