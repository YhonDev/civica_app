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

  group('evaluarCasaParaRecorrido — TODOS', () {
    test('incluye casa con cualquier cuota con saldo (cualquier ciclo)', () {
      final casa = _casa(cuotas: [
        {'estado': 'PENDIENTE', 'saldo': 10000, 'fechaVencimiento': '2026-09-26'},
      ]);

      expect(
        evaluarCasaParaRecorrido(casa, 'TODOS', '2026-09-12'),
        CasaFiltroVeredicto.incluir,
      );
    });

    test('excluye casa totalmente pagada', () {
      final casa = _casa(
        estado: 'AL_DIA',
        saldo: 0,
        cuotas: [
          {'estado': 'PAGADO', 'saldo': 0, 'fechaVencimiento': '2026-09-12'},
        ],
      );

      expect(
        evaluarCasaParaRecorrido(casa, 'TODOS', '2026-09-12'),
        CasaFiltroVeredicto.excluir,
      );
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
