import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_typography.dart';

enum ToastType { success, error, info, warning }

class TopToast {
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    IconData? icon,
    Color? accentColor,
    ToastType type = ToastType.success,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _TopToastWidget(
        title: title,
        message: message,
        type: type,
        customIcon: icon,
        customColor: accentColor,
        onDismiss: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
        duration: duration,
      ),
    );

    overlayState.insert(overlayEntry);
  }

  static void showSuccess(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title, type: ToastType.success);
  }

  static void showError(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title, type: ToastType.error);
  }

  static void showInfo(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title, type: ToastType.info);
  }
}

class _TopToastWidget extends StatefulWidget {
  final String? title;
  final String message;
  final ToastType type;
  final IconData? customIcon;
  final Color? customColor;
  final VoidCallback onDismiss;
  final Duration duration;

  const _TopToastWidget({
    this.title,
    required this.message,
    required this.type,
    this.customIcon,
    this.customColor,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    _dismissTimer = Timer(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            widget.onDismiss();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color iconColor;
    IconData icon;

    switch (widget.type) {
      case ToastType.success:
        iconColor = widget.customColor ?? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF166534));
        icon = widget.customIcon ?? Icons.check_circle_rounded;
        break;
      case ToastType.error:
        iconColor = widget.customColor ?? (isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B));
        icon = widget.customIcon ?? Icons.error_rounded;
        break;
      case ToastType.warning:
        iconColor = widget.customColor ?? (isDark ? const Color(0xFFFACC15) : const Color(0xFF854D0E));
        icon = widget.customIcon ?? Icons.warning_rounded;
        break;
      case ToastType.info:
        iconColor = widget.customColor ?? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF075985));
        icon = widget.customIcon ?? Icons.info_rounded;
        break;
    }

    final cardBgColor = isDark ? const Color(0xFF1E2022) : Colors.white;
    final titleTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final bodyTextColor = isDark ? Colors.white.withValues(alpha: 0.88) : const Color(0xFF334155);
    final shadowColor = isDark ? Colors.black.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.12);
    final borderColor = isDark ? iconColor.withValues(alpha: 0.35) : iconColor.withValues(alpha: 0.25);

    return Positioned(
      top: topPadding + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            bottom: false,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: borderColor, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.title != null) ...[
                            Text(
                              widget.title!,
                              style: AppTypography.body.copyWith(
                                color: titleTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            widget.message,
                            style: AppTypography.caption.copyWith(
                              color: bodyTextColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
