import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Atomic Design Molecule: KPI Metric Card (`KPICard`).
///
/// Standardized card for displaying key performance metrics across Admin, Cobrador, and Residente dashboards.
/// Uses FittedBox for value text so large amounts ($200.000) or long dates (5 de septiembre)
/// auto-scale down smoothly without breaking into multiple lines or breaking symmetry.
class KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? color;
  final String? trendText;
  final bool? trendPositive;
  final double? percentage;
  final String? actionLabel;
  final VoidCallback? onTap;

  const KPICard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon = Icons.insights_rounded,
    this.color,
    this.trendText,
    this.trendPositive,
    this.percentage,
    this.actionLabel,
    this.onTap,
  });

  /// Factory for Recaudo / Percentage Progress KPI Cards
  factory KPICard.progress({
    required String title,
    required String amount,
    double? percentage,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onTap,
  }) {
    return KPICard(
      title: title,
      value: amount,
      subtitle: subtitle,
      percentage: percentage,
      actionLabel: actionLabel,
      icon: Icons.account_balance_wallet_outlined,
      color: AppColors.primary,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppColors.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(icon, color: themeColor, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: AppTypography.cardValue.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                ),
              ),
              if (percentage != null) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusProgress),
                  child: LinearProgressIndicator(
                    value: (percentage! / 100).clamp(0.0, 1.0),
                    backgroundColor: themeColor.withValues(alpha: 0.12),
                    color: themeColor,
                    minHeight: 5,
                  ),
                ),
              ],
              if (subtitle != null || trendText != null || actionLabel != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (trendText != null) ...[
                      Icon(
                        (trendPositive ?? true)
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 13,
                        color: (trendPositive ?? true)
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trendText!,
                        style: AppTypography.smallBold.copyWith(
                          color: (trendPositive ?? true)
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (subtitle != null)
                      Expanded(
                        child: Text(
                          subtitle!,
                          style: AppTypography.small.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (actionLabel != null)
                      Text(
                        actionLabel!,
                        style: AppTypography.smallBold.copyWith(
                          color: themeColor,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Compatibility typedef for older call sites.
typedef KpiCard = KPICard;
