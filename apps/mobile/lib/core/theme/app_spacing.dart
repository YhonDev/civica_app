import 'package:flutter/material.dart';

/// Spacing constants used throughout the app.
///
/// Follows the tokens defined in doc/DESIGN_SYSTEM.md.
class AppSpacing {
  const AppSpacing._();

  // ── Gap sizes ─────────────────────────────────────
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  // ── Padding ───────────────────────────────────────
  static const double screenPadding = 20;
  static const double cardPadding = 20;
  static const double cardInnerPadding = 16;

  // ── Radii ─────────────────────────────────────────
  static const double cardRadius = 16;
  static const double chipRadius = 20;
  static const double buttonRadius = 12;
  static const double inputRadius = 12;
  static const double bottomSheetRadius = 20;

  // ── Edge insets helper ────────────────────────────
  static EdgeInsets get screenEdgeInsets =>
      const EdgeInsets.symmetric(horizontal: screenPadding);

  static EdgeInsets get cardEdgeInsets =>
      const EdgeInsets.all(cardPadding);
}
