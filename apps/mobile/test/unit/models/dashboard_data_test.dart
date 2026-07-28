import 'package:flutter_test/flutter_test.dart';

import 'package:civica_pago_mobile/features/dashboard/models/dashboard_data.dart';

void main() {
  // ─────────────────────────────────────────────────────────────
  // DashboardData (principal)
  // ─────────────────────────────────────────────────────────────
  group('DashboardData', () {
    final validJson = <String, dynamic>{
      'mes': 3,
      'anio': 2026,
      'resumen': {
        'recaudoTotal': 780000000, // cents → 7,800,000.00
        'metaMensual': 105600000, // cents → 1,056,000.00
        'pagaron': 65,
        'pendientes': 17,
        'moraTotal': 72000000, // cents → 720,000.00
        'porcentajeMeta': 73.9,
      },
      'estadoCobros': {
        'pagados': 73.9,
        'pendientes': 19.3,
        'revision': 6.8,
      },
      'evolucion': [
        {'dia': '01', 'valor': 120000000},
        {'dia': '15', 'valor': 780000000},
      ],
      'modalidades': [
        {'modalidad': 'MENSUAL', 'porcentaje': 65, 'montoRecaudo': 507000000},
      ],
      'actividad': [
        {
          'id': 'A1',
          'tipo': 'pago_registrado',
          'descripcion': 'Pagó la cuota mensual',
          'usuario': 'Juan Pérez',
          'timestamp': '2026-03-15T10:30:00.000Z',
          'hace': 'hace 5 min',
        },
      ],
      'solicitudesPendientes': 5,
      'residentesMora': 6,
      'nuevosResidentesSemana': 3,
      'acumuladoAnual': 2100000000,
      'metaAnual': 12672000000,
      'historialMeses': [
        {'mes': 1, 'anio': 2026, 'recaudo': 650000000, 'pendientes': 12, 'mora': 50000000},
        {'mes': 2, 'anio': 2026, 'recaudo': 720000000, 'pendientes': 15, 'mora': 60000000},
      ],
    };

    test('fromJson -> campos mapeados con división de centavos', () {
      final data = DashboardData.fromJson(validJson);

      expect(data.mes, 3);
      expect(data.anio, 2026);
      expect(data.recaudoMes, 7800000); // 780000000 / 100
      expect(data.metaMensual, 1056000); // 105600000 / 100
      expect(data.pagaron, 65);
      expect(data.pendientes, 17);
      expect(data.mora, 720000); // 72000000 / 100
      expect(data.porcentaje, 73.9);
      expect(data.solicitudesPendientes, 5);
      expect(data.residentesMora, 6);
      expect(data.nuevosResidentesSemana, 3);
      expect(data.acumuladoAnual, 21000000); // 2100000000 / 100
      expect(data.metaAnual, 126720000); // 12672000000 / 100
    });

    test('fromJson -> listas se mapean correctamente', () {
      final data = DashboardData.fromJson(validJson);

      expect(data.evolucion.length, 2);
      expect(data.evolucion[0].dia, '01');
      expect(data.evolucion[0].valor, 1200000); // 120000000 / 100

      expect(data.modalidades.length, 1);
      expect(data.modalidades[0].nombre, 'MENSUAL');
      expect(data.modalidades[0].porcentaje, 65);
      expect(data.modalidades[0].valor, 5070000); // 507000000 / 100

      expect(data.actividadReciente.length, 1);
      expect(data.actividadReciente[0].id, 'A1');

      expect(data.estadosCobro.length, 3);
      expect(data.estadosCobro[0].estado, 'Pagados');
      expect(data.estadosCobro[0].porcentaje, 73.9);

      expect(data.historialMeses.length, 2);
      expect(data.historialMeses[0].mes, 1);
      expect(data.historialMeses[0].recaudo, 6500000); // 650000000 / 100
    });

    test('fromJson -> null resumen usa defaults', () {
      final data = DashboardData.fromJson({
        'mes': '3',
        'anio': '2026',
      });

      expect(data.recaudoMes, 0);
      expect(data.metaMensual, 0);
      expect(data.pagaron, 0);
      expect(data.pendientes, 0);
      expect(data.mora, 0);
      expect(data.porcentaje, 0);
      expect(data.evolucion, []);
      expect(data.modalidades, []);
      expect(data.actividadReciente, []);
      expect(data.historialMeses, []);
    });

    test('fromJson -> string numéricos se parsean correctamente', () {
      final data = DashboardData.fromJson({
        'mes': '6',
        'anio': '2027',
        'resumen': {
          'recaudoTotal': '5000000',
          'metaMensual': '10000000',
          'pagaron': '30',
          'pendientes': '5',
          'moraTotal': '100000',
          'porcentajeMeta': '50.5',
        },
        'estadoCobros': {'pagados': '50', 'pendientes': '30', 'revision': '20'},
      });

      expect(data.mes, 6);
      expect(data.anio, 2027);
      expect(data.recaudoMes, 50000);
      expect(data.metaMensual, 100000);
      expect(data.pagaron, 30);
      expect(data.pendientes, 5);
      expect(data.mora, 1000);
      expect(data.porcentaje, 50.5);
    });

    test('fromJson -> estadoCobros null usa defaults', () {
      final data = DashboardData.fromJson({
        'mes': 1,
        'anio': 2026,
        'resumen': {
          'recaudoTotal': 0,
          'metaMensual': 0,
          'pagaron': 0,
          'pendientes': 0,
          'moraTotal': 0,
          'porcentajeMeta': 0,
        },
      });

      expect(data.estadosCobro.length, 3);
      expect(data.estadosCobro[0].porcentaje, 0);
      expect(data.estadosCobro[1].porcentaje, 0);
      // moraPct = 100 - pagadosPct (0) - pendientesPct (0) = 100
      expect(data.estadosCobro[2].porcentaje, 100);
    });

    test('fromJson -> campos string inválidos → 0', () {
      final data = DashboardData.fromJson({
        'mes': 'no-es-numero',
        'anio': 'invalido',
      });

      expect(data.mes, 0);
      expect(data.anio, 0);
    });

    test('Equatable -> igualdad por props', () {
      final a = DashboardData.fromJson(validJson);
      final b = DashboardData.fromJson(validJson);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('Equatable -> distinto mes no es igual', () {
      final a = DashboardData.fromJson(validJson);
      final b = DashboardData.fromJson({...validJson, 'mes': 4});
      expect(a, isNot(equals(b)));
    });
  });

  // ─────────────────────────────────────────────────────────────
  // EvolucionPunto
  // ─────────────────────────────────────────────────────────────
  group('EvolucionPunto', () {
    test('fromJson -> valors y división de centavos', () {
      final punto = EvolucionPunto.fromJson({
        'dia': '05',
        'valor': 350000000,
      });

      expect(punto.dia, '05');
      expect(punto.valor, 3500000);
    });

    test('fromJson -> campos null → defaults vacíos', () {
      final punto = EvolucionPunto.fromJson({});

      expect(punto.dia, '');
      expect(punto.valor, 0);
    });

    test('Equatable', () {
      final a = EvolucionPunto.fromJson({'dia': '01', 'valor': 100000});
      final b = EvolucionPunto.fromJson({'dia': '01', 'valor': 100000});
      final c = EvolucionPunto.fromJson({'dia': '02', 'valor': 100000});

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  // ─────────────────────────────────────────────────────────────
  // ModalidadItem
  // ─────────────────────────────────────────────────────────────
  group('ModalidadItem', () {
    test('fromJson -> modalidad mapeada a nombre, montoRecaudo a valor', () {
      final item = ModalidadItem.fromJson({
        'modalidad': 'MENSUAL',
        'porcentaje': 65,
        'montoRecaudo': 507000000,
      });

      expect(item.nombre, 'MENSUAL');
      expect(item.porcentaje, 65);
      expect(item.valor, 5070000);
    });

    test('fromJson -> campos null → 0 / vacío', () {
      final item = ModalidadItem.fromJson({});
      expect(item.nombre, '');
      expect(item.porcentaje, 0);
      expect(item.valor, 0);
    });

    test('Equatable', () {
      final a = ModalidadItem.fromJson({'modalidad': 'SEMANAL', 'porcentaje': 10, 'montoRecaudo': 100000});
      final b = ModalidadItem.fromJson({'modalidad': 'SEMANAL', 'porcentaje': 10, 'montoRecaudo': 100000});
      final c = ModalidadItem.fromJson({'modalidad': 'MENSUAL', 'porcentaje': 10, 'montoRecaudo': 100000});
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  // ─────────────────────────────────────────────────────────────
  // CobroEstadoItem
  // ─────────────────────────────────────────────────────────────
  group('CobroEstadoItem', () {
    test('fromJson -> mapeo directo sin división de centavos', () {
      final item = CobroEstadoItem.fromJson({
        'estado': 'Pagados',
        'porcentaje': 73.9,
        'cantidad': 65,
      });

      expect(item.estado, 'Pagados');
      expect(item.porcentaje, 73.9);
      expect(item.cantidad, 65);
    });

    test('fromJson -> null defaults', () {
      final item = CobroEstadoItem.fromJson({});
      expect(item.estado, '');
      expect(item.porcentaje, 0);
      expect(item.cantidad, 0);
    });

    test('Equatable', () {
      final a = const CobroEstadoItem(estado: 'Mora', porcentaje: 10, cantidad: 5);
      final b = const CobroEstadoItem(estado: 'Mora', porcentaje: 10, cantidad: 5);
      final c = const CobroEstadoItem(estado: 'Pagados', porcentaje: 10, cantidad: 5);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  // ─────────────────────────────────────────────────────────────
  // ActividadItem
  // ─────────────────────────────────────────────────────────────
  group('ActividadItem', () {
    test('fromJson -> todos los campos', () {
      final item = ActividadItem.fromJson({
        'id': 'A1',
        'tipo': 'pago_registrado',
        'descripcion': 'Pagó la cuota mensual',
        'usuario': 'Juan Pérez',
        'timestamp': '2026-03-15T10:30:00.000Z',
        'hace': 'hace 5 min',
      });

      expect(item.id, 'A1');
      expect(item.tipo, 'pago_registrado');
      expect(item.descripcion, 'Pagó la cuota mensual');
      expect(item.usuario, 'Juan Pérez');
      expect(item.timestamp, DateTime.utc(2026, 3, 15, 10, 30, 0));
      expect(item.hace, 'hace 5 min');
    });

    test('fromJson -> timestamp inválido usa DateTime.now()', () {
      final item = ActividadItem.fromJson({
        'id': 'A2',
        'tipo': 'test',
        'descripcion': 'test',
        'usuario': 'Test',
        'timestamp': 'no-es-fecha',
        'hace': 'hace 1h',
      });

      expect(item.id, 'A2');
      // Should be close to now (within 2 seconds)
      expect(
        item.timestamp.difference(DateTime.now()).inSeconds.abs(),
        lessThan(2),
      );
    });

    test('fromJson -> null defaults', () {
      final item = ActividadItem.fromJson({});
      expect(item.id, '');
      expect(item.tipo, '');
      expect(item.descripcion, '');
      expect(item.usuario, '');
      expect(item.hace, '');
    });

    test('Equatable', () {
      final now = DateTime.now();
      final a = ActividadItem.fromJson({
        'id': 'A1', 'tipo': 'pago', 'descripcion': 'test',
        'usuario': 'U', 'timestamp': now.toIso8601String(), 'hace': '1m',
      });
      final b = ActividadItem.fromJson({
        'id': 'A1', 'tipo': 'pago', 'descripcion': 'test',
        'usuario': 'U', 'timestamp': now.toIso8601String(), 'hace': '1m',
      });
      expect(a, equals(b));
    });
  });

  // ─────────────────────────────────────────────────────────────
  // CobroSemanaItem
  // ─────────────────────────────────────────────────────────────
  group('CobroSemanaItem', () {
    test('fromJson -> todos los campos', () {
      final item = CobroSemanaItem.fromJson({
        'semana': 2,
        'pagados': 40,
        'pendientes': 12,
        'mora': 4,
      });

      expect(item.semana, 2);
      expect(item.pagados, 40);
      expect(item.pendientes, 12);
      expect(item.mora, 4);
    });

    test('fromJson -> null defaults (semana=1, resto=0)', () {
      final item = CobroSemanaItem.fromJson({});
      expect(item.semana, 1);
      expect(item.pagados, 0);
      expect(item.pendientes, 0);
      expect(item.mora, 0);
    });

    test('Equatable', () {
      final a = const CobroSemanaItem(semana: 1, pagados: 10, pendientes: 2, mora: 1);
      final b = const CobroSemanaItem(semana: 1, pagados: 10, pendientes: 2, mora: 1);
      final c = const CobroSemanaItem(semana: 2, pagados: 10, pendientes: 2, mora: 1);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  // ─────────────────────────────────────────────────────────────
  // MesHistorico
  // ─────────────────────────────────────────────────────────────
  group('MesHistorico', () {
    test('fromJson -> todos los campos con división de centavos', () {
      final mes = MesHistorico.fromJson({
        'mes': 2,
        'anio': 2026,
        'recaudo': 720000000,
        'pendientes': 15,
        'mora': 60000000,
      });

      expect(mes.mes, 2);
      expect(mes.anio, 2026);
      expect(mes.recaudo, 7200000); // 720000000 / 100
      expect(mes.pendientes, 15);
      expect(mes.mora, 600000); // 60000000 / 100
    });

    test('fromJson -> null defaults (mes=1, anio=2026, resto=0)', () {
      final mes = MesHistorico.fromJson({});
      expect(mes.mes, 1);
      expect(mes.anio, 2026);
      expect(mes.recaudo, 0);
      expect(mes.pendientes, 0);
      expect(mes.mora, 0);
    });

    test('Equatable', () {
      final a = MesHistorico.fromJson({'mes': 1, 'anio': 2026, 'recaudo': 100, 'pendientes': 5, 'mora': 10});
      final b = MesHistorico.fromJson({'mes': 1, 'anio': 2026, 'recaudo': 100, 'pendientes': 5, 'mora': 10});
      final c = MesHistorico.fromJson({'mes': 2, 'anio': 2026, 'recaudo': 100, 'pendientes': 5, 'mora': 10});
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
