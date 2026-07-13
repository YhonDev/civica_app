import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/features/dashboard/dashboard_repository.dart';
import 'package:civica_pago_mobile/features/dashboard/models/dashboard_data.dart';
import 'mock_http_adapter.dart';

/// Simula la respuesta completa del endpoint GET /dashboard/administrador
Map<String, dynamic> _dashboardResponse() {
  return {
    'mes': 6,
    'anio': 2026,
    'resumen': {
      'recaudoTotal': 780000000,   // 7.8M en centavos
      'metaMensual': 1056000000,   // 10.56M
      'porcentajeMeta': 73.9,
      'pagaron': 65,
      'pendientes': 17,
      'moraTotal': 72000000,       // 720K
    },
    'evolucion': [
      {'dia': 1, 'valor': 120000000},
      {'dia': 5, 'valor': 350000000},
      {'dia': 10, 'valor': 580000000},
    ],
    'modalidades': [
      {'frecuencia': 'MENSUAL', 'totalCuotas': 80, 'pagadas': 50, 'porcentaje': 62.5, 'montoRecaudo': 500000000},
    ],
    'estadoCobros': {
      'pagados': 73.9,
      'pendientes': 19.3,
      'revision': 0,
    },
    'actividad': [
      {
        'id': 'A1',
        'tipo': 'pago',
        'descripcion': 'Pago registrado',
        'usuario': 'Juan Pérez',
        'timestamp': '2026-06-15T10:00:00Z',
        'hace': 'hace 5 min',
      },
    ],
    'solicitudesPendientes': 5,
    'propietariosMora': 6,
    'nuevosPropietariosSemana': 3,
    'acumuladoAnual': 3500000000,  // 35M
    'metaAnual': 12000000000,      // 120M
    'historialMeses': [
      {'mes': 1, 'anio': 2026, 'recaudo': 600000000, 'pendientes': 20, 'mora': 50000000},
      {'mes': 2, 'anio': 2026, 'recaudo': 650000000, 'pendientes': 18, 'mora': 55000000},
    ],
    'cobrosPorSemana': [],
  };
}

void main() {
  late MockHttpAdapter mockAdapter;
  late DashboardRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.init(baseUrl: 'http://test.local');
    mockAdapter = MockHttpAdapter();
    ApiClient.setHttpClientAdapter(mockAdapter);
    repository = DashboardRepository();
  });

  group('DashboardRepository.getDashboard', () {
    test('mapea todos los campos correctamente desde centavos a unidades', () async {
      mockAdapter.onGet('/dashboard/administrador', _dashboardResponse());
      mockAdapter.onGet('/propietarios', [
        {'id': 'P1', 'nombre': 'Juan'},
        {'id': 'P2', 'nombre': 'María'},
      ]);

      final data = await repository.getDashboard(6, 2026);

      expect(data.mes, 6);
      expect(data.anio, 2026);

      // Campos del resumen (centavos → unidades / 100)
      expect(data.recaudoMes, 7800000);     // 780,000,000 / 100
      expect(data.metaMensual, 10560000);   // 1,056,000,000 / 100
      expect(data.mora, 720000);            // 72,000,000 / 100
      expect(data.porcentaje, 73.9);
      expect(data.pagaron, 65);
      expect(data.pendientes, 17);

      // Campos de reportes anuales
      expect(data.acumuladoAnual, 35000000); // 3,500,000,000 / 100
      expect(data.metaAnual, 120000000);      // 12,000,000,000 / 100

      // Evolución
      expect(data.evolucion.length, 3);
      expect(data.evolucion[0].dia, '1');
      expect(data.evolucion[0].valor, 1200000); // 120,000,000 / 100

      // Modalidades
      expect(data.modalidades.length, 1);
      expect(data.modalidades[0].nombre, 'MENSUAL');
      expect(data.modalidades[0].porcentaje, 62.5);
      expect(data.modalidades[0].valor, 5000000); // 500,000,000 / 100

      // Estados de cobro
      expect(data.estadosCobro.length, 3);
      expect(data.estadosCobro[0].estado, 'Pagados');
      expect(data.estadosCobro[0].porcentaje, 73.9);

      // Actividad
      expect(data.actividadReciente.length, 1);
      expect(data.actividadReciente[0].tipo, 'pago');
      expect(data.actividadReciente[0].usuario, 'Juan Pérez');

      // Centro de atención
      expect(data.solicitudesPendientes, 5);
      expect(data.propietariosMora, 6);
      expect(data.nuevosPropietariosSemana, 3);
      expect(data.totalPropietarios, 2);

      // Historial meses
      expect(data.historialMeses.length, 2);
      expect(data.historialMeses[0].mes, 1);
      expect(data.historialMeses[0].recaudo, 6000000); // 600,000,000 / 100
      expect(data.historialMeses[0].pendientes, 20);

      // EstadosCobro con cantidad de pagaron/pendientes
      expect(data.estadosCobro[0].cantidad, 65);
      expect(data.estadosCobro[1].cantidad, 17);
    });

    test('maneja respuesta vacía con valores por defecto', () async {
      mockAdapter.onGet('/dashboard/administrador', {
        'mes': 1,
        'anio': 2026,
        'resumen': {},
        'estadoCobros': {},
      });
      mockAdapter.onGet('/propietarios', []);

      final data = await repository.getDashboard(1, 2026);

      expect(data.recaudoMes, 0);
      expect(data.metaMensual, 0);
      expect(data.mora, 0);
      expect(data.evolucion, isEmpty);
      expect(data.modalidades, isEmpty);
      expect(data.actividadReciente, isEmpty);
      expect(data.historialMeses, isEmpty);
      expect(data.totalPropietarios, 0);
    });

    test('resumen con campos nulos no causa error', () async {
      mockAdapter.onGet('/dashboard/administrador', {
        'mes': 6,
        'anio': 2026,
        'resumen': {},  // resumen vacío
        'estadoCobros': {},
      });
      mockAdapter.onGet('/propietarios', []);

      final data = await repository.getDashboard(6, 2026);

      expect(data.recaudoMes, 0);
      expect(data.metaMensual, 0);
      expect(data.mora, 0);
      expect(data.porcentaje, 0);
      expect(data.estadosCobro.length, 3);
    });
  });

  group('DashboardRepository — error handling', () {
    test('lanza Exception cuando falla la llamada API', () async {
      expect(
        () => repository.getDashboard(1, 2026),
        throwsA(isA<Exception>()),
      );
    });
  });
}
