import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/kpi_card.dart';
import '../../../shared/widgets/mini_stat_card.dart';

/// KPI section: main recaudo card + 3 mini stat cards.
class ResumenSection extends StatelessWidget {
  final double recaudoMes;
  final double metaMensual;
  final double porcentaje;
  final int pagaron;
  final int pendientes;
  final double mora;

  const ResumenSection({
    super.key,
    required this.recaudoMes,
    required this.metaMensual,
    required this.porcentaje,
    required this.pagaron,
    required this.pendientes,
    required this.mora,
  });

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(0)}k';
    }
    return '\$${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main KPI card
        KpiCard(
          title: 'Recaudo del Mes',
          amount: _formatCurrency(recaudoMes),
          percentage: porcentaje,
          subtitle: '${porcentaje.toStringAsFixed(0)}% de la meta mensual',
        ),
        const SizedBox(height: AppSpacing.md),

        // Mini stat cards row
        Row(
          children: [
            MiniStatCard(
              icon: Icons.check_circle_rounded,
              label: 'Pagaron',
              value: pagaron.toString(),
              color: AppColors.success,
            ),
            const SizedBox(width: AppSpacing.sm),
            MiniStatCard(
              icon: Icons.access_time_rounded,
              label: 'Pendientes',
              value: pendientes.toString(),
              color: AppColors.warning,
            ),
            const SizedBox(width: AppSpacing.sm),
            MiniStatCard(
              icon: Icons.warning_rounded,
              label: 'Mora',
              value: _formatCurrency(mora),
              color: AppColors.error,
            ),
          ],
        ),
      ],
    );
  }
}
