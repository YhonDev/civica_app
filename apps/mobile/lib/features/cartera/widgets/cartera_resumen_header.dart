import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../screens/auth/auth_cubit.dart';
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

    final unitCuota = isResidente ? 'cuotas' : 'propietarios';
    final unitPago = isResidente ? 'pagos' : 'propietarios';

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
            label: label1,
            amount: resumen.totalPendiente,
            count: resumen.cantidadPendientes,
            unitLabel: unitCuota,
            color: Colors.white,
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildMetric(
            context,
            label: label2,
            amount: resumen.totalMora,
            count: resumen.cantidadMora,
            unitLabel: unitCuota,
            color: Colors.white,
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          _buildMetric(
            context,
            label: label3,
            amount: resumen.totalPagado,
            count: resumen.cantidadPagados,
            unitLabel: unitPago,
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
    required String unitLabel,
    required Color color,
  }) {
    // Formato abreviado (e.g. 7.8M, 20K)
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
          '$count $unitLabel',
          style: AppTypography.caption.copyWith(
            color: color.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
