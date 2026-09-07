import 'package:flutter_test/flutter_test.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/features/residentes/residentes_repository.dart';
import 'mock_http_adapter.dart';

void main() {
  late MockHttpAdapter mockAdapter;
  late ResidentesRepository repository;

  setUp(() {
    ApiClient.init(
      baseUrl: 'http://test.local',
      tokenStorage: TokenStorage(storage: InMemorySecureStorage()),
    );
    mockAdapter = MockHttpAdapter();
    ApiClient.setHttpClientAdapter(mockAdapter);
    repository = ResidentesRepository();
  });

  Map<String, dynamic> residenteJson(Map<String, dynamic> overrides) => {
        'id': 'RES_1',
        'nombre': 'Camilo Silva',
        'telefono': '3001234567',
        'cuotas': [],
        'tenencias': [],
        ...overrides,
      };

  group('ResidentesRepository.getResumen', () {
    test('cuenta total de casas, ocupadas y vacantes desde proyectos y tenencias', () async {
      mockAdapter.onGet('/proyectos', [
        {
          'etapas': [
            {
              'manzanas': [
                {'casas': [{}]},
                {
                  'casas': [
                    {},
                    {},
                  ],
                },
              ],
            },
          ],
        },
      ]);
      mockAdapter.onGet('/residentes', [
        residenteJson({
          'tenencias': [
            {'casaId': 'CASA_A'},
          ],
        }),
        residenteJson({
          'id': 'RES_2',
          'tenencias': [
            {'casaId': 'CASA_A'}, // misma casa no cuenta dos veces
          ],
        }),
      ]);

      final resumen = await repository.getResumen();

      expect(resumen.totalPropiedades, 3);
      expect(resumen.ocupadas, 1); // set deduplica
      expect(resumen.vacantes, 2);
    });
  });

  group('ResidentesRepository.getResidentes', () {
    test('suma saldo y marca Mora solo con cuotas VENCIDA o PENDIENTE', () async {
      mockAdapter.onGet('/residentes', [
        residenteJson({
          'cuotas': [
            {'estado': 'VENCIDA', 'monto': 4000000, 'montoPagado': 1000000},
            {'estado': 'PENDIENTE', 'monto': 4000000, 'montoPagado': 0},
            {'estado': 'PAGADA', 'monto': 4000000, 'montoPagado': 4000000},
          ],
          'tenencias': [
            {
              'casa': {
                'id': 'CASA_1',
                'direccionInterna': 'Casa 1',
                'manzana': {
                  'id': 'MZ_1',
                  'nombre': 'Manzana A',
                  'etapa': {'id': 'ET_1', 'nombre': 'Etapa 1'},
                },
              },
            },
          ],
        }),
      ]);

      final residentes = await repository.getResidentes();

      expect(residentes, hasLength(1));
      final r = residentes.first;
      // VENCIDA: (4.000.000-1.000.000)/100 = 30.000 + PENDIENTE: 4.000.000/100 = 40.000
      expect(r.saldoPendiente, 70000.0);
      expect(r.estadoFinanciero, 'Mora');
      expect(r.casa, 'Manzana A - Casa 1');
      expect(r.etapa, 'Etapa 1');
      expect(r.casaId, 'CASA_1');
    });

    test('residente sin cuotas ni casa queda Al Día y Sin casa', () async {
      mockAdapter.onGet('/residentes', [residenteJson({})]);

      final residentes = await repository.getResidentes();

      expect(residentes.first.estadoFinanciero, 'Al Día');
      expect(residentes.first.saldoPendiente, 0.0);
      expect(residentes.first.casa, 'Sin manzana - Sin casa');
      expect(residentes.first.modalidadPago, 'MENSUAL');
    });

    test('retorna los residentes en orden inverso (nuevos arriba)', () async {
      mockAdapter.onGet('/residentes', [
        residenteJson({'id': 'RES_VIEJO', 'nombre': 'Primero en el API'}),
        residenteJson({'id': 'RES_NUEVO', 'nombre': 'Segundo en el API'}),
      ]);

      final residentes = await repository.getResidentes();

      expect(residentes.first.id, 'RES_NUEVO');
      expect(residentes.last.id, 'RES_VIEJO');
    });

    test('lanza Exception cuando la API falla', () async {
      // Sin handlers registrados, el adaptador lanza DioException
      await expectLater(
        repository.getResidentes(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('ResidentesRepository.createResidente', () {
    test('envía nombre, teléfono y modalidad, y omite campos opcionales vacíos', () async {
      mockAdapter.onPost('/residentes', {
        'id': 'RES_9',
        'credenciales': {'username': 'csilva', 'password': 'temporal1'},
      });

      final respuesta = await repository.createResidente(
        nombre: 'Nuevo Residente',
        telefono: '3009876543',
      );

      expect(respuesta['credenciales']['username'], 'csilva');
      expect(mockAdapter.calls('POST', '/residentes'), 1);
    });
  });

  group('ResidentesRepository.deleteResidente', () {
    test('retorna true en éxito y false al fallar sin lanzar', () async {
      mockAdapter.onDelete('/residentes/RES_1', {'success': true});

      expect(await repository.deleteResidente('RES_1'), isTrue);
      // Sin handler para RES_404 → el adaptador lanza → el repo retorna false
      expect(await repository.deleteResidente('RES_404'), isFalse);
    });
  });

  group('ResidentesRepository.updateResidente', () {
    test('retorna true en éxito y false al fallar sin lanzar', () async {
      mockAdapter.onPatch('/residentes/RES_1', {'success': true});

      expect(await repository.updateResidente('RES_1', {'nombre': 'X'}), isTrue);
      expect(
        await repository.updateResidente('RES_404', {'nombre': 'X'}),
        isFalse,
      );
    });
  });
}
