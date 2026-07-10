import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class AlertaItem {
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;

  AlertaItem({
    required this.titulo,
    required this.descripcion,
    required this.onTap,
  });
}

class AlertasSection extends StatelessWidget {
  final List<AlertaItem> alertas;

  const AlertasSection({super.key, required this.alertas});

  @override
  Widget build(BuildContext context) {
    if (alertas.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: alertas.map((alerta) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.cardInnerPadding),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          child: InkWell(
            onTap: alerta.onTap,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alerta.titulo,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alerta.descripcion,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver',
                      style: AppTypography.body.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.warning,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
