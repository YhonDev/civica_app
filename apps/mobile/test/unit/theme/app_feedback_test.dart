import 'package:flutter_test/flutter_test.dart';
import 'package:civica_pago_mobile/core/theme/app_feedback.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppFeedback', () {
    test('selection completes without throwing', () async {
      await expectLater(AppFeedback.selection(), completes);
    });

    test('light completes without throwing', () async {
      await expectLater(AppFeedback.light(), completes);
    });

    test('medium completes without throwing', () async {
      await expectLater(AppFeedback.medium(), completes);
    });

    test('success completes without throwing', () async {
      await expectLater(AppFeedback.success(), completes);
    });

    test('warning completes without throwing', () async {
      await expectLater(AppFeedback.warning(), completes);
    });

    test('error completes without throwing', () async {
      await expectLater(AppFeedback.error(), completes);
    });
  });
}
