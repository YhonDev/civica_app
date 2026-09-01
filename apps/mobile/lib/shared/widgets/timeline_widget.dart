import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A data model for each timeline entry.
class TimelineItem {
  final String id;
  final String tipo;
  final String descripcion;
  final String usuario;
  final DateTime timestamp;
  final String hace;
  final String? contexto;
  final int? monto;

  const TimelineItem({
    required this.id,
    required this.tipo,
    required this.descripcion,
    required this.usuario,
    required this.timestamp,
    required this.hace,
    this.contexto,
    this.monto,
  });
}

/// A vertical timeline feed for recent activity.
///
/// Per DESIGN_SYSTEM.md (Timeline):
///   - Official component for history
///   - Never use tables for movements
///   - Each element contains: Estado, Fecha, Monto, Descripción, Acción
///
/// Per doc/19 (Animaciones):
///   - Every card: Fade + Slide, 200–300ms
///
/// Reusable in: Dashboard Propietario (2 items), Historial (all),
/// Dashboard Admin (activity feed), Cobrador (jornada).
class TimelineWidget extends StatelessWidget {
  final List<TimelineItem> items;

  /// Optional callback when an item is tapped (opens ticket, etc.)
  final void Function(TimelineItem item)? onItemTap;

  const TimelineWidget({
    super.key,
    required this.items,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text(
            'Sin actividad reciente',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(items.length, (i) {
        final item = items[i];
        final isLast = i == items.length - 1;
        return _TimelineRow(
          item: item,
          isLast: isLast,
          onTap: onItemTap != null ? () => onItemTap!(item) : null,
        );
      }),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final TimelineItem item;
  final bool isLast;
  final VoidCallback? onTap;

  const _TimelineRow({
    required this.item,
    required this.isLast,
    this.onTap,
  });

  Color _dotColor() {
    switch (item.tipo) {
      case 'pago':
        return AppColors.success;
      case 'creacion':
        return AppColors.info;
      case 'cuota':
        return AppColors.textDisabled;
      case 'solicitud':
        return AppColors.warning;
      case 'alerta':
        return AppColors.error;
      case 'vencida':
        return AppColors.error;
      case 'pago_registrado':
        return AppColors.success;
      case 'solicitud_revision':
        return AppColors.warning;
      case 'nuevo_propietario':
        return AppColors.info;
      case 'mora_generada':
        return AppColors.error;
      default:
        return AppColors.textDisabled;
    }
  }

  IconData _dotIcon() {
    switch (item.tipo) {
      case 'pago':
        return Icons.payments_outlined;
      case 'creacion':
        return Icons.receipt_long_outlined;
      case 'cuota':
        return Icons.receipt_long_outlined;
      case 'solicitud':
        return Icons.help_outline_rounded;
      case 'alerta':
        return Icons.notifications_outlined;
      case 'vencida':
        return Icons.error_outline_rounded;
      case 'pago_registrado':
        return Icons.payments_outlined;
      case 'solicitud_revision':
        return Icons.help_outline_rounded;
      case 'nuevo_propietario':
        return Icons.person_add_outlined;
      case 'mora_generada':
        return Icons.warning_amber_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line + dot
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _dotColor().withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _dotIcon(),
                        size: 14,
                        color: _dotColor(),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 1,
                          color: AppColors.border,
                        ),
                      ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: AppSpacing.sm,
                    bottom: isLast ? 0 : AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Context (Manzana/Casa) or fallback to User
                            Text(
                              item.contexto ?? item.usuario,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                            
                            // Description
                            if (item.descripcion.isNotEmpty)
                              Text(
                                item.descripcion.replaceAll(': undefined', '').replaceAll(': null', ''),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            const SizedBox(height: 2),

                            // User + timestamp
                            Text(
                              item.contexto != null 
                                ? '${item.usuario} • ${item.hace}'
                                : item.hace,
                              style: AppTypography.small.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Chevron hint for tap
                      if (onTap != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textDisabled,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
