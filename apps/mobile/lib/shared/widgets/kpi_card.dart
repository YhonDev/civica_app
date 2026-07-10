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
  final String? actionLabel;
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.title,
    required this.amount,
    required this.percentage,
    required this.subtitle,
    this.actionLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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

          // Compact percentage and subtitle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: AppTypography.small.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  subtitle,
                  style: AppTypography.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),

          if (actionLabel != null && onTap != null) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(color: Colors.white24, height: 1),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        actionLabel!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
