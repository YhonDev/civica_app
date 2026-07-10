import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'solicitud_card.dart';

class SolicitudBottomSheet extends StatelessWidget {
  final SolicitudData solicitud;
  final String? montoStr;

  const SolicitudBottomSheet({
    super.key,
    required this.solicitud,
    this.montoStr,
  });

  static Future<void> show(
    BuildContext context, 
    SolicitudData solicitud, {
    String? montoStr,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SolicitudBottomSheet(
        solicitud: solicitud,
        montoStr: montoStr,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy').format(solicitud.fecha);
    Color statusColor = AppColors.warning;
    String statusText = 'Pendiente';

    if (solicitud.estado == SolicitudEstado.enRevision) {
      statusColor = AppColors.info;
      statusText = (solicitud.tipo.toLowerCase().contains('pago') ||
                    solicitud.tipo.toLowerCase().contains('pagad'))
          ? 'Pago en revisión'
          : 'En revisión';
    }

    final isPago = solicitud.tipo.toLowerCase().contains('pago') ||
                   solicitud.tipo.toLowerCase().contains('pagad');

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        top: AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      solicitud.tipo,
                      style: AppTypography.subtitle.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Fecha reporte: $dateStr',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Estado de la solicitud',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.lens, color: statusColor, size: 10),
              const SizedBox(width: 6),
              Text(
                statusText,
                style: AppTypography.bodyMedium.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Observación',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.cardInnerPadding),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            ),
            child: Text(
              solicitud.descripcion,
              style: AppTypography.body,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (isPago) ...[
            Text(
              'Recibo digital reportado',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(AppSpacing.cardInnerPadding),
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('N° Recibo', style: AppTypography.caption),
                      Text('TK-948271', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Valor', style: AppTypography.caption),
                      Text(montoStr ?? '—', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Fecha pago', style: AppTypography.caption),
                      Text('10/08/2026', style: AppTypography.bodyMedium),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cobrador', style: AppTypography.caption),
                      Text('Carlos Gómez', style: AppTypography.bodyMedium),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ),
        ],
      ),
    );
  }
}
