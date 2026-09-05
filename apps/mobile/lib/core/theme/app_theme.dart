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
    surface: AppColors.lightBackground,
    onSurface: AppColors.lightTextPrimary,
    surfaceContainerHighest: AppColors.lightSurface,
    onSurfaceVariant: AppColors.lightTextSecondary,
    error: AppColors.error,
    onError: Colors.white,
    outline: AppColors.lightTextDisabled,
    outlineVariant: AppColors.lightBorder,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    textTheme: AppTypography.toTextTheme(),

    // ── AppBar ──────────────────────────────────────
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.lightBackground,
      foregroundColor: AppColors.lightTextPrimary,
      titleTextStyle: AppTypography.subtitle.copyWith(
        color: AppColors.lightTextPrimary,
      ),
    ),

    // ── Card ────────────────────────────────────────
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.lightCard,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(
          color: AppColors.lightBorder.withValues(alpha: 0.85),
          width: 1,
        ),
      ),
      margin: EdgeInsets.zero,
    ),

    // ── Input ───────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      labelStyle: AppTypography.caption.copyWith(
        color: AppColors.lightTextSecondary,
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
        side: const BorderSide(color: AppColors.lightBorder),
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
      backgroundColor: AppColors.lightCard,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.lightTextDisabled,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: AppTypography.smallBold,
      unselectedLabelStyle: AppTypography.small,
      enableFeedback: true,
    ),

    // ── Chips ───────────────────────────────────────
    chipTheme: ChipThemeData(
      elevation: 0,
      backgroundColor: AppColors.lightSurface,
      selectedColor: AppColors.primary.withValues(alpha: 0.12),
      labelStyle: AppTypography.caption.copyWith(
        color: AppColors.lightTextPrimary,
      ),
      secondaryLabelStyle: AppTypography.caption.copyWith(
        color: AppColors.lightTextSecondary,
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
    scaffoldBackgroundColor: AppColors.lightBackground,

    // ── Divider ─────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.lightBorder,
      thickness: 1,
      space: 1,
    ),

    // ── Dialog ──────────────────────────────────────
    dialogTheme: DialogThemeData(
      elevation: 0,
      backgroundColor: AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
    ),
  );
}

/// Builds the dark [ThemeData] for the Civica Pago app.
ThemeData buildDarkTheme() {
  final colorScheme = ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primary.withValues(alpha: 0.2),
    onPrimaryContainer: Colors.white,
    secondary: AppColors.primaryLight,
    onSecondary: Colors.white,
    surface: AppColors.darkBackground,
    onSurface: AppColors.darkTextPrimary,
    surfaceContainerHighest: AppColors.darkSurface,
    onSurfaceVariant: AppColors.darkTextSecondary,
    error: AppColors.error,
    onError: Colors.white,
    outline: AppColors.darkTextDisabled,
    outlineVariant: AppColors.darkBorder,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    textTheme: AppTypography.toTextTheme(),

    // ── AppBar ──────────────────────────────────────
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.darkBackground,
      foregroundColor: AppColors.darkTextPrimary,
      titleTextStyle: AppTypography.subtitle.copyWith(
        color: AppColors.darkTextPrimary,
      ),
    ),

    // ── Card ────────────────────────────────────────
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.darkCard,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(
          color: AppColors.darkBorder.withValues(alpha: 0.9),
          width: 1,
        ),
      ),
      margin: EdgeInsets.zero,
    ),

    // ── Input ───────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      labelStyle: AppTypography.caption.copyWith(
        color: AppColors.darkTextSecondary,
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
        side: const BorderSide(color: AppColors.darkBorder),
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
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.darkTextDisabled,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: AppTypography.smallBold,
      unselectedLabelStyle: AppTypography.small,
      enableFeedback: true,
    ),

    // ── Chips ───────────────────────────────────────
    chipTheme: ChipThemeData(
      elevation: 0,
      backgroundColor: AppColors.darkSurface,
      selectedColor: AppColors.primary.withValues(alpha: 0.12),
      labelStyle: AppTypography.caption.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      secondaryLabelStyle: AppTypography.caption.copyWith(
        color: AppColors.darkTextSecondary,
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
    scaffoldBackgroundColor: AppColors.darkBackground,

    // ── Divider ─────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.darkBorder,
      thickness: 1,
      space: 1,
    ),

    // ── Dialog ──────────────────────────────────────
    dialogTheme: DialogThemeData(
      elevation: 0,
      backgroundColor: AppColors.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
    ),
  );
}
