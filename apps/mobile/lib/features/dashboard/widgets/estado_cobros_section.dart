import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/donut_chart.dart';
import '../../dashboard/models/dashboard_data.dart';

/// Estado de Cobros section with donut chart and legend.
class EstadoCobrosSection extends StatelessWidget {
  final List<CobroEstadoItem> estados;

  const EstadoCobrosSection({super.key, required this.estados});

  Color _colorForEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pagado':
      case 'pagados':
      case 'al día':
        return AppColors.success;
      case 'pendiente':
      case 'pendientes':
        return AppColors.warning;
      case 'revision':
      case 'en revisión':
        return AppColors.info;
      case 'mora':
      case 'vencido':
        return AppColors.error;
      default:
        return AppColors.textDisabled;
    }
  }

  String _labelForEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pagado':
      case 'pagados':
        return 'Pagados';
      case 'pendiente':
      case 'pendientes':
        return 'Pendientes';
      case 'revision':
      case 'en revisión':
        return 'Revisión';
      case 'mora':
      case 'vencido':
        return 'En mora';
      default:
        return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    final segments = estados
        .map((e) => DonutSegment(
              label: _labelForEstado(e.estado),
              percentage: e.porcentaje,
              color: _colorForEstado(e.estado),
            ))
        .toList();

    return Container(
      padding: AppSpacing.cardEdgeInsets,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estado Cobros',
            style: AppTypography.subtitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: DonutChart(segments: segments, size: 160),
          ),
          const SizedBox(height: AppSpacing.md),
          // Legend
          ...estados.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _colorForEstado(e.estado),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _labelForEstado(e.estado),
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${e.porcentaje.toStringAsFixed(0)}%',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
