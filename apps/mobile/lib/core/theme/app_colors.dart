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

  // ── Light Theme Tokens ─────────────────────────────
  static const Color lightBackground = Color(0xFFF1F5F9);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextDisabled = Color(0xFF9CA3AF);
  static const Color lightBorder = Color(0xFFCBD5E1);

  // ── Dark Theme Tokens ──────────────────────────────
  static const Color darkBackground = Color(0xFF121417);
  static const Color darkCard = Color(0xFF23272D);
  static const Color darkSurface = Color(0xFF1B1E22);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextDisabled = Color(0xFF64748B);
  static const Color darkBorder = Color(0xFF32373E);

  // ── Primary ───────────────────────────────────────
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1D4ED8);

  // ── Dynamic Backgrounds (Current Mode) ─────────────
  static Color get background => _isDark ? darkBackground : lightBackground;
  static Color get card => _isDark ? darkCard : lightCard;
  static Color get surface => _isDark ? darkSurface : lightSurface;

  /// Campo de búsqueda / contenedor de chips sobre el fondo de pantalla.
  /// Reemplaza los literales 0xFF1E293B (dark) / 0xFFF1F5F9 (light).
  static Color get searchField => _isDark ? darkSurface : lightBackground;

  /// Fondo de tarjeta elevada sobre el fondo de pantalla.
  /// Reemplaza los literales 0xFF1E293B (dark) / Colors.white (light).
  static Color get elevatedCard => _isDark ? darkCard : lightCard;

  /// Texto de énfasis sobre tarjeta elevada (alias de elevatedCardText).
  static Color get ink => elevatedCardText;

  /// Texto de énfasis sobre tarjeta elevada.
  static Color get elevatedCardText => _isDark ? darkTextPrimary : lightTextPrimary;

  /// Borde de tarjeta elevada.
  static Color get elevatedCardBorder => _isDark ? darkBorder : lightBorder;

  /// Texto secundario sobre tarjeta elevada (alias de elevatedCardTextSecondary).
  static Color get inkSecondary => elevatedCardTextSecondary;

  /// Texto secundario sobre tarjeta elevada.
  static Color get elevatedCardTextSecondary =>
      _isDark ? darkTextSecondary : Color(0xFF475569);

  // ── Dynamic Text (Current Mode) ────────────────────
  static Color get textPrimary => _isDark ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary => _isDark ? darkTextSecondary : lightTextSecondary;
  static Color get textDisabled => _isDark ? darkTextDisabled : lightTextDisabled;

  // ── Semantic ───────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ── Category & Feature Accents ────────────────────
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentTeal = Color(0xFF14B8A6);

  // ── Dynamic Borders (Current Mode) ─────────────────
  static Color get border => _isDark ? darkBorder : lightBorder;
}
