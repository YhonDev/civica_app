import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Reusable item definition for Basic Information tiles.
class BasicInfoItem {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const BasicInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });
}

/// Atomic Reusable Basic Information Section (`BasicInformationSection`).
///
/// Follows Atomic Design System principles. Shared across Residente, Cobrador, and Admin screens.
/// Renders standard "Información Básica" card with adaptive role-based tiles.
class BasicInformationSection extends StatelessWidget {
  final Map<String, dynamic>? user;
  final String? proyectoNombre;
  final List<BasicInfoItem>? customItems;

  const BasicInformationSection({
    super.key,
    this.user,
    this.proyectoNombre,
    this.customItems,
  });

  @override
  Widget build(BuildContext context) {
    final items = customItems ?? _buildDefaultItems();

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
    final email = user?['email'] as String? ?? '';
    final rol = user?['rol'] as String? ?? '';
    final tenantId = user?['tenantId'] as String? ?? '';

    final proyecto = proyectoNombre ??
        ((tenantId.isEmpty || tenantId.contains('-'))
            ? 'Urbanización San Sebastián'
            : tenantId);

    final list = <BasicInfoItem>[
      BasicInfoItem(
        icon: Icons.email_outlined,
        label: 'Correo registrado',
        value: email.isNotEmpty ? email : 'No se ha agregado correo',
      ),
      BasicInfoItem(
        icon: Icons.business_outlined,
        label: 'Proyecto / Urbanización',
        value: proyecto,
      ),
    ];

    // Additional role-adaptive items
    if (rol == 'RESIDENTE' || rol == 'PROPIETARIO') {
      final casa = user?['casaInfo'] as String? ?? user?['casa'] as String? ?? '';
      if (casa.isNotEmpty) {
        list.add(
          BasicInfoItem(
            icon: Icons.home_outlined,
            label: 'Inmueble / Casa',
            value: casa,
          ),
        );
      }
    } else if (rol == 'COBRADOR') {
      final zona = user?['zonaAsignada'] as String? ?? 'Ruta Principal';
      list.add(
        BasicInfoItem(
          icon: Icons.map_outlined,
          label: 'Zona / Ruta Asignada',
          value: zona,
        ),
      );
    }

    return list;
  }
}

class _InfoTileWidget extends StatelessWidget {
  final BasicInfoItem item;

  const _InfoTileWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(item.icon, color: AppColors.textSecondary),
      title: Text(
        item.label,
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      subtitle: Text(
        item.value,
        style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
      ),
      trailing: item.onTap != null
          ? Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled)
          : null,
      onTap: item.onTap,
    );
  }
}
