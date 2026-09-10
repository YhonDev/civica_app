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

  /// Prefijos de ruta permitidos para deep links de push (fail-closed).
  /// Cualquier enlace que no empiece por uno de estos se descarta.
  static const List<String> kAllowedDeepLinkPrefixes = [
    '/ticket/',
    '/jornada',
    '/solicitudes',
    '/solicitud-nueva',
    '/estado',
    '/cartera',
    '/mi-casa',
    '/historial',
    '/sync-queue',
  ];

  /// Valida un deep link entrante de push: debe ser una ruta interna
  /// conocida. Rechaza esquemas externos (http://…), dobles slashes
  /// (`//host`) y rutas desconocidas. Visible para tests.
  @visibleForTesting
  bool isAllowedDeepLink(String? deepLink) {
    if (deepLink == null) return false;
    final link = deepLink.trim();
    if (link.isEmpty) return false;
    if (!link.startsWith('/')) return false;
    if (link.contains('//')) return false; // esquema o protocol-relative
    return kAllowedDeepLinkPrefixes.any(link.startsWith);
  }

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

      // Fallback: solo rutas internas de la allowlist. Un payload de push
      // nunca debe poder navegar a una pantalla arbitraria o esquema externo.
      if (isAllowedDeepLink(deepLink)) {
        context.push(deepLink);
      } else {
        debugPrint('[DeepLink] Deep link no permitido, ignorado: $deepLink');
      }
    } catch (e) {
      debugPrint('[DeepLink] Error executing deep link navigation to $deepLink: $e');
    }
  }
}
