import 'dart:async';
import '../../core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import '../theme/app_typography.dart';
import '../theme/app_feedback.dart';
import '../theme/app_colors.dart';

/// Estándar global de notificaciones de la app.
///
/// Todo aviso no-bloqueante pasa por [TopToast]: éxito, error, información y
/// advertencia. Estilo único (doc/DESIGN_SYSTEM.md): tarjeta superior con
/// entrada elástica, tokenizados `AppColors.toast*`/`AppTypography` y
/// haptics por variante. Reglas:
///
/// - **Un solo slot:** mostrar un nuevo toast reemplaza al anterior
///   (nada de pilas de notificaciones).
/// - **Tap para cerrar:** la tarjeta responde al toque; además del
///   auto-cierre ([duration]).
/// - **Acción opcional:** [actionLabel] + [onAction] para deshacer/ver.
/// - Nada de `SnackBar`/`ScaffoldMessenger` fuera de este archivo
///   (regla de guardian 9.8; lo hace cumplir el design-token guard).
enum ToastType { success, error, info, warning }

class TopToast {
  TopToast._();

  static OverlayEntry? _current;

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    IconData? icon,
    Color? accentColor,
    ToastType type = ToastType.success,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    switch (type) {
      case ToastType.success:
        AppFeedback.success();
        break;
      case ToastType.error:
        AppFeedback.error();
        break;
      case ToastType.warning:
        AppFeedback.warning();
        break;
      case ToastType.info:
        AppFeedback.light();
        break;
    }

    // Un solo slot global: el toast anterior se retira antes de insertar.
    dismissCurrent();

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
        onRemoved: () {
          if (identical(_current, overlayEntry)) _current = null;
        },
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );

    _current = overlayEntry;
    overlayState.insert(overlayEntry);
  }

  /// Retira el toast visible, si lo hay, sin animación de salida.
  static void dismissCurrent() {
    final entry = _current;
    if (entry != null && entry.mounted) {
      entry.remove();
    }
    _current = null;
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

  static void showWarning(BuildContext context, String message, {String? title}) {
    show(context, message: message, title: title, type: ToastType.warning);
  }
}

class _TopToastWidget extends StatefulWidget {
  final String? title;
  final String message;
  final ToastType type;
  final IconData? customIcon;
  final Color? customColor;
  final VoidCallback onDismiss;
  final VoidCallback onRemoved;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _TopToastWidget({
    this.title,
    required this.message,
    required this.type,
    this.customIcon,
    this.customColor,
    required this.onDismiss,
    required this.onRemoved,
    required this.duration,
    this.actionLabel,
    this.onAction,
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

    _scheduleDismiss();
  }

  void _scheduleDismiss() {
    _dismissTimer?.cancel();
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

  void _handleTap() {
    if (widget.actionLabel != null && widget.onAction != null) {
      widget.onAction!();
    }
    _dismissTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
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
        iconColor = widget.customColor ?? AppColors.toastSuccess;
        icon = widget.customIcon ?? Icons.check_circle_rounded;
        break;
      case ToastType.error:
        iconColor = widget.customColor ?? AppColors.toastError;
        icon = widget.customIcon ?? Icons.error_rounded;
        break;
      case ToastType.warning:
        iconColor = widget.customColor ?? AppColors.toastWarning;
        icon = widget.customIcon ?? Icons.warning_rounded;
        break;
      case ToastType.info:
        iconColor = widget.customColor ?? AppColors.toastInfo;
        icon = widget.customIcon ?? Icons.info_rounded;
        break;
    }

    final cardBgColor = AppColors.toastSurface;
    final titleTextColor = AppColors.toastTitle;
    final bodyTextColor = AppColors.toastBody;
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
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _handleTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(AppSpacing.heroRadius),
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
                                style: AppTypography.caption.copyWith(
                                  color: titleTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              widget.message,
                              style: AppTypography.label.copyWith(
                                color: bodyTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (widget.actionLabel != null) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            widget.onAction?.call();
                            _dismissTimer?.cancel();
                            _controller.reverse().then((_) {
                              if (mounted) widget.onDismiss();
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: iconColor,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            widget.actionLabel!,
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
