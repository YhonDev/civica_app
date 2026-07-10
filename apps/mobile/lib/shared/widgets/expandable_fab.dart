import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class ExpandableFabAction {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const ExpandableFabAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });
}

class ExpandableFab extends StatefulWidget {
  final List<ExpandableFabAction> actions;
  final Color? backgroundColor;

  const ExpandableFab({
    super.key,
    required this.actions,
    this.backgroundColor,
  });

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Ensure the stack takes enough height. Assuming each item is ~50px and spacing.
      height: 250,
      width: 200,
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          _buildTapToCloseFab(),
          ..._buildExpandingActionButtons(),
          _buildTapToOpenFab(),
        ],
      ),
    );
  }

  Widget _buildTapToCloseFab() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.value == 0) return const SizedBox.shrink();
        return IgnorePointer(
          ignoring: !_open,
          child: GestureDetector(
            onTap: _toggle,
            child: Container(
              color: Colors.transparent, // Captures taps to close outside
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];
    final count = widget.actions.length;
    for (int i = 0; i < count; i++) {
      children.add(
        _ExpandingActionButton(
          directionInDegrees: 90,
          maxDistance: (i + 1) * 60.0,
          progress: _expandAnimation,
          action: widget.actions[i],
          onToggle: _toggle,
        ),
      );
    }
    return children;
  }

  Widget _buildTapToOpenFab() {
    return IgnorePointer(
      ignoring: _open,
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _open ? 0.7 : 1.0,
          _open ? 0.7 : 1.0,
          1.0,
        ),
        duration: const Duration(milliseconds: 250),
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        child: AnimatedOpacity(
          opacity: _open ? 0.0 : 1.0,
          curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          duration: const Duration(milliseconds: 250),
          child: FloatingActionButton(
            backgroundColor: widget.backgroundColor ?? AppColors.primary,
            onPressed: _toggle,
            shape: const CircleBorder(),
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _ExpandingActionButton extends StatelessWidget {
  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final ExpandableFabAction action;
  final VoidCallback onToggle;

  const _ExpandingActionButton({
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.action,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final offset = Offset.fromDirection(
          directionInDegrees * (math.pi / 180.0),
          progress.value * maxDistance,
        );
        return Positioned(
          right: 4.0,
          bottom: 4.0 + offset.dy,
          child: child!,
        );
      },
      child: FadeTransition(
        opacity: progress,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  action.label,
                  style: AppTypography.small.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              heroTag: null,
              backgroundColor: action.color ?? AppColors.surface,
              onPressed: () {
                onToggle();
                action.onPressed();
              },
              shape: const CircleBorder(),
              child: Icon(
                action.icon,
                color: action.color != null ? Colors.white : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
