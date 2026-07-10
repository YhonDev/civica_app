import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/cartera_models.dart';

class CarteraResumenHeader extends StatelessWidget {
  final CarteraResumen resumen;

  const CarteraResumenHeader({
    super.key,
    required this.resumen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetric(
            context,
            label: 'Por cobrar',
            amount: resumen.totalPendiente,
            count: resumen.cantidadPendientes,
            color: Colors.white,
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildMetric(
            context,
            label: 'Mora',
            amount: resumen.totalMora,
            count: resumen.cantidadMora,
            color: Colors.white,
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildMetric(
            context,
            label: 'Recaudado',
            amount: resumen.totalPagado,
            count: resumen.cantidadPagados,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(
    BuildContext context, {
    required String label,
    required double amount,
    required int count,
    required Color color,
  }) {
    // Formato abreviado (e.g. 7.8M, 2.0M)
    final amountString = amount >= 1000000
        ? '${(amount / 1000000).toStringAsFixed(1)}M'
        : '${(amount / 1000).toStringAsFixed(0)}K';

    return Column(
      children: [
        Text(
          label,
          style: AppTypography.small.copyWith(
            color: color.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$$amountString',
          style: AppTypography.title.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$count propietarios',
          style: AppTypography.caption.copyWith(
            color: color.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
