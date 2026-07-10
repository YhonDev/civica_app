import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../dashboard/models/dashboard_data.dart';

/// Modalidades de pago section.
class ModalidadesSection extends StatelessWidget {
  final List<ModalidadItem> modalidades;

  const ModalidadesSection({super.key, required this.modalidades});

  @override
  Widget build(BuildContext context) {
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
            'Modalidades',
            style: AppTypography.subtitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...modalidades.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _ModalidadRow(modalidad: m),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModalidadRow extends StatelessWidget {
  final ModalidadItem modalidad;

  const _ModalidadRow({required this.modalidad});

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              modalidad.nombre,
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${modalidad.porcentaje.toStringAsFixed(0)}%',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 4,
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        color: AppColors.surface,
                      ),
                      FractionallySizedBox(
                        widthFactor:
                            (modalidad.porcentaje.clamp(0, 100)) / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.6),
                                AppColors.primary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              _formatCurrency(modalidad.valor),
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
