import 'package:flutter_test/flutter_test.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/features/cartera/cartera_repository.dart';
import 'mock_http_adapter.dart';

/// Mock cuotas con diferentes estados, montos y propietarios anidados.
List<Map<String, dynamic>> _cuotasResponse() {
  return [
    // PAGADA
    {
      'id': 'CUO_1',
      'monto': 5000000,     // 50,000 COP en centavos
      'montoPagado': 5000000,
      'estado': 'PAGADA',
      'residente': {
        'id': 'PRO_1',
        'nombre': 'Juan Pérez',
        'tenencias': [
          {
            'casa': {
              'direccionInterna': 'Casa 101',
              'manzana': {'nombre': 'Manzana A', 'etapa': {'nombre': 'Etapa Alfa'}},
            },
          },
        ],
      },
    },
    // VENCIDA
    {
      'id': 'CUO_2',
      'monto': 5000000,
      'montoPagado': 2000000,  // pagó parcial
      'estado': 'VENCIDA',
      'residente': {
        'id': 'PRO_2',
        'nombre': 'María García',
        'tenencias': [
          {
            'casa': {
              'direccionInterna': 'Casa 102',
              'manzana': {'nombre': 'Manzana A', 'etapa': {'nombre': 'Etapa Alfa'}},
            },
          },
        ],
      },
    },
    // PENDIENTE (sin pagos)
    {
      'id': 'CUO_3',
      'monto': 5000000,
      'montoPagado': 0,
      'estado': 'PENDIENTE',
      'residente': {
        'id': 'PRO_3',
        'nombre': 'Pedro López',
        'tenencias': [],
      },
    },
  ];
}

void main() {
  late MockHttpAdapter mockAdapter;
  late CarteraRepository repository;

  setUp(() {
    ApiClient.init(
      baseUrl: 'http://test.local',
      tokenStorage: TokenStorage(storage: InMemorySecureStorage()),
    );
    mockAdapter = MockHttpAdapter();
    ApiClient.setHttpClientAdapter(mockAdapter);
    repository = CarteraRepository();
  });

  group('CarteraRepository.getCarteraResumen', () {
    test('agrega correctamente montos por estado (PAGADA, VENCIDA, PENDIENTE)', () async {
      mockAdapter.onGet('/cobros', _cuotasResponse());

      final resumen = await repository.getCarteraResumen();

      // CUO_1: PAGADA → 50,000 pagado
      // CUO_2: VENCIDA → monto=50,000, pagado=20,000 → mora=30,000
      // CUO_3: PENDIENTE → monto=50,000, pagado=0 → pendiente=50,000
      expect(resumen.cantidadPagados, 1);
      expect(resumen.cantidadMora, 1);
      expect(resumen.cantidadPendientes, 1);

      expect(resumen.totalPagado, 70000);  // 50,000 + 20,000
      expect(resumen.totalMora, 30000);    // 50,000 - 20,000
      expect(resumen.totalPendiente, 50000); // 50,000 - 0
    });

    test('lista vacía retorna todo en cero', () async {
      mockAdapter.onGet('/cobros', []);

      final resumen = await repository.getCarteraResumen();

      expect(resumen.cantidadPagados, 0);
      expect(resumen.cantidadMora, 0);
      expect(resumen.cantidadPendientes, 0);
      expect(resumen.totalPagado, 0);
      expect(resumen.totalMora, 0);
      expect(resumen.totalPendiente, 0);
    });
  });

  group('CarteraRepository.getCobros', () {
    test('mapea correctamente estados y datos del propietario', () async {
      mockAdapter.onGet('/cobros', _cuotasResponse());

      final cobros = await repository.getCobros();

      expect(cobros.length, 3);

      // PAGADA
      expect(cobros[0].estado, 'Pagado');
      expect(cobros[0].nombre, 'Juan Pérez');
      expect(cobros[0].saldo, 0);
      expect(cobros[0].casa, 'Casa 101');
      expect(cobros[0].manzana, 'Manzana A');
      expect(cobros[0].etapa, 'Etapa Alfa');

      // VENCIDA
      expect(cobros[1].estado, 'Mora');
      expect(cobros[1].nombre, 'María García');
      expect(cobros[1].saldo, 30000); // 50,000 - 20,000
      expect(cobros[1].casa, 'Casa 102');
      expect(cobros[1].manzana, 'Manzana A');

      // PENDIENTE con tenencias vacías
      expect(cobros[2].estado, 'Pendiente');
      expect(cobros[2].nombre, 'Pedro López');
      expect(cobros[2].saldo, 50000);
      expect(cobros[2].casa, 'Sin casa');
      expect(cobros[2].manzana, 'Sin manzana');
      expect(cobros[2].etapa, 'Sin etapa');
    });

    test('propietario nulo usa valores por defecto', () async {
      mockAdapter.onGet('/cobros', [
        {
          'id': 'CUO_X',
          'monto': 1000000,
          'montoPagado': 0,
          'estado': 'PENDIENTE',
          // sin residente
        },
      ]);

      final cobros = await repository.getCobros();

      expect(cobros.length, 1);
      expect(cobros[0].nombre, 'Desconocido');
      expect(cobros[0].residenteId, '');
      expect(cobros[0].casa, 'Sin casa');
      expect(cobros[0].manzana, 'Sin manzana');
      expect(cobros[0].etapa, 'Sin etapa');
    });
  });

  group('CarteraRepository.registrarPago', () {
    test('envía POST a /pagos con los datos correctos', () async {
      mockAdapter.onPost('/pagos', {'id': 'PAG_NEW'});

      final result = await repository.registrarPago(
        residenteId: 'PRO_1',
        montoCentavos: 5000000,
      );

      expect(mockAdapter.calls('POST', '/pagos'), 1);
      expect(result['id'], 'PAG_NEW');
    });
  });

  group('CarteraRepository — edge cases', () {
    test('cuota en estado PARCIAL se trata como pendiente en getCobros', () async {
      mockAdapter.onGet('/cobros', [
        {
          'id': 'CUO_PARCIAL',
          'monto': 5000000,
          'montoPagado': 3000000,
          'estado': 'PARCIAL',
          'residente': {
            'id': 'PRO_P',
            'nombre': 'Parcial',
            'tenencias': [],
          },
        },
      ]);

      final cobros = await repository.getCobros();

      // Estado PARCIAL no tiene mapeo explícito → cae a 'Pendiente'
      expect(cobros[0].estado, 'Pendiente');
      expect(cobros[0].saldo, 20000); // (50,000 - 30,000)
    });

    test('cuota en estado PARCIAL se suma al resumen como pendiente y abono', () async {
      mockAdapter.onGet('/cobros', [
        {
          'id': 'CUO_PP',
          'monto': 5000000,
          'montoPagado': 3000000,
          'estado': 'PARCIAL',
          'residente': {'id': 'P1', 'nombre': 'Test', 'tenencias': []},
        },
      ]);

      final resumen = await repository.getCarteraResumen();

      // PARCIAL se mapea a Pendiente, por lo que suma al saldo pendiente y al total pagado
      expect(resumen.cantidadPagados, 0);
      expect(resumen.cantidadMora, 0);
      expect(resumen.cantidadPendientes, 1);
      expect(resumen.totalPagado, 30000.0);
      expect(resumen.totalMora, 0.0);
      expect(resumen.totalPendiente, 20000.0);
    });
  });

  group('CarteraRepository — error handling', () {
    test('lanza Exception cuando la API falla en getCarteraResumen', () async {
      expect(
        () => repository.getCarteraResumen(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('CarteraRepository — role-aware endpoint selection', () {
    test('PROPIETARIO calls GET /cobros/residente/{id} for getCarteraResumen', () async {
      final propRepo = CarteraRepository(
        role: 'PROPIETARIO',
        residenteId: 'PROP_42',
      );

      mockAdapter.onGet('/cobros/residente/PROP_42', [
        {
          'id': 'CUO_R1',
          'monto': 5000000,
          'montoPagado': 0,
          'estado': 'PENDIENTE',
          'residente': {
            'id': 'PROP_42',
            'nombre': 'Prop Test',
            'tenencias': [],
          },
        },
      ]);

      final resumen = await propRepo.getCarteraResumen();

      expect(mockAdapter.calls('GET', '/cobros/residente/PROP_42'), 1);
      expect(mockAdapter.calls('GET', '/cobros'), 0);
      expect(resumen.cantidadPendientes, 1);
    });

    test('COBRADOR calls GET /cobros for getCarteraResumen', () async {
      final cobradorRepo = CarteraRepository(
        role: 'COBRADOR',
      );

      mockAdapter.onGet('/cobros', []);

      await cobradorRepo.getCarteraResumen();

      expect(mockAdapter.calls('GET', '/cobros'), 1);
    });

    test('PROPIETARIO calls GET /cobros/residente/{id} for getCobros', () async {
      final propRepo = CarteraRepository(
        role: 'PROPIETARIO',
        residenteId: 'PROP_42',
      );

      mockAdapter.onGet('/cobros/residente/PROP_42', [
        {
          'id': 'CUO_R2',
          'monto': 5000000,
          'montoPagado': 2000000,
          'estado': 'VENCIDA',
          'residente': {
            'id': 'PROP_42',
            'nombre': 'Prop Test',
            'tenencias': [],
          },
        },
      ]);

      final cobros = await propRepo.getCobros();

      expect(mockAdapter.calls('GET', '/cobros/residente/PROP_42'), 1);
      expect(cobros.length, 1);
      expect(cobros[0].nombre, 'Prop Test');
    });

    test('without role falls back to GET /cobros (backward compatible)', () async {
      final defaultRepo = CarteraRepository();

      mockAdapter.onGet('/cobros', _cuotasResponse());

      final resumen = await defaultRepo.getCarteraResumen();

      expect(mockAdapter.calls('GET', '/cobros'), 1);
      expect(resumen.cantidadPagados, 1);
    });
  });
}
