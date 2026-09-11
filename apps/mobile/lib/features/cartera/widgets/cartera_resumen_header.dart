import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format/app_currency.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../features/auth/auth_cubit.dart';
import '../models/cartera_models.dart';

class CarteraResumenHeader extends StatelessWidget {
  final CarteraResumen resumen;

  const CarteraResumenHeader({
    super.key,
    required this.resumen,
  });

  @override
  Widget build(BuildContext context) {
    final userRole = context.watch<AuthCubit>().state.usuario?['rol'] as String?;
    final isResidente = userRole == 'RESIDENTE' || userRole == 'PROPIETARIO';

    final label1 = isResidente ? 'Pendiente' : 'Por cobrar';
    final label2 = isResidente ? 'En Mora' : 'Mora';
    final label3 = isResidente ? 'Pagado' : 'Recaudado';

    final unitCuota = isResidente ? 'cuotas' : 'casas';
    final unitPago = isResidente ? 'pagos' : 'recaudos';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardInnerPadding),
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
          Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                isResidente ? 'Estado de Cuenta' : 'Resumen de Cartera',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: label1,
                  amount: resumen.totalPendiente,
                  count: resumen.cantidadPendientes,
                  unitLabel: unitCuota,
                  badgeColor: AppColors.warning,
                  icon: Icons.hourglass_top_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _buildMetricTile(
                  label: label2,
                  amount: resumen.totalMora,
                  count: resumen.cantidadMora,
                  unitLabel: unitCuota,
                  badgeColor: AppColors.error,
                  icon: Icons.warning_amber_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _buildMetricTile(
                  label: label3,
                  amount: resumen.totalPagado,
                  count: resumen.cantidadPagados,
                  unitLabel: unitPago,
                  badgeColor: AppColors.success,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required double amount,
    required int count,
    required String unitLabel,
    required Color badgeColor,
    required IconData icon,
  }) {
    final amountFormatted = AppCurrency.format(amount.round());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        border: Border.all(color: badgeColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: badgeColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.smallBold.copyWith(
                    color: badgeColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amountFormatted,
              style: AppTypography.cardTitle.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$count $unitLabel',
            style: AppTypography.micro.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
