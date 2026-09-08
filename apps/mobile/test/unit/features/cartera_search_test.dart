import 'package:flutter_test/flutter_test.dart';
import 'package:civica_pago_mobile/features/cartera/cartera_screen.dart';
import 'package:civica_pago_mobile/features/cartera/models/cartera_models.dart';

void main() {
  group('CarteraScreen.matchesSearch — Intelligent Multi-Token Search Engine', () {
    final danielaCobro = CobroItem(
      id: 'cobro-daniela-1',
      residenteId: 'res-daniela',
      nombre: 'Daniela Bedoya Castro',
      etapa: 'Etapa 1',
      manzana: 'Manzana C',
      casa: 'Casa 1',
      concepto: 'Septiembre — Cuota 1',
      monto: 10000,
      montoPagado: 0,
      saldo: 10000,
      fechaVencimiento: '2026-09-05',
      estado: 'PENDIENTE',
      modalidad: 'SEMANAL',
      nroRecibo: 'TK-4A9BD6',
    );

    final simonCobro = CobroItem(
      id: 'cobro-simon-1',
      residenteId: 'res-simon',
      nombre: 'Simón Montoya Henao',
      etapa: 'Etapa 1',
      manzana: 'Manzana C',
      casa: 'Casa 4',
      concepto: 'Septiembre — Cuota 1',
      monto: 10000,
      montoPagado: 0,
      saldo: 10000,
      fechaVencimiento: '2026-09-05',
      estado: 'VENCIDA',
      modalidad: 'SEMANAL',
      nroRecibo: 'TK-SIMON4',
    );

    final camiloCobro = CobroItem(
      id: 'cobro-camilo-2',
      residenteId: 'res-camilo',
      nombre: 'Camilo Silva',
      etapa: 'Etapa 1',
      manzana: 'Manzana A',
      casa: 'Casa 1',
      concepto: 'Septiembre — Cuota 2',
      monto: 10000,
      montoPagado: 0,
      saldo: 10000,
      fechaVencimiento: '2026-09-12',
      estado: 'PENDIENTE',
      modalidad: 'SEMANAL',
      nroRecibo: 'TK-CAMILO2',
    );

    test('empty query matches all items', () {
      expect(CarteraScreen.matchesSearch(danielaCobro, ''), isTrue);
      expect(CarteraScreen.matchesSearch(danielaCobro, '   '), isTrue);
    });

    test('matches by first name, last name or full name regardless of case', () {
      expect(CarteraScreen.matchesSearch(danielaCobro, 'daniela'), isTrue);
      expect(CarteraScreen.matchesSearch(danielaCobro, 'DANIELA'), isTrue);
      expect(CarteraScreen.matchesSearch(danielaCobro, 'Bedoya'), isTrue);
      expect(CarteraScreen.matchesSearch(danielaCobro, 'daniela bedoya'), isTrue);
      expect(CarteraScreen.matchesSearch(camiloCobro, 'camilo'), isTrue);
      expect(CarteraScreen.matchesSearch(camiloCobro, 'Silva'), isTrue);
    });

    test('matches accents / diacritics transparently (simon -> Simón)', () {
      expect(CarteraScreen.matchesSearch(simonCobro, 'simon'), isTrue);
      expect(CarteraScreen.matchesSearch(simonCobro, 'Simón'), isTrue);
      expect(CarteraScreen.matchesSearch(simonCobro, 'SIMON'), isTrue);
    });

    test('matches full formal address in any order: Manzana C Casa 1', () {
      expect(CarteraScreen.matchesSearch(danielaCobro, 'Manzana C Casa 1'), isTrue);
      expect(CarteraScreen.matchesSearch(danielaCobro, 'Casa 1 Manzana C'), isTrue);
    });

    test('matches shorthand aliases: Mz C Casa 1, Mz C 1, Mza C', () {
      expect(CarteraScreen.matchesSearch(danielaCobro, 'Mz C Casa 1'), isTrue);
      expect(CarteraScreen.matchesSearch(danielaCobro, 'mzc 1'), isTrue);
      expect(CarteraScreen.matchesSearch(danielaCobro, 'Mza C 1'), isTrue);
      expect(CarteraScreen.matchesSearch(danielaCobro, 'C 1 Mz C'), isTrue);
    });

    test('matches combination of resident name and billing period', () {
      expect(CarteraScreen.matchesSearch(danielaCobro, 'Daniela septiembre'), isTrue);
      expect(CarteraScreen.matchesSearch(camiloCobro, 'Camilo cuota 2'), isTrue);
      expect(CarteraScreen.matchesSearch(camiloCobro, 'Camilo septiembre'), isTrue);
    });

    test('matches receipt number', () {
      expect(CarteraScreen.matchesSearch(danielaCobro, 'TK-4A9BD6'), isTrue);
      expect(CarteraScreen.matchesSearch(danielaCobro, '4A9BD6'), isTrue);
    });

    test('returns false when tokens do not match', () {
      expect(CarteraScreen.matchesSearch(danielaCobro, 'Manzana A'), isFalse);
      expect(CarteraScreen.matchesSearch(danielaCobro, 'Camilo'), isFalse);
      expect(CarteraScreen.matchesSearch(danielaCobro, 'inexistente999'), isFalse);
    });
  });
}
