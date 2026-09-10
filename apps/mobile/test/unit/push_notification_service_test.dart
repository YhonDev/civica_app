import 'package:flutter_test/flutter_test.dart';
import 'package:civica_pago_mobile/core/network/push_notification_service.dart';

/// Guardian de deep links: el payload de un push nunca debe poder navegar
/// a una pantalla arbitraria o a un esquema externo (http://, //host, etc.).
void main() {
  final service = PushNotificationService.instance;

  group('PushNotificationService.isAllowedDeepLink', () {
    test('permite rutas internas de la allowlist', () {
      expect(service.isAllowedDeepLink('/ticket/abc-123'), isTrue);
      expect(service.isAllowedDeepLink('/jornada'), isTrue);
      expect(service.isAllowedDeepLink('/solicitudes'), isTrue);
      expect(service.isAllowedDeepLink('/estado'), isTrue);
      expect(service.isAllowedDeepLink('/cartera'), isTrue);
      expect(service.isAllowedDeepLink('/mi-casa'), isTrue);
      expect(service.isAllowedDeepLink('/historial'), isTrue);
      expect(service.isAllowedDeepLink('/sync-queue'), isTrue);
    });

    test('rechaza nulo, vacío y strings sin ruta', () {
      expect(service.isAllowedDeepLink(null), isFalse);
      expect(service.isAllowedDeepLink(''), isFalse);
      expect(service.isAllowedDeepLink('   '), isFalse);
      expect(service.isAllowedDeepLink('ticket/abc'), isFalse);
    });

    test('rechaza esquemas externos y protocol-relative', () {
      expect(service.isAllowedDeepLink('https://evil.example.com/login'), isFalse);
      expect(service.isAllowedDeepLink('http://127.0.0.1:3000/api'), isFalse);
      expect(service.isAllowedDeepLink('//evil.example.com/login'), isFalse);
      expect(service.isAllowedDeepLink('javascript:alert(1)'), isFalse);
      expect(service.isAllowedDeepLink('file:///etc/passwd'), isFalse);
    });

    test('rechaza rutas internas desconocidas (fail-closed)', () {
      expect(service.isAllowedDeepLink('/configuracion'), isFalse);
      expect(service.isAllowedDeepLink('/comunidad/residentes'), isFalse);
      expect(service.isAllowedDeepLink('/ruta-inexistente'), isFalse);
    });

    test('el tipo PAGO_REGISTRADO mantiene su ruta dedicada /ticket/', () {
      // La rama por tipo usa /ticket/<pagoId>: misma allowlist.
      expect(service.isAllowedDeepLink('/ticket/x'), isTrue);
    });
  });
}
