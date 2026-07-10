import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A large KPI card that displays a key metric.
///
/// Layout (per doc/DESIGN_SYSTEM.md):
/// ┌──────────────────────────────┐
/// │   Recaudo del Mes            │ ← caption, secondary
/// │   $12.580.000                │ ← title, 28px, bold
/// │   ██████████████░░ 82%       │ ← progress bar, thin
/// │   82% de la meta mensual     │ ← caption
/// └──────────────────────────────┘
class KpiCard extends StatelessWidget {
  final String title;
  final String amount;
  final double percentage;
  final String subtitle;

  const KpiCard({
    super.key,
    required this.title,
    required this.amount,
    required this.percentage,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardEdgeInsets,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Amount
          Text(
            amount,
            style: AppTypography.title.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  FractionallySizedBox(
                    widthFactor: (percentage.clamp(0, 100)) / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Subtitle
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Color _progressColor() {
    if (percentage >= 80) return AppColors.success;
    if (percentage >= 50) return AppColors.warning;
    return AppColors.error;
  }
}
