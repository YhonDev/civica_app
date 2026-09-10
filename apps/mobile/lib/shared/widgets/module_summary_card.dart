import 'package:flutter/material.dart';

import '../../core/theme/app_card_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class ModuleSummaryItem {
  final String label;
  final String value;
  final Color? color;
  final VoidCallback? onTap;

  const ModuleSummaryItem({
    required this.label,
    required this.value,
    this.color,
    this.onTap,
  });
}

/// A "Newspaper-style" card that summarizes a module.
/// It avoids loose data and ends with a clear Call to Action (CTA).
class ModuleSummaryCard extends StatelessWidget {
  final String title;
  final List<ModuleSummaryItem> items;
  final String actionLabel;
  final VoidCallback onActionTap;
  final bool isGrid;
  final bool highlightBorder;
  final Widget? extraContent;

  const ModuleSummaryCard({
    super.key,
    required this.title,
    required this.items,
    required this.actionLabel,
    required this.onActionTap,
    this.isGrid = false,
    this.highlightBorder = false,
    this.extraContent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppCardStyles.sectionCard(
        context,
        borderColor: highlightBorder
            ? AppColors.warning.withValues(alpha: 0.5)
            : null,
        glowColor: highlightBorder
            ? AppColors.warning.withValues(alpha: 0.08)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.cardPadding,
              AppSpacing.cardPadding,
              AppSpacing.cardPadding,
              AppSpacing.sm,
            ),
            child: Text(
              title.toUpperCase(),
              style: AppTypography.caption.copyWith(
                color: highlightBorder ? AppColors.warning : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          
          // Body (List of items)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.cardPadding,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isGrid
                    ? Row(
                        children: items.map((item) {
                          final content = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.value,
                                style: AppCardStyles.bigStat(
                                  item.color ?? AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.label,
                                style: AppCardStyles.kpiLabel,
                              ),
                            ],
                          );

                          return Expanded(
                            child: item.onTap != null
                                ? InkWell(onTap: item.onTap, child: content)
                                : content,
                          );
                        }).toList(),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: items.map((item) {
                          final rowContent = Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Row(
                              children: [
                                Text(
                                  item.value,
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: item.color ?? AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: AppCardStyles.listRowLabel,
                                  ),
                                ),
                                if (item.onTap != null)
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                              ],
                            ),
                          );

                          return item.onTap != null
                              ? InkWell(
                                  onTap: item.onTap,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  child: rowContent,
                                )
                              : rowContent;
                        }).toList(),
                      ),
                if (extraContent != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  extraContent!,
                ],
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.border),
          
          // Footer (Call to Action)
          Material(
            color: Colors.transparent,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppSpacing.cardRadius),
            ),
            child: InkWell(
              onTap: onActionTap,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppSpacing.cardRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        actionLabel,
                        style: AppCardStyles.cardAction,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
