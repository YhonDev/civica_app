import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum CardStatusBorder { none, primary, success, warning, error }

/// Reusable global Card component for the Civica Pago design system.
/// Ensures consistent 1px borders, subtle elevation shadow, and status-colored accent borders.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final CardStatusBorder statusBorder;
  final Color? customBorderColor;
  final Color? backgroundColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.statusBorder = CardStatusBorder.none,
    this.customBorderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color borderColor;
    if (customBorderColor != null) {
      borderColor = customBorderColor!;
    } else {
      switch (statusBorder) {
        case CardStatusBorder.primary:
          borderColor = AppColors.primary.withValues(alpha: 0.6);
          break;
        case CardStatusBorder.success:
          borderColor = AppColors.success.withValues(alpha: 0.6);
          break;
        case CardStatusBorder.warning:
          borderColor = AppColors.warning.withValues(alpha: 0.6);
          break;
        case CardStatusBorder.error:
          borderColor = AppColors.error.withValues(alpha: 0.6);
          break;
        case CardStatusBorder.none:
          borderColor = isDark
              ? const Color(0xFF32373E)
              : AppColors.border.withValues(alpha: 0.9);
          break;
      }
    }

    final cardBg = backgroundColor ??
        (isDark ? const Color(0xFF23272D) : Colors.white);

    final cardWidget = Container(
      margin: margin ?? EdgeInsets.zero,
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: cardWidget,
        ),
      );
    }

    return cardWidget;
  }
}
