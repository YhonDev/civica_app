import 'package:flutter/material.dart';

/// Typography constants matching the design system.
///
/// Font sizes: title 28, subtitle 20, body 16, caption 13.
/// letterSpacing: -0.02 for modern tight tracking.
class AppTypography {
  const AppTypography._();

  static const _letterSpacing = -0.02;

  // ── Title (28px, bold) ───────────────────────────
  static const title = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: _letterSpacing,
    height: 1.4,
  );

  // ── Subtitle (20px, semibold) ────────────────────
  static const subtitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: _letterSpacing,
    height: 1.4,
  );

  // ── Body (16px, regular) ─────────────────────────
  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: _letterSpacing,
    height: 1.4,
  );

  // ── Body Medium (16px, medium) ───────────────────
  static const bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: _letterSpacing,
    height: 1.4,
  );

  // ── Caption (13px, regular) ──────────────────────
  static const caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: _letterSpacing,
    height: 1.4,
  );

  // ── Small (11px, regular) ────────────────────────
  static const small = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: _letterSpacing,
    height: 1.4,
  );

  // ── Small Bold (11px, semibold) ──────────────────
  static const smallBold = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: _letterSpacing,
    height: 1.4,
  );

  /// Returns a [TextTheme] built from the design tokens.
  static TextTheme toTextTheme() {
    return TextTheme(
      displayLarge: title,
      headlineLarge: title,
      headlineMedium: subtitle,
      titleLarge: subtitle,
      titleMedium: bodyMedium,
      bodyLarge: body,
      bodyMedium: body,
      bodySmall: caption,
      labelLarge: bodyMedium,
      labelMedium: caption,
      labelSmall: small,
    );
  }
}
