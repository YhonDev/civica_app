import 'package:flutter/material.dart';
import 'package:civica_pago_mobile/core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Un contenedor de scroll horizontal con desvanecimiento suave (fade) en los bordes.
/// Es adaptativo: cuando el scroll está en el inicio (offset 0), el borde izquierdo
/// se muestra 100% nítido sin difuminación. Solo aplica desvanecimiento en el borde
/// que realmente tiene contenido oculto para scrollear.
class FadingHorizontalScroll extends StatefulWidget {
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
  State<FadingHorizontalScroll> createState() => _FadingHorizontalScrollState();
}

class _FadingHorizontalScrollState extends State<FadingHorizontalScroll> {
  ScrollController? _internalController;
  ScrollController get _effectiveController =>
      widget.controller ?? (_internalController ??= ScrollController());

  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _effectiveController.addListener(_checkScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScroll());
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _internalController?.dispose();
    } else {
      widget.controller?.removeListener(_checkScroll);
    }
    super.dispose();
  }

  void _checkScroll() {
    if (!mounted || !_effectiveController.hasClients) return;
    final pos = _effectiveController.position;
    final canLeft = pos.pixels > 1.0;
    final canRight =
        pos.maxScrollExtent > 1.0 && pos.pixels < (pos.maxScrollExtent - 1.0);

    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        if (totalWidth <= 0 || totalWidth.isInfinite) {
          return SingleChildScrollView(
            controller: _effectiveController,
            scrollDirection: Axis.horizontal,
            physics: widget.physics,
            padding: widget.padding,
            child: widget.child,
          );
        }

        if (!_canScrollLeft && !_canScrollRight) {
          return NotificationListener<ScrollNotification>(
            onNotification: (notif) {
              _checkScroll();
              return false;
            },
            child: SingleChildScrollView(
              controller: _effectiveController,
              scrollDirection: Axis.horizontal,
              physics: widget.physics,
              padding: widget.padding,
              child: widget.child,
            ),
          );
        }

        final fadeFraction = (widget.fadeWidth / totalWidth).clamp(0.01, 0.2);

        return NotificationListener<ScrollNotification>(
          onNotification: (notif) {
            _checkScroll();
            return false;
          },
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  _canScrollLeft ? Colors.transparent : AppColors.onPrimary,
                  AppColors.onPrimary,
                  AppColors.onPrimary,
                  _canScrollRight ? Colors.transparent : AppColors.onPrimary,
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
              controller: _effectiveController,
              scrollDirection: Axis.horizontal,
              physics: widget.physics,
              padding: widget.padding,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}
