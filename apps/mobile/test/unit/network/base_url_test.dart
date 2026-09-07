import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:civica_pago_mobile/core/network/base_url.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('detectBaseUrl', () {
    test('usa 127.0.0.1:3000/api en Android (ruta adb reverse)', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(detectBaseUrl(), 'http://127.0.0.1:3000/api');
    });

    test('usa localhost:3000/api en plataformas no-Android', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(detectBaseUrl(), 'http://localhost:3000/api');
    });
  });

  group('detectWsUrl', () {
    test('elimina el sufijo /api de la base URL', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(detectWsUrl(), 'http://127.0.0.1:3000');
    });
  });
}
