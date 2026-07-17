import 'package:flutter_test/flutter_test.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/main.dart';

void main() {
  setUp(() async {
    ApiClient.init(
      baseUrl: 'http://localhost:3000',
      tokenStorage: TokenStorage(storage: InMemorySecureStorage()),
    );
  });

  testWidgets('App smoke test — shows login when unauthenticated',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CivicaPagoApp());

    // Let async AuthCubit.checkSession() complete (no server -> catch -> unauthenticated)
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    // Falls back to login screen when no session exists
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
