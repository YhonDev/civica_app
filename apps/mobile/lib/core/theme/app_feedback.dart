import 'package:flutter/services.dart';

/// Global enterprise tactile feedback service for Cívica Pago.
///
/// Centralizes all haptic interactions across all screens and modules,
/// ensuring consistent, ergonomic physical response on key operations
/// (e.g. payment registration, modality selection, stepper progress).
class AppFeedback {
  AppFeedback._();

  /// Subtle click for filter chips, tabs, stepper nodes, and toggles.
  static Future<void> selection() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Light impact for standard button presses and item taps.
  static Future<void> light() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Medium impact for key state transitions (e.g. opening payment sheet).
  static Future<void> medium() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Satisfying physical confirmation when a payment or critical action completes successfully.
  static Future<void> success() async {
    try {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Alert feedback for overdue cuotas, warnings, or caution modals.
  static Future<void> warning() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Error feedback for failed validation or connection issues.
  static Future<void> error() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 80));
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}
