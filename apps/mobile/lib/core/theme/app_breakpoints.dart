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
}
