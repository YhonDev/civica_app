import 'package:flutter/material.dart';
import '../theme/app_breakpoints.dart';

typedef ResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  BoxConstraints constraints,
);

/// A widget that switches between layout builders depending on available width.
class ResponsiveBuilder extends StatelessWidget {
  /// Builder for mobile / compact viewports (< 600px). Required.
  final ResponsiveWidgetBuilder compact;

  /// Builder for tablet / medium viewports (600px - 1023px).
  /// Falls back to [expanded] or [compact] if null.
  final ResponsiveWidgetBuilder? medium;

  /// Builder for desktop / expanded viewports (>= 1024px).
  /// Falls back to [medium] or [compact] if null.
  final ResponsiveWidgetBuilder? expanded;

  const ResponsiveBuilder({
    super.key,
    required this.compact,
    this.medium,
    this.expanded,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppBreakpoints.medium && expanded != null) {
          return expanded!(context, constraints);
        }
        if (constraints.maxWidth >= AppBreakpoints.compact) {
          if (medium != null) {
            return medium!(context, constraints);
          }
          if (expanded != null) {
            return expanded!(context, constraints);
          }
        }
        return compact(context, constraints);
      },
    );
  }
}

/// Constrains the child widget to a maximum width, centered horizontally.
/// Useful for preventing forms and cards from over-stretching on wide monitors.
class ContentConstrainedBox extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;
  final double? heightFactor;

  const ContentConstrainedBox({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.maxContentWidth,
    this.padding = EdgeInsets.zero,
    this.alignment = Alignment.center,
    this.heightFactor,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      heightFactor: heightFactor,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
