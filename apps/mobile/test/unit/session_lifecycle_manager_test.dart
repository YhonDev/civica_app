import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:civica_pago_mobile/core/security/session_lifecycle_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionLifecycleManager Tests', () {
    late SessionLifecycleManager manager;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      manager = SessionLifecycleManager.instance;
    });

    tearDown(() {
      manager.dispose();
    });

    test('init y dispose administran estado correctamente', () {
      manager.init();
      // No debe lanzar y debe poder registrar actividad
      manager.recordUserActivity();
      manager.dispose();
    });

    test('closeApp invoca el handler inyectado onCloseApp', () async {
      bool appClosed = false;
      manager.init(
        onCloseApp: () async {
          appClosed = true;
        },
      );

      await manager.closeApp();
      expect(appClosed, isTrue);
    });

    test('triggerReauthentication delega en onReauthenticateRequired si está presente', () async {
      bool reauthenticated = false;
      manager.init(
        onReauthenticateRequired: () async {
          reauthenticated = true;
        },
      );

      await manager.triggerReauthentication();
      expect(reauthenticated, isTrue);
    });

    test('recordUserActivity es seguro antes y después de dispose', () {
      manager.init();
      manager.recordUserActivity();
      manager.dispose();
      manager.recordUserActivity();
    });
  });
}
