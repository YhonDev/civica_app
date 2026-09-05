import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class DarkThemeNotifier extends ValueNotifier<bool> {
  DarkThemeNotifier(super.value);

  @override
  set value(bool newValue) {
    AppColors.setDarkMode(newValue);
    super.value = newValue;
  }
}

final darkThemeNotifier = DarkThemeNotifier(false);

/// Builds the light [ThemeData] for the Civica Pago app.
ThemeData buildLightTheme() {
  final colorScheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryLight.withValues(alpha: 0.2),
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.primaryLight,
    onSecondary: Colors.white,
    surface: AppColors.background,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.surface,
    onSurfaceVariant: AppColors.textSecondary,
    error: AppColors.error,
    onError: Colors.white,
    outline: AppColors.textDisabled,
    outlineVariant: AppColors.border,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: AppTypography.toTextTheme(),

    // ── AppBar ──────────────────────────────────────
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      titleTextStyle: AppTypography.subtitle.copyWith(
        color: AppColors.textPrimary,
      ),
    ),

    // ── Card ────────────────────────────────────────
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.card,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(
          color: AppColors.border.withValues(alpha: 0.85),
          width: 1,
        ),
      ),
      margin: EdgeInsets.zero,
    ),

    // ── Input ───────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: BorderSide(color: AppColors.error),
      ),
      labelStyle: AppTypography.caption.copyWith(
        color: AppColors.textSecondary,
      ),
    ),

    // ── Filled Button ──────────────────────────────
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        textStyle: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // ── Outlined Button ────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
      ),
    ),

    // ── Bottom Navigation ──────────────────────────
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      elevation: 0,
      backgroundColor: AppColors.card,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textDisabled,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: AppTypography.smallBold,
      unselectedLabelStyle: AppTypography.small,
      enableFeedback: true,
    ),

    // ── Chips ───────────────────────────────────────
    chipTheme: ChipThemeData(
      elevation: 0,
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary.withValues(alpha: 0.12),
      labelStyle: AppTypography.caption.copyWith(
        color: AppColors.textPrimary,
      ),
      secondaryLabelStyle: AppTypography.caption.copyWith(
        color: AppColors.textSecondary,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      side: BorderSide.none,
    ),

    // ── Scaffold ────────────────────────────────────
    scaffoldBackgroundColor: AppColors.background,

    // ── Divider ─────────────────────────────────────
    dividerTheme: DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),

    // ── Dialog ──────────────────────────────────────
    dialogTheme: DialogThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
    ),
  );
}

/// Builds the dark [ThemeData] for the Civica Pago app.
ThemeData buildDarkTheme() {
  final darkBackground = const Color(0xFF121417);
  final darkSurface = const Color(0xFF1B1E22);
  final darkCard = const Color(0xFF23272D);
  final darkBorder = const Color(0xFF32373E);

  final colorScheme = ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primary.withValues(alpha: 0.2),
    onPrimaryContainer: Colors.white,
    secondary: AppColors.primaryLight,
    onSecondary: Colors.white,
    surface: darkBackground,
    onSurface: Colors.white,
    surfaceContainerHighest: darkSurface,
    onSurfaceVariant: const Color(0xFF94A3B8),
    error: const Color(0xFFEF4444),
    onError: Colors.white,
    outline: const Color(0xFF64748B),
    outlineVariant: darkBorder,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: darkBackground,

    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: darkBackground,
      foregroundColor: Colors.white,
      titleTextStyle: AppTypography.subtitle.copyWith(color: Colors.white),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: darkCard,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(
          color: darkBorder.withValues(alpha: 0.9),
          width: 1,
        ),
      ),
      margin: EdgeInsets.zero,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      elevation: 0,
      backgroundColor: darkSurface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: const Color(0xFF64748B),
      type: BottomNavigationBarType.fixed,
    ),

    dialogTheme: DialogThemeData(
      elevation: 0,
      backgroundColor: darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
    ),
  );
}
