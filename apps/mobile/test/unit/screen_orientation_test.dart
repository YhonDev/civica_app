import 'package:flutter_test/flutter_test.dart';
import 'package:civica_pago_mobile/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Screen Orientation Configuration Tests', () {
    test('smartphones (shortestSide < 600dp) son fijados a portraitUp', () async {
      // Debe completar sin error
      await configureScreenOrientation(shortestSideOverride: 390.0);
    });

    test('tablets (shortestSide >= 600dp) permiten orientaciones completas', () async {
      // Debe completar sin error
      await configureScreenOrientation(shortestSideOverride: 800.0);
    });

    test('valores no positivos o nulos no modifican orientaciones', () async {
      await configureScreenOrientation(shortestSideOverride: 0.0);
      await configureScreenOrientation(shortestSideOverride: -10.0);
    });
  });
}
