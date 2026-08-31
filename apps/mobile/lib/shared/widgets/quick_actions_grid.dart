import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Single item model for Quick Actions.
class QuickActionItem {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const QuickActionItem({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });
}

/// Atomic Design Molecule: Quick Actions Grid (`QuickActionsGrid`).
///
/// Standardized grid component for quick actions in Dashboards.
class QuickActionsGrid extends StatelessWidget {
  final List<QuickActionItem> actions;
  final String? title;

  const QuickActionsGrid({
    super.key,
    required this.actions,
    this.title = 'Acciones Rápidas',
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
            child: Text(
              title!,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 2.5,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            final themeColor = action.color ?? AppColors.primary;

            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: action.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(action.icon, color: themeColor, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          action.label,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
