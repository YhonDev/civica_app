import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';

/// Un contenedor de scroll horizontal con desvanecimiento suave (fade) en los bordes.
/// Evita que los elementos parezcan "cortarse" bruscamente o salirse de la pantalla,
/// desvaneciéndolos con un degradado en la zona de margen exterior.
class FadingHorizontalScroll extends StatelessWidget {
  final Widget child;
  final ScrollController? controller;
  final ScrollPhysics physics;
  final EdgeInsetsGeometry padding;
  final double fadeWidth;

  const FadingHorizontalScroll({
    super.key,
    required this.child,
    this.controller,
    this.physics = const BouncingScrollPhysics(),
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
    this.fadeWidth = AppSpacing.screenPadding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        if (totalWidth <= 0 || totalWidth.isInfinite) {
          return SingleChildScrollView(
            controller: controller,
            scrollDirection: Axis.horizontal,
            physics: physics,
            padding: padding,
            child: child,
          );
        }

        final fadeFraction = (fadeWidth / totalWidth).clamp(0.01, 0.2);

        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: [
                0.0,
                fadeFraction,
                1.0 - fadeFraction,
                1.0,
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: SingleChildScrollView(
            controller: controller,
            scrollDirection: Axis.horizontal,
            physics: physics,
            padding: padding,
            child: child,
          ),
        );
      },
    );
  }
}
