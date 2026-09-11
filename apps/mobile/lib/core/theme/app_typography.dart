import 'package:flutter/material.dart';

/// Typography constants matching the design system.
///
/// Única fuente de verdad para tipografías. Cambiar un tamaño aquí lo aplica
/// a TODA la app. Regla: `copyWith` solo para color/peso — nunca para tamaño.
///
/// Escalas base: title 28, subtitle 20, body 16, caption 13, small 11.
/// Escalas de tarjeta/módulo: cardTitle 15.5, cardValue 18, stat 22,
/// sectionHeader 26, display 32, label 12, micro 10, displayMicro 9.5.
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

  // ── Section Header (26px, bold) — headers de sección/lista ──
  static const sectionHeader = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: _letterSpacing,
    height: 1.4,
  );

  // ── Display (32px, bold) — cifras hero (tickets, modos inmersivos) ──
  static const display = TextStyle(
    fontSize: 32,
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

  // ── Stat (22px, extrabold) — cifras destacadas en dashboards ──
  static const stat = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
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

  // ── Body Small (14px, medium) — texto intermedio (listas densas) ──
  static const bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: _letterSpacing,
    height: 1.4,
  );

  // ── Card Title (15.5px, extrabold) — título principal de tarjeta ──
  static const cardTitle = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    height: 1.4,
  );

  // ── Card Value (18px, extrabold) — monto/cifra de tarjeta ──
  static const cardValue = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
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

  // ── Label (12px, semibold) — texto secundario de tarjeta/chips ──
  static const label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
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

  // ── Micro (10px, bold) — badges compactos ────────
  static const micro = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: _letterSpacing,
    height: 1.4,
  );

  // ── Display Micro (9.5px, bold) — meta-texto ultra compacto ──
  static const displayMicro = TextStyle(
    fontSize: 9.5,
    fontWeight: FontWeight.w700,
    letterSpacing: _letterSpacing,
    height: 1.4,
  );

  // ── Emoji (18px) — glifos decorativos (sin altura fija, no es texto) ──
  static const emoji = TextStyle(fontSize: 18);

  /// Returns a [TextTheme] built from the design tokens.
  static TextTheme toTextTheme() {
    return TextTheme(
      displayLarge: display,
      displayMedium: title,
      headlineLarge: title,
      headlineMedium: sectionHeader,
      headlineSmall: subtitle,
      titleLarge: subtitle,
      titleMedium: bodyMedium,
      titleSmall: label,
      bodyLarge: body,
      bodyMedium: body,
      bodySmall: caption,
      labelLarge: bodyMedium,
      labelMedium: caption,
      labelSmall: small,
    );
  }
}
