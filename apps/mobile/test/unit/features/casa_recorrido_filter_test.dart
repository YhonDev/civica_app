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
    test('PENDIENTES conserva el comportamiento previo por estado de casa', () {
      expect(
        evaluarCasaParaRecorrido(_casa(estado: 'VENCIDA', saldo: 10000), 'PENDIENTES', null),
        CasaFiltroVeredicto.incluir,
      );
      expect(
        evaluarCasaParaRecorrido(_casa(estado: 'AL_DIA', saldo: 0), 'PENDIENTES', null),
        CasaFiltroVeredicto.excluir,
      );
    });
  });
}
