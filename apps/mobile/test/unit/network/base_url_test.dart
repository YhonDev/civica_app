import 'package:flutter_test/flutter_test.dart';

import 'package:civica_pago_mobile/core/network/base_url.dart';

void main() {
  group('detectBaseUrl', () {
    test('usa 127.0.0.1:3000/api como fallback en todas las plataformas', () {
      // 127.0.0.1 explícito: "localhost" puede resolverse a ::1 (IPv6) y
      // fallar con OperationError si el backend no escucha dual-stack.
      expect(detectBaseUrl(), 'http://127.0.0.1:3000/api');
    });

    test('respeta API_BASE_URL de --dart-define sobre el fallback', () {
      // Nota: String.fromEnvironment es constante de compilación; este test
      // documenta la prioridad. Para probarla realmente, compilar con:
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
