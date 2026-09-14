import 'package:flutter/material.dart';
import '../../core/format/app_currency.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Atomic Component: `RecaudoTimelineWidget`
///
/// Progress card displaying monthly payment progress, cuotas ratio (e.g. 2/4 pagadas),
/// percentage bar, and financial status for the Residente Dashboard.
class RecaudoTimelineWidget extends StatelessWidget {
  final int cuotasPagadas;
  final int totalCuotas;
  final double montoPagado;
  final double saldoPendiente;
  final String modalidad;
  final VoidCallback? onAccionTap;

  const RecaudoTimelineWidget({
    super.key,
    required this.cuotasPagadas,
    required this.totalCuotas,
    required this.montoPagado,
    required this.saldoPendiente,
    this.modalidad = 'MENSUAL',
    this.onAccionTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTotal = totalCuotas > 0 ? totalCuotas : 1;
    final porcentaje = (cuotasPagadas / effectiveTotal).clamp(0.0, 1.0);
    final porcentajeInt = (porcentaje * 100).round();

    final isCompleto = cuotasPagadas >= totalCuotas && totalCuotas > 0;
    final statusColor = isCompleto ? AppColors.success : (saldoPendiente > 0 ? AppColors.warning : AppColors.info);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ─────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Icon(
                  isCompleto ? Icons.check_circle_rounded : Icons.donut_large_rounded,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progreso de Cuotas',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$cuotasPagadas de $totalCuotas cuotas completadas',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$porcentajeInt%',
                  style: AppTypography.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Progress Bar ───────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: LinearProgressIndicator(
              value: porcentaje,
              minHeight: 8,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Sub-stats Row ──────────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  label: 'Abonado este mes',
                  val: AppCurrency.format(montoPagado),
                  color: AppColors.success,
                ),
              ),
              Container(
                height: 24,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                color: AppColors.border.withValues(alpha: 0.5),
              ),
              Expanded(
                child: _buildStatItem(
                  label: 'Saldo pendiente',
                  val: AppCurrency.format(saldoPendiente),
                  color: saldoPendiente > 0 ? AppColors.error : AppColors.textSecondary,
                ),
              ),
            ],
          ),

          if (onAccionTap != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAccionTap,
                icon: Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
                label: Text(
                  'Ver Detalle de Cuotas',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String val,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.small.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            val,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
