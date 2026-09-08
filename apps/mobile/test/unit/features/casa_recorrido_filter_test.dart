import 'package:flutter_test/flutter_test.dart';

import 'package:civica_pago_mobile/features/dashboard_cobrador/casas_cubit.dart';

CasaExplorer _casa({
  String estado = 'PENDIENTE',
  int saldo = 10000,
  List<Map<String, dynamic>> cuotas = const [],
}) {
  return CasaExplorer(
    id: 'casa-1',
    direccion: 'Casa 1',
    residenteNombre: 'Camilo Silva',
    residenteTelefono: '',
    estado: estado,
    saldo: saldo,
    cuotas: cuotas,
  );
}

void main() {
  group('evaluarCasaParaRecorrido — PENDIENTES con fecha de corte', () {
    test('incluye cuota de la semana actual (vence el sábado del recorrido)', () {
      final casa = _casa(cuotas: [
        {'estado': 'PENDIENTE', 'saldo': 10000, 'fechaVencimiento': '2026-09-12'},
      ]);

      expect(
        evaluarCasaParaRecorrido(casa, 'PENDIENTES', '2026-09-12'),
        CasaFiltroVeredicto.incluir,
      );
    });

    test('excluye cuota que vence en un recorrido futuro', () {
      final casa = _casa(cuotas: [
        {'estado': 'PENDIENTE', 'saldo': 10000, 'fechaVencimiento': '2026-09-26'},
      ]);

      expect(
        evaluarCasaParaRecorrido(casa, 'PENDIENTES', '2026-09-12'),
        CasaFiltroVeredicto.excluir,
      );
    });

    test('cuota vencida se reporta como mora, no como pendiente', () {
      final casa = _casa(cuotas: [
        {'estado': 'VENCIDA', 'saldo': 10000, 'fechaVencimiento': '2026-09-05'},
      ]);

      expect(
        evaluarCasaParaRecorrido(casa, 'PENDIENTES', '2026-09-12'),
        CasaFiltroVeredicto.mora,
      );
    });

    test('mezcla: mora domina, pero cuota vigente incluye aunque haya futuras', () {
      final casaConVigente = _casa(cuotas: [
        {'estado': 'VENCIDA', 'saldo': 5000, 'fechaVencimiento': '2026-09-05'},
        {'estado': 'PENDIENTE', 'saldo': 10000, 'fechaVencimiento': '2026-09-12'},
        {'estado': 'PENDIENTE', 'saldo': 10000, 'fechaVencimiento': '2026-09-26'},
      ]);
      expect(
        evaluarCasaParaRecorrido(casaConVigente, 'PENDIENTES', '2026-09-12'),
        CasaFiltroVeredicto.incluir,
      );
    });

    test('cuota pagada (saldo 0) no incluye la casa', () {
      final casa = _casa(cuotas: [
        {'estado': 'PAGADO', 'saldo': 0, 'fechaVencimiento': '2026-09-12'},
      ]);

      expect(
        evaluarCasaParaRecorrido(casa, 'PENDIENTES', '2026-09-12'),
        CasaFiltroVeredicto.excluir,
      );
    });

    test('cuota parcial de la semana incluye', () {
      final casa = _casa(cuotas: [
        {'estado': 'PARCIAL', 'saldo': 4000, 'fechaVencimiento': '2026-09-12'},
      ]);

      expect(
        evaluarCasaParaRecorrido(casa, 'PENDIENTES', '2026-09-12'),
        CasaFiltroVeredicto.incluir,
      );
    });
  });

  group('evaluarCasaParaRecorrido — MORA', () {
    test('incluye casa con cuota vencida y saldo', () {
      final casa = _casa(cuotas: [
        {'estado': 'VENCIDA', 'saldo': 10000, 'fechaVencimiento': '2026-09-05'},
      ]);

      expect(
        evaluarCasaParaRecorrido(casa, 'MORA', '2026-09-12'),
        CasaFiltroVeredicto.incluir,
      );
    });

    test('excluye casa solo con cuotas pendientes de la semana', () {
      final casa = _casa(cuotas: [
        {'estado': 'PENDIENTE', 'saldo': 10000, 'fechaVencimiento': '2026-09-12'},
      ]);

      expect(
        evaluarCasaParaRecorrido(casa, 'MORA', '2026-09-12'),
        CasaFiltroVeredicto.excluir,
      );
    });

    test('fallback al estado de la casa cuando no hay detalle de cuotas', () {
      expect(
        evaluarCasaParaRecorrido(
          _casa(estado: 'VENCIDA', saldo: 10000),
          'MORA',
          '2026-09-12',
        ),
        CasaFiltroVeredicto.incluir,
      );
      expect(
        evaluarCasaParaRecorrido(
          _casa(estado: 'PENDIENTE', saldo: 10000),
          'MORA',
          '2026-09-12',
        ),
        CasaFiltroVeredicto.excluir,
      );
    });
  });

  group('evaluarCasaParaRecorrido — filtros inexistentes', () {
    test('un filtro desconocido excluye la casa (solo existen PENDIENTES y MORA)', () {
      final casa = _casa(cuotas: [
        {'estado': 'PENDIENTE', 'saldo': 10000, 'fechaVencimiento': '2026-09-26'},
      ]);

      expect(
        evaluarCasaParaRecorrido(casa, 'TODOS', '2026-09-12'),
        CasaFiltroVeredicto.excluir,
      );
    });
  });

  group('fechaVencimientoMasAntiguaDeCuotas y compararCasasPorMoraAntigua', () {
    test('devuelve la fecha más antigua entre cuotas con saldo', () {
      final cuotas = [
        {'saldo': 10000, 'fechaVencimiento': '2026-09-12'},
        {'saldo': 5000, 'fechaVencimiento': '2026-08-29'},
        {'saldo': 0, 'fechaVencimiento': '2026-07-01'}, // pagada: se ignora
      ];

      expect(fechaVencimientoMasAntiguaDeCuotas(cuotas), '2026-08-29');
    });

    test('sin fechas con saldo devuelve cadena vacía y ordena al final', () {
      final sinFechas = _casa(cuotas: [
        {'saldo': 9000, 'fechaVencimiento': null},
      ]);
      final conFecha = _casa(cuotas: [
        {'saldo': 9000, 'fechaVencimiento': '2026-08-29'},
      ]);

      expect(fechaVencimientoMasAntiguaDeCuotas(sinFechas.cuotas), '');
      expect(compararCasasPorMoraAntigua(sinFechas, conFecha), 1);
      expect(compararCasasPorMoraAntigua(conFecha, sinFechas), -1);
    });

    test('mora: la deuda más vieja queda primero', () {
      final vieja = _casa(cuotas: [
        {'saldo': 10000, 'fechaVencimiento': '2026-08-01'},
      ]);
      final reciente = _casa(cuotas: [
        {'saldo': 10000, 'fechaVencimiento': '2026-09-05'},
      ]);

      expect(compararCasasPorMoraAntigua(vieja, reciente), lessThan(0));
      expect(compararCasasPorMoraAntigua(reciente, vieja), greaterThan(0));
      expect(compararCasasPorMoraAntigua(vieja, vieja), 0);
    });
  });

  group('evaluarCasaParaRecorrido — compatibilidad sin fecha de corte', () {
    test('PENDIENTES incluye PENDIENTE/PARCIAL y clasifica VENCIDA como mora', () {
      expect(
        evaluarCasaParaRecorrido(_casa(estado: 'PENDIENTE', saldo: 10000), 'PENDIENTES', null),
        CasaFiltroVeredicto.incluir,
      );
      expect(
        evaluarCasaParaRecorrido(_casa(estado: 'PARCIAL', saldo: 5000), 'PENDIENTES', null),
        CasaFiltroVeredicto.incluir,
      );
      expect(
        evaluarCasaParaRecorrido(_casa(estado: 'VENCIDA', saldo: 10000), 'PENDIENTES', null),
        CasaFiltroVeredicto.mora,
      );
      expect(
        evaluarCasaParaRecorrido(_casa(estado: 'AL_DIA', saldo: 0), 'PENDIENTES', null),
        CasaFiltroVeredicto.excluir,
      );
    });
  });

  group('evaluarCasaParaRecorrido — filtrado por sábados (R2, R3, R4)', () {
    final casaMulticuota = _casa(cuotas: [
      {'id': 'c1', 'estado': 'VENCIDA', 'saldo': 25000, 'fechaVencimiento': '2026-09-05', 'tituloCuota': 'Septiembre · Cuota 1'},
      {'id': 'c2', 'estado': 'PENDIENTE', 'saldo': 25000, 'fechaVencimiento': '2026-09-12', 'tituloCuota': 'Septiembre · Cuota 2'},
      {'id': 'c3', 'estado': 'PENDIENTE', 'saldo': 25000, 'fechaVencimiento': '2026-09-19', 'tituloCuota': 'Septiembre · Cuota 3'},
      {'id': 'c4', 'estado': 'PENDIENTE', 'saldo': 25000, 'fechaVencimiento': '2026-09-26', 'tituloCuota': 'Septiembre · Cuota 4'},
    ]);

    test('R2 (12 Sep) incluye la cuota 2', () {
      expect(
        evaluarCasaParaRecorrido(casaMulticuota, 'PENDIENTES', '2026-09-12'),
        CasaFiltroVeredicto.incluir,
      );
    });

    test('R3 (19 Sep) incluye la cuota 3', () {
      expect(
        evaluarCasaParaRecorrido(casaMulticuota, 'PENDIENTES', '2026-09-19'),
        CasaFiltroVeredicto.incluir,
      );
    });

    test('casa que solo tiene cuota en R4 (26 Sep, mensual) se excluye de R2 y R3', () {
      final casaMensual = _casa(cuotas: [
        {'id': 'cm', 'estado': 'PENDIENTE', 'saldo': 100000, 'fechaVencimiento': '2026-09-26', 'tituloCuota': 'Septiembre · Cuota Única'},
      ]);

      expect(
        evaluarCasaParaRecorrido(casaMensual, 'PENDIENTES', '2026-09-12'),
        CasaFiltroVeredicto.excluir,
      );
      expect(
        evaluarCasaParaRecorrido(casaMensual, 'PENDIENTES', '2026-09-19'),
        CasaFiltroVeredicto.excluir,
      );
      expect(
        evaluarCasaParaRecorrido(casaMensual, 'PENDIENTES', '2026-09-26'),
        CasaFiltroVeredicto.incluir,
      );
    });
  });

  group('obtenerCuotaParaRecorrido', () {
    final casa = _casa(cuotas: [
      {'id': 'cuota-1', 'estado': 'VENCIDA', 'saldo': 20000, 'fechaVencimiento': '2026-09-05', 'tituloCuota': 'Septiembre · Cuota 1'},
      {'id': 'cuota-2', 'estado': 'PENDIENTE', 'saldo': 25000, 'fechaVencimiento': '2026-09-12', 'tituloCuota': 'Septiembre · Cuota 2'},
      {'id': 'cuota-3', 'estado': 'PENDIENTE', 'saldo': 25000, 'fechaVencimiento': '2026-09-19', 'tituloCuota': 'Septiembre · Cuota 3'},
    ]);

    test('extrae la cuota 2 al seleccionar sábado 12 de septiembre (R2)', () {
      final info = obtenerCuotaParaRecorrido(casa, 'PENDIENTES', '2026-09-12');
      expect(info.id, 'cuota-2');
      expect(info.nombre, 'Septiembre · Cuota 2');
      expect(info.monto, 25000);
      expect(info.fechaVencimiento, '2026-09-12');
      expect(info.estado, 'PENDIENTE');
    });

    test('extrae la cuota 3 al seleccionar sábado 19 de septiembre (R3)', () {
      final info = obtenerCuotaParaRecorrido(casa, 'PENDIENTES', '2026-09-19');
      expect(info.id, 'cuota-3');
      expect(info.nombre, 'Septiembre · Cuota 3');
      expect(info.monto, 25000);
      expect(info.fechaVencimiento, '2026-09-19');
      expect(info.estado, 'PENDIENTE');
    });

    test('en MORA extrae la cuota vencida más antigua con saldo', () {
      final info = obtenerCuotaParaRecorrido(casa, 'MORA', null);
      expect(info.id, 'cuota-1');
      expect(info.nombre, 'Septiembre · Cuota 1');
      expect(info.monto, 20000);
      expect(info.fechaVencimiento, '2026-09-05');
      expect(info.estado, 'VENCIDA');
    });
  });
}
