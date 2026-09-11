import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_card_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Status of a solicitud (review request / cobro request).
enum SolicitudEstado {
  pendiente,
  enEspera,
  enCamino,
  cobrada,
  enRevision,
  resuelta,
  aprobada,
  rechazada,
  vencida,
}

/// Data model for a solicitud.
class SolicitudData {
  final String id;
  final String cobroId;
  final String? pagoId;
  final String nroRecibo;
  final String tipo;
  final String descripcion;
  final SolicitudEstado estado;
  final DateTime fecha;
  final String? respuesta;
  final String? residenteId;
  final String? residenteNombre;
  final String? cuotaConcepto;

  const SolicitudData({
    required this.id,
    required this.cobroId,
    this.pagoId,
    required this.nroRecibo,
    required this.tipo,
    required this.descripcion,
    required this.estado,
    required this.fecha,
    this.respuesta,
    this.residenteId,
    this.residenteNombre,
    this.cuotaConcepto,
  });

  /// Formats concept by removing redundant year (e.g., 'Septiembre 2026 - Cuota 1' -> 'Septiembre — Cuota 1')
  static String cleanConcepto(String raw) {
    var s = raw.replaceAll(RegExp(r'\s*\b20\d\d\b\s*'), ' ').trim();
    s = s.replaceAll(RegExp(r'\s*-\s*'), ' — ');
    return s.replaceAll(RegExp(r'\s+'), ' ');
  }

  String get displayTitle {
    final t = tipo.toLowerCase();
    if (t.contains('revision') || t.contains('revisión')) {
      return 'Revisión de pago';
    }
    if (t.contains('cobro')) {
      return 'Solicitud de cobro';
    }
    return tipo;
  }

  String? get displaySubtitulo {
    if (cuotaConcepto != null && cuotaConcepto!.trim().isNotEmpty) {
      return cleanConcepto(cuotaConcepto!);
    }
    if (tipo.contains(':')) {
      final parts = tipo.split(':');
      if (parts.length > 1 && parts[1].trim().isNotEmpty) {
        return cleanConcepto(parts[1].trim());
      }
    }
    return null;
  }
}

/// A card displaying a review request or collection request.
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
        SolicitudEstado.enEspera => AppColors.warning,
        SolicitudEstado.enCamino => AppColors.info,
        SolicitudEstado.cobrada => AppColors.success,
        SolicitudEstado.enRevision => AppColors.info,
        SolicitudEstado.resuelta => AppColors.success,
        SolicitudEstado.aprobada => AppColors.success,
        SolicitudEstado.rechazada => AppColors.error,
        SolicitudEstado.vencida => AppColors.error,
      };

  IconData get _statusIcon => switch (solicitud.estado) {
        SolicitudEstado.pendiente => Icons.schedule_outlined,
        SolicitudEstado.enEspera => Icons.hourglass_top_rounded,
        SolicitudEstado.enCamino => Icons.directions_walk_rounded,
        SolicitudEstado.cobrada => Icons.check_circle_outlined,
        SolicitudEstado.enRevision => Icons.search_outlined,
        SolicitudEstado.resuelta => Icons.check_circle_outlined,
        SolicitudEstado.aprobada => Icons.verified_outlined,
        SolicitudEstado.rechazada => Icons.cancel_outlined,
        SolicitudEstado.vencida => Icons.error_outline_rounded,
      };

  String get _statusLabel {
    final tipoLower = solicitud.tipo.toLowerCase();
    final isCobro = tipoLower.contains('cobro') || tipoLower.contains('solicitud_cobro');

    return switch (solicitud.estado) {
      SolicitudEstado.pendiente => isCobro ? 'Esperando cobrador' : 'Pendiente',
      SolicitudEstado.enEspera => isCobro ? 'Esperando cobrador' : 'En espera',
      SolicitudEstado.enCamino => 'Cobrador en camino',
      SolicitudEstado.cobrada => 'Cobrado',
      SolicitudEstado.enRevision => 'Pago en revisión',
      SolicitudEstado.resuelta => 'Resuelta',
      SolicitudEstado.aprobada => 'Pago verificado',
      SolicitudEstado.rechazada => 'Rechazada',
      SolicitudEstado.vencida => 'Vencida',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppCardStyles.listCard(context),
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
                  decoration: AppCardStyles.iconTile(_statusColor),
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
                        solicitud.displayTitle,
                        style: AppCardStyles.listTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (solicitud.displaySubtitulo != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          solicitud.displaySubtitulo!,
                          style: AppCardStyles.listSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(_statusIcon, color: _statusColor, size: 12),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _statusLabel,
                              style: AppCardStyles.statusText(_statusColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (solicitud.nroRecibo.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '·',
                              style: AppTypography.label.copyWith(
                                color: AppColors.textDisabled,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                            child: Text(
                              solicitud.nroRecibo,
                              style: AppCardStyles.statusText(AppColors.primary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              DateFormat("dd/MM/yyyy · hh:mm a", 'es').format(solicitud.fecha),
                              style: AppCardStyles.listMeta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
