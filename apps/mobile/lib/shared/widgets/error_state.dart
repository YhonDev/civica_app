import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Standardized error state widget with retry capability and accessibility.
///
/// Designed to follow the design system tokens:
/// - Semantic error iconography with tinted circular background
/// - Clear headline and descriptive resolution text
/// - Minimum 48x48dp touch target for the retry action
class ErrorState extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String retryLabel;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.title = 'Algo salió mal',
    required this.description,
    this.icon = Icons.error_outline_rounded,
    this.retryLabel = 'Reintentar',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon in themed circle container
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              title,
              style: AppTypography.subtitle.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Description
            Text(
              description,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            // Action / Retry Button
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Semantics(
                button: true,
                label: retryLabel,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 48,
                    minWidth: 140,
                  ),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                      ),
                    ),
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: Text(
                      retryLabel,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
