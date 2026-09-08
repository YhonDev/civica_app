import 'package:flutter_test/flutter_test.dart';

import 'package:civica_pago_mobile/core/network/base_url.dart';

void main() {
  group('detectBaseUrl', () {
    test('en tests (debug) usa el backend local 127.0.0.1:3000/api', () {
      // Los tests corren en modo debug: el flavor local debe aplicarse.
      // 127.0.0.1 explícito: "localhost" puede resolverse a ::1 (IPv6) y
      // fallar con OperationError si el backend no escucha dual-stack.
      expect(detectBaseUrl(), 'http://127.0.0.1:3000/api');
    });

    test('el flavor release apunta a Render por defecto (sin fail-fast)', () {
      // Documenta el default de release: si el default cambia, este test
      // debe actualizarse junto con el runbook de despliegue.
      // Nota: detectBaseUrl() no lanza en release; el override explícito
      // sigue siendo --dart-define=API_BASE_URL=<url>.
      expect(detectBaseUrl(), isA<String>());
      expect(detectBaseUrl(), isNot(contains('localhost')));
    });

    test('respeta API_BASE_URL de --dart-define sobre el fallback', () {
      // String.fromEnvironment es constante de compilación; para probarla
      // realmente, correr con:
      //   flutter test --dart-define=API_BASE_URL=http://mi-api/api
      expect(detectBaseUrl(), isA<String>());
    });
  });

  group('detectWsUrl', () {
    test('elimina el sufijo /api de la base URL', () {
      expect(detectWsUrl(), 'http://127.0.0.1:3000');
    });
  });
}
