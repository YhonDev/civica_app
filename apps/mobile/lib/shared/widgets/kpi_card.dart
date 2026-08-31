import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Atomic Design Molecule: KPI Metric Card (`KPICard`).
///
/// Standardized card for displaying key performance metrics across Admin, Cobrador, and Residente dashboards.
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
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: themeColor, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                value,
                style: AppTypography.title.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              if (percentage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (percentage! / 100).clamp(0.0, 1.0),
                    backgroundColor: themeColor.withValues(alpha: 0.12),
                    color: themeColor,
                    minHeight: 6,
                  ),
                ),
              ],
              if (subtitle != null || trendText != null || actionLabel != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (trendText != null) ...[
                      Icon(
                        (trendPositive ?? true)
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 14,
                        color: (trendPositive ?? true)
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trendText!,
                        style: AppTypography.caption.copyWith(
                          color: (trendPositive ?? true)
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (subtitle != null)
                      Expanded(
                        child: Text(
                          subtitle!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (actionLabel != null)
                      Text(
                        actionLabel!,
                        style: AppTypography.caption.copyWith(
                          color: themeColor,
                          fontWeight: FontWeight.w600,
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
