import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Componente global homogéneo para títulos principales de pantalla.
/// Alineado a la izquierda, en negrita destacada y tamaño amplio de 26px.
class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.only(
      left: AppSpacing.screenPadding,
      right: AppSpacing.screenPadding,
      top: AppSpacing.md,
      bottom: AppSpacing.md,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.title.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    height: 1.15,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AppTypography.body.copyWith(
                      color: isDark ? Colors.white60 : AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
