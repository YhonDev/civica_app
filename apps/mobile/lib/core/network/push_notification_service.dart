import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Enterprise Push Notification & Deep Linking Handler for Flutter.
///
/// Processes incoming FCM Push Notification payloads when the user taps
/// a system banner or native notification, routing them directly to the
/// relevant domain screen (e.g. Ticket de Pago, Jornada de Cobro, Solicitudes).
class PushNotificationService {
  static final PushNotificationService instance = PushNotificationService._internal();

  PushNotificationService._internal();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initializes device token for FCM push dispatching
  Future<void> init() async {
    // Register the token through the push provider in production. Do not log it.
    _fcmToken = null;
  }

  /// Handles deep linking navigation when notification banner is tapped
  void handleDeepLinkPayload(Map<String, dynamic> data, BuildContext context) {
    debugPrint('[PushNotificationService] Processing notification payload');

    final deepLink = data['deepLink'] as String?;
    final type = data['type'] as String?;

    if (deepLink == null || deepLink.isEmpty) return;

    try {
      if (type == 'PAGO_REGISTRADO') {
        final pagoId = data['pagoId'] as String?;
        if (pagoId != null && pagoId.isNotEmpty) {
          debugPrint('[DeepLink] Navigating to Ticket de Pago screen for $pagoId');
          context.push('/ticket/$pagoId');
          return;
        }
      }

      if (type == 'SOLICITUD_CREADA') {
        debugPrint('[DeepLink] Navigating to Jornada de Cobro screen');
        context.go('/jornada');
        return;
      }

      // Fallback router navigation
      context.push(deepLink);
    } catch (e) {
      debugPrint('[DeepLink] Error executing deep link navigation to $deepLink: $e');
    }
  }
}
