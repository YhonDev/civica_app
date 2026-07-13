import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/features/propietarios/propietarios_repository.dart';
import 'package:civica_pago_mobile/features/propietarios/models/propietarios_models.dart';
import 'mock_http_adapter.dart';

/// Simula la respuesta de GET /conjuntos con una estructura anidada completa.
Map<String, dynamic> _conjuntosResponse() {
  return {
    'id': 'CJTO_1',
    'nombre': 'Urbanización Test',
    'tenantId': 't1',
    'etapas': [
      {
        'id': 'ETP_1',
        'nombre': 'Etapa Alfa',
        'manzanas': [
          {
            'id': 'MNZ_1',
            'nombre': 'Manzana A',
            'casas': [
              {'id': 'CSA_101', 'direccionInterna': 'Casa 101'},
              {'id': 'CSA_102', 'direccionInterna': 'Casa 102'},
            ],
          },
        ],
      },
    ],
  };
}

/// Simula la respuesta de GET /propietarios con tenencias, casa, manzana, etapa y cuotas.
List<Map<String, dynamic>> _propietariosResponse() {
  return [
    {
      'id': 'PRO_1',
      'nombre': 'Juan Pérez',
      'telefono': '555-0101',
      'email': 'juan@mail.com',
      'tenantId': 't1',
      'modalidadPago': 'MENSUAL',
      'tenencias': [
        {
          'casaId': 'CSA_101',
          'casa': {
            'id': 'CSA_101',
            'direccionInterna': 'Casa 101',
            'manzana': {
              'id': 'MNZ_1',
              'nombre': 'Manzana A',
              'etapa': {
                'id': 'ETP_1',
                'nombre': 'Etapa Alfa',
              },
            },
          },
        },
      ],
      'cuotas': [
        {'monto': 5000000, 'montoPagado': 5000000, 'estado': 'PAGADA'},
      ],
    },
    {
      'id': 'PRO_2',
      'nombre': 'María García',
      'telefono': '555-0102',
      'tenantId': 't1',
      'modalidadPago': 'MENSUAL',
      'tenencias': [
        {
          'casaId': 'CSA_102',
          'casa': {
            'id': 'CSA_102',
            'direccionInterna': 'Casa 102',
            'manzana': {
              'id': 'MNZ_1',
              'nombre': 'Manzana A',
              'etapa': {
                'id': 'ETP_1',
                'nombre': 'Etapa Alfa',
              },
            },
          },
        },
      ],
      'cuotas': [
        {'monto': 5000000, 'montoPagado': 0, 'estado': 'VENCIDA'},
        {'monto': 5000000, 'montoPagado': 0, 'estado': 'PENDIENTE'},
      ],
    },
  ];
}

void main() {
  late MockHttpAdapter mockAdapter;
  late PropietariosRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.init(baseUrl: 'http://test.local');
    mockAdapter = MockHttpAdapter();
    ApiClient.setHttpClientAdapter(mockAdapter);
    repository = PropietariosRepository();
  });

  group('PropietariosRepository.getPropietarios', () {
    test('retorna lista de propietarios mapeados correctamente', () async {
      mockAdapter.onGet('/propietarios', _propietariosResponse());
      mockAdapter.onGet('/conjuntos', [_conjuntosResponse()]);

      final result = await repository.getPropietarios();

      expect(result.length, 2);

      // Juan Pérez — pagado → Al Día, saldo 0
      expect(result[0].nombre, 'María García'); // reversed
      expect(result[1].nombre, 'Juan Pérez');
      expect(result[1].estadoFinanciero, 'Al Día');
      expect(result[1].saldoPendiente, 0);
      expect(result[1].casa, 'Manzana A - Casa 101');
      expect(result[1].etapa, 'Etapa Alfa');
      expect(result[1].email, 'juan@mail.com');
      expect(result[1].modalidadPago, 'MENSUAL');

      // María García — vencida + pendiente → Mora, saldo = 100,000 (10,000,000 cents / 100 = 100,000.0)
      expect(result[0].estadoFinanciero, 'Mora');
      expect(result[0].saldoPendiente, 100000.0); // 10,000,000 cents = 100,000
      expect(result[0].telefono, '555-0102');
    });

    test('propietario sin tenencias usa valores por defecto', () async {
      mockAdapter.onGet('/propietarios', [
        {
          'id': 'PRO_3',
          'nombre': 'Sin Casa',
          'telefono': '000',
          'tenantId': 't1',
          'tenencias': [],
          'cuotas': [],
        },
      ]);
      mockAdapter.onGet('/conjuntos', [_conjuntosResponse()]);

      final result = await repository.getPropietarios();

      expect(result.length, 1);
      expect(result.first.casa, 'Sin manzana - Sin casa');
      expect(result.first.etapa, 'Sin etapa');
      expect(result.first.estadoFinanciero, 'Al Día');
      expect(result.first.saldoPendiente, 0);
    });
  });

  group('PropietariosRepository.getResumen', () {
    test('calcula total, ocupadas y vacantes correctamente', () async {
      mockAdapter.onGet('/conjuntos', [_conjuntosResponse()]);
      // 2 casas en el conjunto: 101, 102
      // 1 propietario con tenencia activa (PRO_1) → 1 ocupada
      mockAdapter.onGet('/propietarios', [
        _propietariosResponse()[0], // solo Juan Pérez (tiene CSA_101)
      ]);

      final resumen = await repository.getResumen();

      expect(resumen.totalPropiedades, 2);
      expect(resumen.ocupadas, 1);
      expect(resumen.vacantes, 1);
    });
  });

  group('PropietariosRepository — edge cases', () {
    test('propietario con cuota PARCIAL: repo no calcula saldo (solo VENCIDA/PENDIENTE)', () async {
      mockAdapter.onGet('/propietarios', [
        {
          'id': 'PRO_PARCIAL',
          'nombre': 'Pago Parcial',
          'telefono': '555-0001',
          'tenantId': 't1',
          'tenencias': [],
          'cuotas': [
            {'monto': 5000000, 'montoPagado': 2000000, 'estado': 'PARCIAL'},
          ],
        },
      ]);

      final result = await repository.getPropietarios();

      // PARCIAL no es VENCIDA ni PENDIENTE → el repo no lo procesa
      expect(result.first.estadoFinanciero, 'Al Día');
      expect(result.first.saldoPendiente, 0); // PARCIAL no se contabiliza
    });

    test('propietario con email null no causa error', () async {
      mockAdapter.onGet('/propietarios', [
        {
          'id': 'PRO_NO_EMAIL',
          'nombre': 'Sin Email',
          'telefono': '555-0002',
          'tenantId': 't1',
          // sin email
          'tenencias': [],
          'cuotas': [],
        },
      ]);
      mockAdapter.onGet('/conjuntos', [_conjuntosResponse()]);

      final result = await repository.getPropietarios();

      expect(result.length, 1);
      expect(result.first.email, isNull);
      expect(result.first.nombre, 'Sin Email');
    });
  });

  group('PropietariosRepository — error handling', () {
    test('lanza ApiException cuando el servidor responde con error', () async {
      // No registramos mock → MockHttpAdapter lanza DioException
      expect(
        () => repository.getPropietarios(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
