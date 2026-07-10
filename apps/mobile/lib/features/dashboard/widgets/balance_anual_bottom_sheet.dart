import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class BalanceAnualBottomSheet extends StatelessWidget {
  const BalanceAnualBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // Generar últimos 12 meses mock
    final now = DateTime.now();
    final meses = List.generate(12, (index) {
      final date = DateTime(now.year, now.month - index, 1);
      return _MesBalance(
        date: date,
        recaudo: 12500000.0 - (index * 150000), // Dato mock decreciente
        pendientes: 42 - index,
        mora: 2500000.0 + (index * 100000),
      );
    });

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
          // List
          Expanded(
            child: ListView.builder(
              itemCount: meses.length,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              itemBuilder: (context, index) {
                final mes = meses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: Text(
                        _formatMonthYear(mes.date),
                        style: AppTypography.subtitle.copyWith(color: AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        'Recaudo: \$${(mes.recaudo / 1000000).toStringAsFixed(1)}M',
                        style: AppTypography.body.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      childrenPadding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        _buildDetailRow('Cuotas Pendientes', '${mes.pendientes}'),
                        const SizedBox(height: AppSpacing.xs),
                        _buildDetailRow('Mora Total', '\$${(mes.mora / 1000000).toStringAsFixed(1)}M',
                            isError: true),
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

  String _formatMonthYear(DateTime date) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _MesBalance {
  final DateTime date;
  final double recaudo;
  final int pendientes;
  final double mora;

  _MesBalance({
    required this.date,
    required this.recaudo,
    required this.pendientes,
    required this.mora,
  });
}
