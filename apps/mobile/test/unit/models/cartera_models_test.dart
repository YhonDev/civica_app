import 'package:flutter_test/flutter_test.dart';

import 'package:civica_pago_mobile/features/cartera/models/cartera_models.dart';

void main() {
  group('CarteraResumen', () {
    const resumen = CarteraResumen(
      totalPendiente: 2040000,
      totalMora: 720000,
      totalPagado: 7800000,
      cantidadPendientes: 17,
      cantidadMora: 6,
      cantidadPagados: 65,
    );

    test('constructor asigna campos', () {
      expect(resumen.totalPendiente, 2040000);
      expect(resumen.totalMora, 720000);
      expect(resumen.totalPagado, 7800000);
      expect(resumen.cantidadPendientes, 17);
      expect(resumen.cantidadMora, 6);
      expect(resumen.cantidadPagados, 65);
    });

    test('valores pueden ser 0', () {
      const vacio = CarteraResumen(
        totalPendiente: 0, totalMora: 0, totalPagado: 0,
        cantidadPendientes: 0, cantidadMora: 0, cantidadPagados: 0,
      );

      expect(vacio.totalPendiente, 0);
      expect(vacio.cantidadMora, 0);
    });

    test('Equatable -> igualdad por valor', () {
      const a = resumen;
      const b = CarteraResumen(
        totalPendiente: 2040000, totalMora: 720000, totalPagado: 7800000,
        cantidadPendientes: 17, cantidadMora: 6, cantidadPagados: 65,
      );
      const c = CarteraResumen(
        totalPendiente: 0, totalMora: 0, totalPagado: 0,
        cantidadPendientes: 0, cantidadMora: 0, cantidadPagados: 0,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('CobroItem', () {
    const baseItem = CobroItem(
      id: 'C-1',
      propietarioId: 'P-1',
      nombre: 'Juan Pérez',
      casa: 'Casa 14',
      etapa: 'Etapa 1',
      saldo: 120000,
      estado: 'Pendiente',
      modalidad: 'Mensual',
    );

    test('constructor asigna campos', () {
      expect(baseItem.id, 'C-1');
      expect(baseItem.propietarioId, 'P-1');
      expect(baseItem.nombre, 'Juan Pérez');
      expect(baseItem.casa, 'Casa 14');
      expect(baseItem.etapa, 'Etapa 1');
      expect(baseItem.saldo, 120000);
      expect(baseItem.estado, 'Pendiente');
      expect(baseItem.modalidad, 'Mensual');
    });

    test('todos los estados posibles', () {
      const pendiente = baseItem;
      const mora = CobroItem(
        id: 'M-1', propietarioId: 'P-2', nombre: 'En Mora',
        casa: 'Casa 5', etapa: 'Etapa 1', saldo: 360000,
        estado: 'Mora', modalidad: 'Mensual',
      );
      const pagado = CobroItem(
        id: 'PG-1', propietarioId: 'P-3', nombre: 'Pagado',
        casa: 'Casa 10', etapa: 'Etapa 2', saldo: 0,
        estado: 'Pagado', modalidad: 'Semanal',
      );

      expect(pendiente.estado, 'Pendiente');
      expect(mora.estado, 'Mora');
      expect(pagado.estado, 'Pagado');
    });

    test('saldo puede ser 0 (pagado)', () {
      const pagado = CobroItem(
        id: 'PG-2', propietarioId: 'P-4', nombre: 'Pagado',
        casa: 'Casa 20', etapa: 'Etapa 1', saldo: 0,
        estado: 'Pagado', modalidad: 'Quincenal',
      );

      expect(pagado.saldo, 0);
    });

    test('propietarioId puede ser string vacío', () {
      final item = CobroItem(
        id: 'C-2',
        propietarioId: '',
        nombre: 'Sin Propietario',
        casa: 'Casa 99',
        etapa: 'Etapa 3',
        saldo: 50000,
        estado: 'Pendiente',
        modalidad: 'Mensual',
      );

      expect(item.propietarioId, isEmpty);
    });

    test('Equatable -> igualdad por valor', () {
      const a = baseItem;
      const b = CobroItem(
        id: 'C-1', propietarioId: 'P-1', nombre: 'Juan Pérez',
        casa: 'Casa 14', etapa: 'Etapa 1', saldo: 120000,
        estado: 'Pendiente', modalidad: 'Mensual',
      );
      const c = CobroItem(
        id: 'C-2', propietarioId: 'P-2', nombre: 'Otro',
        casa: 'Casa 5', etapa: 'Etapa 1', saldo: 0,
        estado: 'Pagado', modalidad: 'Mensual',
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
