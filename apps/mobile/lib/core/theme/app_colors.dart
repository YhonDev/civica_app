import 'package:flutter/material.dart';

/// Design system colors for the Civica Pago app.
///
/// Matches the tokens defined in doc/DESIGN_SYSTEM.md.
class AppColors {
  AppColors._();

  static bool _isDark = false;
  static void setDarkMode(bool dark) {
    _isDark = dark;
  }
  static bool get isDark => _isDark;

  // ── Primary ───────────────────────────────────────
  static Color get primary => const Color(0xFF2563EB);
  static Color get primaryLight => const Color(0xFF60A5FA);
  static Color get primaryDark => const Color(0xFF1D4ED8);

  // ── Backgrounds ────────────────────────────────────
  static Color get background => _isDark ? const Color(0xFF000000) : const Color(0xFFF8FAFC);
  static Color get card => _isDark ? const Color(0xFF121212) : const Color(0xFFFFFFFF);
  static Color get surface => _isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9);

  // ── Text ───────────────────────────────────────────
  static Color get textPrimary => _isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111827);
  static Color get textSecondary => _isDark ? const Color(0xFFB3B3B3) : const Color(0xFF6B7280);
  static Color get textDisabled => _isDark ? const Color(0xFF666666) : const Color(0xFF9CA3AF);

  // ── Semantic ───────────────────────────────────────
  static Color get success => const Color(0xFF22C55E);
  static Color get error => const Color(0xFFEF4444);
  static Color get warning => const Color(0xFFF59E0B);
  static Color get info => const Color(0xFF3B82F6);

  // ── Borders ────────────────────────────────────────
  static Color get border => _isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE2E8F0);
}
