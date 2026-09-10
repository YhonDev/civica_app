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

  // Radios de la escala completa (migración de literales, ver §9.5 del
  // design system): cada `BorderRadius.circular(<literal>)` de la app
  // debe expresarse con uno de estos tokens.
  static const double radiusSm = 6;      // micro-elementos: badges, chips internos
  static const double radiusMd = 8;      // botones compactos, contenedores pequeños
  static const double radiusLg = 10;     // icon tiles, mini-tarjetas
  static const double radiusProgress = 4; // barras de progreso, skeleton y pills finas
  static const double radiusXl = 22;     // tiles héroe (logo login), avatares cuadrados
  static const double heroRadius = 28;   // contenedores héroe del modo inmersivo
  static const double radiusCircle = 999; // círculos perfectos (recorta al 50%)

  // ── Edge insets helper ────────────────────────────
  static EdgeInsets get screenEdgeInsets =>
      const EdgeInsets.symmetric(horizontal: screenPadding);

  static EdgeInsets get cardEdgeInsets =>
      const EdgeInsets.all(cardPadding);
}
