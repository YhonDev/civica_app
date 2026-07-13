import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/features/propietarios/cobradores_repository.dart';
import 'package:civica_pago_mobile/features/propietarios/models/cobradores_models.dart';
import 'mock_http_adapter.dart';

void main() {
  late MockHttpAdapter mockAdapter;
  late CobradoresRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.init(baseUrl: 'http://test.local');
    mockAdapter = MockHttpAdapter();
    ApiClient.setHttpClientAdapter(mockAdapter);
    repository = CobradoresRepository();
  });

  group('CobradoresRepository.getCobradores', () {
    test('retorna cobradores con zonas mapeadas desde asignaciones', () async {
      mockAdapter.onGet('/usuarios', [
        {
          'id': 'USR_1',
          'nombre': 'Carlos Cobrador',
          'email': 'carlos@cobradores.com',
          'rol': 'COBRADOR',
          'asignaciones': [
            {
              'etapa': {'nombre': 'Etapa Alfa'},
            },
            {
              'etapa': {'nombre': 'Etapa Beta'},
            },
          ],
        },
        {
          'id': 'USR_2',
          'nombre': 'Ana Cobradora',
          'email': 'ana@cobradores.com',
          'rol': 'COBRADOR',
          'asignaciones': [],
        },
      ]);

      final cobradores = await repository.getCobradores();

      expect(cobradores.length, 2);

      // Carlos tiene 2 zonas
      expect(cobradores[0].nombre, 'Carlos Cobrador');
      expect(cobradores[0].zonas, ['Etapa Alfa', 'Etapa Beta']);
      expect(cobradores[0].correo, 'carlos@cobradores.com');

      // Ana sin zonas
      expect(cobradores[1].nombre, 'Ana Cobradora');
      expect(cobradores[1].zonas, isEmpty);
      expect(cobradores[1].activo, true);
    });

    test('cobrador sin email usa string vacío', () async {
      mockAdapter.onGet('/usuarios', [
        {
          'id': 'USR_3',
          'nombre': 'Sin Email',
          'rol': 'COBRADOR',
          'asignaciones': [],
        },
      ]);

      final cobradores = await repository.getCobradores();

      expect(cobradores.length, 1);
      expect(cobradores.first.correo, '');
    });

    test('asignaciones usa el campo correcto (asignaciones, no asignacionesEtapa)', () async {
      mockAdapter.onGet('/usuarios', [
        {
          'id': 'USR_4',
          'nombre': 'Test',
          'email': 'test@test.com',
          'rol': 'COBRADOR',
          'asignaciones': [
            {'etapa': {'nombre': 'Zona Única'}},
          ],
        },
      ]);

      final cobradores = await repository.getCobradores();

      expect(cobradores.first.zonas, ['Zona Única']);
    });
  });

  group('CobradoresRepository.getResumen', () {
    test('retorna resumen con total de cobradores', () async {
      mockAdapter.onGet('/usuarios', [
        {'id': 'U1', 'nombre': 'A', 'email': 'a@a.com', 'rol': 'COBRADOR', 'asignaciones': []},
        {'id': 'U2', 'nombre': 'B', 'email': 'b@b.com', 'rol': 'COBRADOR', 'asignaciones': []},
      ]);

      final resumen = await repository.getResumen();

      expect(resumen.totalCobradores, 2);
      expect(resumen.activos, 2);
      expect(resumen.inactivos, 0);
    });
  });

  group('CobradoresRepository — edge cases', () {
    test('asignaciones null se maneja como lista vacía', () async {
      mockAdapter.onGet('/usuarios', [
        {
          'id': 'USR_NULL',
          'nombre': 'Null Asig',
          'email': 'null@test.com',
          'rol': 'COBRADOR',
          // asignaciones ausente (null/undefined en JSON)
        },
      ]);

      final cobradores = await repository.getCobradores();

      expect(cobradores.length, 1);
      expect(cobradores.first.zonas, isEmpty);
    });

    test('etapa null en asignacion se filtra correctamente', () async {
      mockAdapter.onGet('/usuarios', [
        {
          'id': 'USR_FILTER',
          'nombre': 'Filter',
          'email': 'f@test.com',
          'rol': 'COBRADOR',
          'asignaciones': [
            {'etapa': null},
            {'etapa': {'nombre': 'Válida'}},
          ],
        },
      ]);

      final cobradores = await repository.getCobradores();

      expect(cobradores.first.zonas, ['Válida']);
      expect(cobradores.first.zonas.length, 1);
    });
  });

  group('CobradoresRepository — error handling', () {
    test('lanza Exception cuando la API falla', () async {
      expect(
        () => repository.getCobradores(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
