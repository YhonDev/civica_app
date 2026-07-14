import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Status of a solicitud (review request).
enum SolicitudEstado { pendiente, enRevision, resuelta, rechazada }

/// Data model for a solicitud.
class SolicitudData {
  final String id;
  final String cobroId;
  final String nroRecibo;
  final String tipo;
  final String descripcion;
  final SolicitudEstado estado;
  final DateTime fecha;
  final String? respuesta;
  final String? propietarioId;
  final String? propietarioNombre;

  const SolicitudData({
    required this.id,
    required this.cobroId,
    required this.nroRecibo,
    required this.tipo,
    required this.descripcion,
    required this.estado,
    required this.fecha,
    this.respuesta,
    this.propietarioId,
    this.propietarioNombre,
  });
}

/// A card displaying a review request (solicitud de revisión).
///
/// Per doc/19-dashboard-specification.md (Solicitudes):
///   Mostrar: Cantidad, Estado, Botón: Solicitar Revisión.
///
/// Reusable in: Dashboard Propietario (summary), Solicitudes screen (full list),
/// Admin (gestión solicitudes).
class SolicitudCard extends StatelessWidget {
  final SolicitudData solicitud;
  final VoidCallback? onTap;

  const SolicitudCard({
    super.key,
    required this.solicitud,
    this.onTap,
  });

  Color get _statusColor => switch (solicitud.estado) {
        SolicitudEstado.pendiente => AppColors.warning,
        SolicitudEstado.enRevision => AppColors.info,
        SolicitudEstado.resuelta => AppColors.success,
        SolicitudEstado.rechazada => AppColors.error,
      };

  IconData get _statusIcon => switch (solicitud.estado) {
        SolicitudEstado.pendiente => Icons.schedule_outlined,
        SolicitudEstado.enRevision => Icons.search_outlined,
        SolicitudEstado.resuelta => Icons.check_circle_outlined,
        SolicitudEstado.rechazada => Icons.cancel_outlined,
      };

  String get _statusLabel {
    if (solicitud.estado == SolicitudEstado.enRevision &&
        (solicitud.tipo.toLowerCase().contains('pago') ||
         solicitud.tipo.toLowerCase().contains('pagad'))) {
      return 'Pago en revisión';
    }
    return switch (solicitud.estado) {
      SolicitudEstado.pendiente => 'Pendiente',
      SolicitudEstado.enRevision => 'En revisión',
      SolicitudEstado.resuelta => 'Resuelta',
      SolicitudEstado.rechazada => 'Rechazada',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Row(
              children: [
                // Icon container
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: _statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        solicitud.tipo,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(_statusIcon, color: _statusColor, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            _statusLabel,
                            style: AppTypography.small.copyWith(
                              color: _statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '·',
                            style: TextStyle(
                              color: AppColors.textDisabled,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd/MM/yyyy').format(solicitud.fecha),
                            style: AppTypography.small.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Chevron
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textDisabled,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
