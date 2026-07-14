import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/dashboard_data.dart';

class BalanceAnualBottomSheet extends StatelessWidget {
  final List<MesHistorico> historialMeses;
  final double acumuladoAnual;
  final double metaAnual;

  const BalanceAnualBottomSheet({
    super.key,
    required this.historialMeses,
    required this.acumuladoAnual,
    required this.metaAnual,
  });

  @override
  Widget build(BuildContext context) {
    final porcentajeMeta = metaAnual > 0
        ? (acumuladoAnual / metaAnual) * 100
        : 0.0;

    // Ordenar descendente: mes más reciente primero
    final mesesOrdenados = List<MesHistorico>.from(historialMeses)
      ..sort((a, b) => b.anio == a.anio
          ? b.mes.compareTo(a.mes)
          : b.anio.compareTo(a.anio));

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Balance General',
                  style: AppTypography.title.copyWith(color: AppColors.textPrimary),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),

          // Resumen anual
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Acumulado Anual',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '\$${_formatAmount(acumuladoAnual)}',
                        style: AppTypography.title.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: porcentajeMeta >= 80
                        ? AppColors.success.withValues(alpha: 0.1)
                        : porcentajeMeta >= 50
                            ? AppColors.warning.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${porcentajeMeta.toStringAsFixed(0)}%',
                    style: AppTypography.body.copyWith(
                      color: porcentajeMeta >= 80
                          ? AppColors.success
                          : porcentajeMeta >= 50
                              ? AppColors.warning
                              : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de meses
          Expanded(
            child: ListView.builder(
              itemCount: mesesOrdenados.length,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              itemBuilder: (context, index) {
                final mes = mesesOrdenados[index];
                final pctRecaudo = metaAnual / 12 > 0
                    ? (mes.recaudo / (metaAnual / 12)) * 100
                    : 0.0;

                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: Text(
                        _formatMonthYear(mes.mes, mes.anio),
                        style: AppTypography.subtitle.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Text(
                            'Recaudo: \$${_formatAmount(mes.recaudo)}',
                            style: AppTypography.body.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: pctRecaudo >= 80
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${pctRecaudo.toStringAsFixed(0)}%',
                              style: AppTypography.small.copyWith(
                                color: pctRecaudo >= 80
                                    ? AppColors.success
                                    : AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      childrenPadding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        _buildDetailRow(
                          'Cobros Pendientes',
                          NumberFormat.decimalPattern('es_CO')
                              .format(mes.pendientes),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _buildDetailRow(
                          'Mora Total',
                          '\$${_formatAmount(mes.mora)}',
                          isError: mes.mora > 0,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: isError ? AppColors.error : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatMonthYear(int mes, int anio) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return '${months[mes - 1]} $anio';
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
