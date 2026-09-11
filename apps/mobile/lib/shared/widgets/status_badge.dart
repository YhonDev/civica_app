import 'package:flutter/material.dart';

import '../../core/theme/app_card_styles.dart';
import '../../core/theme/app_colors.dart';

/// Semantic status types used across the app.
///
/// Per DESIGN_SYSTEM.md — States must always combine color + icon.
/// Never rely on color alone to communicate state.
enum StatusType {
  alDia,
  pendiente,
  mora,
  revision,
  parcial,
  offline,
}

/// A reusable status badge with icon + text + semantic color.
///
/// Used in: EstadoCuentaCard, CobroCard, CarteraScreen (Cobrador/Admin),
/// HistorialScreen, ResidenteCard.
///
/// Layout:
/// ┌──────────────┐
/// │  ✔ Al día     │
/// └──────────────┘
class StatusBadge extends StatelessWidget {
  final StatusType status;
  final double iconSize;
  final TextStyle? textStyle;

  const StatusBadge({
    super.key,
    required this.status,
    this.iconSize = 14,
    this.textStyle,
  });

  /// Create from a string (useful when data comes from backend).
  factory StatusBadge.fromString(String estado, {double iconSize = 14}) {
    final type = switch (estado.toUpperCase()) {
      'AL DÍA' || 'PAGADA' || 'AL_DIA' || 'PAGADO' => StatusType.alDia,
      'PENDIENTE' => StatusType.pendiente,
      'MORA' || 'VENCIDA' || 'VENCIDO' || 'EN MORA' => StatusType.mora,
      'REVISIÓN' || 'REVISION' || 'EN REVISIÓN' => StatusType.revision,
      'PARCIAL' => StatusType.parcial,
      'OFFLINE' || 'SIN CONEXIÓN' => StatusType.offline,
      _ => StatusType.pendiente,
    };
    return StatusBadge(status: type, iconSize: iconSize);
  }

  Color get _color => switch (status) {
        StatusType.alDia => AppColors.success,
        StatusType.pendiente => AppColors.warning,
        StatusType.mora => AppColors.error,
        StatusType.revision => AppColors.info,
        StatusType.parcial => AppColors.warning,
        StatusType.offline => AppColors.textDisabled,
      };

  IconData get _icon => switch (status) {
        StatusType.alDia => Icons.check_circle_outlined,
        StatusType.pendiente => Icons.schedule_outlined,
        StatusType.mora => Icons.error_outline_rounded,
        StatusType.revision => Icons.info_outline_rounded,
        StatusType.parcial => Icons.pie_chart_outline_rounded,
        StatusType.offline => Icons.cloud_off_outlined,
      };

  String get _label => switch (status) {
        StatusType.alDia => 'Al día',
        StatusType.pendiente => 'Pendiente',
        StatusType.mora => 'En mora',
        StatusType.revision => 'En revisión',
        StatusType.parcial => 'Parcial',
        StatusType.offline => 'Sin conexión',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: AppCardStyles.badge(_color, alpha: 0.12, radius: 20, withBorder: false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _color, size: iconSize),
          const SizedBox(width: 5),
          Text(
            _label,
            style: (textStyle ?? AppCardStyles.badgePillText).copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
