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
  final String? title;
  final Map<String, dynamic>? user;
  final String? proyectoNombre;
  final String? emailOverride;
  final String? telefonoOverride;
  final String? modalidadOverride;
  final String? casaInfoOverride;
  final List<BasicInfoItem>? customItems;

  const BasicInformationSection({
    super.key,
    this.title,
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
            title ?? 'Información Básica',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
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

/// Atomic Reusable Section for Occupancy Info (`InformacionOcupacionSection`).
class InformacionOcupacionSection extends StatelessWidget {
  final String nombre;
  final String username;
  final String modalidadPago;
  final String? email;

  const InformacionOcupacionSection({
    super.key,
    required this.nombre,
    required this.username,
    required this.modalidadPago,
    this.email,
  });

  @override
  Widget build(BuildContext context) {
    return BasicInformationSection(
      title: 'Información de Ocupación',
      customItems: [
        BasicInfoItem(
          icon: Icons.person_outline_rounded,
          label: 'Titular / Residente',
          value: nombre.isNotEmpty ? nombre : 'Sin titular',
          iconColor: AppColors.primary,
        ),
        BasicInfoItem(
          icon: Icons.alternate_email_rounded,
          label: 'Usuario registrado',
          value: username.isNotEmpty ? username : 'Sin usuario',
          iconColor: AppColors.accentPurple,
        ),
        if (email != null && email!.trim().isNotEmpty && email!.trim() != 'null')
          BasicInfoItem(
            icon: Icons.email_outlined,
            label: 'Correo registrado',
            value: email!,
            iconColor: AppColors.accentTeal,
          ),
        BasicInfoItem(
          icon: Icons.calendar_today_outlined,
          label: 'Modalidad de Pago',
          value: _formatModalidad(modalidadPago),
          iconColor: AppColors.warning,
        ),
      ],
    );
  }

  static String _formatModalidad(String val) {
    switch (val.toUpperCase()) {
      case 'SEMANAL':
        return 'Semanal (4 cuotas)';
      case 'QUINCENAL':
        return 'Quincenal (2 cuotas)';
      case 'MENSUAL':
        return 'Mensual (1 cuota)';
      default:
        return val.isNotEmpty ? val : 'No asignada';
    }
  }
}

/// Atomic Reusable Section for Property Details (`DetalleInmuebleSection`).
class DetalleInmuebleSection extends StatelessWidget {
  final String proyectoNombre;
  final String etapaNombre;
  final String manzanaNombre;
  final String casaDireccion;

  const DetalleInmuebleSection({
    super.key,
    required this.proyectoNombre,
    required this.etapaNombre,
    required this.manzanaNombre,
    required this.casaDireccion,
  });

  @override
  Widget build(BuildContext context) {
    return BasicInformationSection(
      title: 'Detalles del Inmueble',
      customItems: [
        BasicInfoItem(
          icon: Icons.business_rounded,
          label: 'Proyecto / Urbanización',
          value: proyectoNombre.isNotEmpty ? proyectoNombre : 'Urbanización San Sebastián',
          iconColor: AppColors.primary,
        ),
        BasicInfoItem(
          icon: Icons.layers_outlined,
          label: 'Etapa',
          value: etapaNombre.isNotEmpty ? etapaNombre : 'Sin etapa',
          iconColor: AppColors.accentPurple,
        ),
        BasicInfoItem(
          icon: Icons.grid_view_rounded,
          label: 'Manzana',
          value: manzanaNombre.isNotEmpty ? manzanaNombre : 'Sin manzana',
          iconColor: AppColors.accentTeal,
        ),
        BasicInfoItem(
          icon: Icons.home_outlined,
          label: 'Casa / Ubicación',
          value: casaDireccion.isNotEmpty ? casaDireccion : 'Sin casa',
          iconColor: AppColors.error,
        ),
      ],
    );
  }
}
