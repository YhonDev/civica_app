import 'package:flutter/material.dart';

/// Breakpoints standard based on Material Design 3 specifications.
class AppBreakpoints {
  const AppBreakpoints._();

  /// Below 600px is compact mobile layout (portrait smartphones).
  static const double compact = 600.0;

  /// 600px to 1023px is medium layout (tablets, foldables, half desktop).
  static const double medium = 1024.0;

  /// 1024px to 1439px is expanded desktop/laptop layout.
  static const double expanded = 1440.0;

  /// Maximum recommended width for focused single-column forms (like Login).
  static const double maxFormWidth = 440.0;

  /// Maximum content width to prevent extreme horizontal stretching on 4K/Ultrawide displays.
  static const double maxContentWidth = 1200.0;

  /// Escala máxima de texto de sistema que la UI soporta sin recortes.
  /// MaterialApp acota el textScaler a [1.0, maxTextScale] (ver main.dart);
  /// las alturas fijas que dependen de texto deben multiplicarse por
  /// `context.scaleForText` en lugar de quedarse fijas.
  static const double maxTextScale = 1.3;

  /// Umbral de ancho interno útil de tarjeta (constraints.maxWidth dentro de padding).
  /// Si el ancho interno es menor a este valor (< 315dp, típicamente pantallas
  /// con ancho total < 370dp como Poco X7 Pro o teléfonos compactos de 320–350dp),
  /// las tarjetas activan el modo compacto apilado para evitar desbordamientos.
  /// En pantallas estándar o amplias (>= 370dp como Poco X3 Pro, Tablets, Web),
  /// el ancho interno supera los 315dp y las tarjetas conservan su disposición
  /// horizontal original espaciosa.
  static const double compactCardContent = 315.0;
}

/// Convenience extensions on [BuildContext] for responsive layout checks.
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Returns true if screen width is less than 600px (phone / compact).
  bool get isCompact => screenWidth < AppBreakpoints.compact;

  /// Returns true if screen width is between 600px and 1023px (tablet / medium).
  bool get isMedium =>
      screenWidth >= AppBreakpoints.compact && screenWidth < AppBreakpoints.medium;

  /// Returns true if screen width is 1024px or higher (desktop / wide).
  bool get isExpanded => screenWidth >= AppBreakpoints.medium;

  /// Returns true for tablet and desktop viewports (>= 600px).
  bool get isWideScreen => screenWidth >= AppBreakpoints.compact;

  /// Number of responsive columns for enterprise card grids:
  /// - >= 1024px (Desktop / Widescreen): 3 columns
  /// - 600px to 1023px (Tablet): 2 columns
  /// - < 600px (Mobile): 1 column
  int get gridColumns {
    if (screenWidth >= AppBreakpoints.medium) return 3;
    if (screenWidth >= AppBreakpoints.compact) return 2;
    return 1;
  }

  /// Factor de escala efectivo del texto del sistema, acotado al rango que
  /// la UI soporta ([AppBreakpoints.maxTextScale]). Úsalo SOLO para escalar
  /// alturas fijas que contienen texto (extents de grid, tamaños de filas);
  /// los tamaños de fuente nunca se escalan a mano — van por AppTypography.
  double get scaleForText {
    final raw = MediaQuery.textScalerOf(this).scale(14) / 14;
    return raw.clamp(1.0, AppBreakpoints.maxTextScale);
  }
}
