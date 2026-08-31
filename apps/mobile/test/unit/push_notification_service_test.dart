import 'package:flutter_test/flutter_test.dart';
import 'package:civica_pago_mobile/core/network/push_notification_service.dart';

void main() {
  group('PushNotificationService Deep Linking Tests', () {
    late PushNotificationService service;

    setUp(() {
      service = PushNotificationService.instance;
    });

    test('init sets FCM token', () async {
      await service.init();
      expect(service.fcmToken, isNotNull);
      expect(service.fcmToken, contains('token'));
    });
  });
}
