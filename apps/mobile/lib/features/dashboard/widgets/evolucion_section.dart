import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/line_chart.dart';
import '../../dashboard/models/dashboard_data.dart';

/// Evolucion del recaudo section with line chart.
class EvolucionSection extends StatelessWidget {
  final List<EvolucionPunto> evolucion;

  const EvolucionSection({super.key, required this.evolucion});

  @override
  Widget build(BuildContext context) {
    final points = evolucion
        .map((e) => ChartPoint(day: e.dia, value: e.valor))
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
      child: LineChartWidget(
        title: 'Evolución del recaudo',
        points: points,
        height: 200,
      ),
    );
  }
}
