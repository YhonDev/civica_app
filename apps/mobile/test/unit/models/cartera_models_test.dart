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
      residenteId: 'P-1',
      nombre: 'Juan Pérez',
      casa: 'Casa 14',
      manzana: 'Manzana A',
      etapa: 'Etapa 1',
      monto: 120000,
      montoPagado: 0,
      saldo: 120000,
      estado: 'Pendiente',
      modalidad: 'Mensual',
    );

    test('constructor asigna campos', () {
      expect(baseItem.id, 'C-1');
      expect(baseItem.residenteId, 'P-1');
      expect(baseItem.nombre, 'Juan Pérez');
      expect(baseItem.casa, 'Casa 14');
      expect(baseItem.etapa, 'Etapa 1');
      expect(baseItem.monto, 120000);
      expect(baseItem.montoPagado, 0);
      expect(baseItem.saldo, 120000);
      expect(baseItem.estado, 'Pendiente');
      expect(baseItem.modalidad, 'Mensual');
    });

    test('todos los estados posibles', () {
      const pendiente = baseItem;
      const mora = CobroItem(
        id: 'M-1', residenteId: 'P-2', nombre: 'En Mora',
        casa: 'Casa 5', manzana: 'Manzana B', etapa: 'Etapa 1',
        monto: 360000, montoPagado: 0, saldo: 360000,
        estado: 'Mora', modalidad: 'Mensual',
      );
      const pagado = CobroItem(
        id: 'PG-1', residenteId: 'P-3', nombre: 'Pagado',
        casa: 'Casa 10', manzana: 'Manzana B', etapa: 'Etapa 2',
        monto: 120000, montoPagado: 120000, saldo: 0,
        estado: 'Pagado', modalidad: 'Semanal',
      );

      expect(pendiente.estado, 'Pendiente');
      expect(mora.estado, 'Mora');
      expect(pagado.estado, 'Pagado');
    });

    test('saldo puede ser 0 (pagado)', () {
      const pagado = CobroItem(
        id: 'PG-2', residenteId: 'P-4', nombre: 'Pagado',
        casa: 'Casa 20', manzana: 'Manzana C', etapa: 'Etapa 1',
        monto: 100000, montoPagado: 100000, saldo: 0,
        estado: 'Pagado', modalidad: 'Quincenal',
      );

      expect(pagado.saldo, 0);
    });

    test('residenteId puede ser string vacío', () {
      final item = CobroItem(
        id: 'C-2',
        residenteId: '',
        nombre: 'Sin Propietario',
        casa: 'Casa 99',
        manzana: 'Manzana A',
        etapa: 'Etapa 3',
        monto: 50000,
        montoPagado: 0,
        saldo: 50000,
        estado: 'Pendiente',
        modalidad: 'Mensual',
      );

      expect(item.residenteId, isEmpty);
    });

    test('Equatable -> igualdad por valor', () {
      const a = baseItem;
      const b = CobroItem(
        id: 'C-1', residenteId: 'P-1', nombre: 'Juan Pérez',
        casa: 'Casa 14', manzana: 'Manzana A', etapa: 'Etapa 1',
        monto: 120000, montoPagado: 0, saldo: 120000,
        estado: 'Pendiente', modalidad: 'Mensual',
      );
      const c = CobroItem(
        id: 'C-2', residenteId: 'P-2', nombre: 'Otro',
        casa: 'Casa 5', manzana: 'Manzana B', etapa: 'Etapa 1',
        monto: 100000, montoPagado: 100000, saldo: 0,
        estado: 'Pagado', modalidad: 'Mensual',
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('mesNombre extrae el mes correctamente', () {
      const itemConPeriodo = CobroItem(
        id: 'C-3',
        residenteId: 'P-1',
        nombre: 'Juan Pérez',
        casa: 'Casa 14',
        manzana: 'Manzana A',
        etapa: 'Etapa 1',
        periodoInicio: '2026-09-01T00:00:00.000Z',
        monto: 120000,
        montoPagado: 0,
        saldo: 120000,
        estado: 'Pendiente',
        modalidad: 'Mensual',
      );
      expect(itemConPeriodo.mesNombre, 'Septiembre');
    });

    test('cuotaNombre extrae cuota sin redundancia', () {
      const itemCuotaRegex = CobroItem(
        id: 'C-4',
        residenteId: 'P-1',
        nombre: 'Juan Pérez',
        casa: 'Casa 14',
        manzana: 'Manzana A',
        etapa: 'Etapa 1',
        concepto: 'Septiembre — Cuota 3',
        monto: 120000,
        montoPagado: 0,
        saldo: 120000,
        estado: 'Pendiente',
        modalidad: 'Mensual',
      );
      expect(itemCuotaRegex.cuotaNombre, 'Cuota 3');

      const itemConceptoCustom = CobroItem(
        id: 'C-5',
        residenteId: 'P-1',
        nombre: 'Juan Pérez',
        casa: 'Casa 14',
        manzana: 'Manzana A',
        etapa: 'Etapa 1',
        concepto: 'Arreglo de Puerta',
        monto: 50000,
        montoPagado: 0,
        saldo: 50000,
        estado: 'Pendiente',
        modalidad: 'Mensual',
      );
      expect(itemConceptoCustom.cuotaNombre, 'Arreglo de Puerta');
    });

    test('ubicacionNombre formatea manzana y casa sin redundancia', () {
      const itemUbicacion = CobroItem(
        id: 'C-6',
        residenteId: 'P-1',
        nombre: 'Juan Pérez',
        manzana: 'B',
        casa: '4',
        etapa: '',
        monto: 120000,
        montoPagado: 0,
        saldo: 120000,
        estado: 'Pendiente',
        modalidad: 'Mensual',
      );
      expect(itemUbicacion.ubicacionNombre, 'Manzana B · Casa 4');
    });

    test('tituloCuota combina mes y cuota limpiamente', () {
      const itemTitulo = CobroItem(
        id: 'C-7',
        residenteId: 'P-1',
        nombre: 'Juan Pérez',
        periodoInicio: '2026-09-01T00:00:00.000Z',
        concepto: 'Cuota 1',
        casa: 'Casa 4',
        manzana: 'Manzana A',
        etapa: 'Etapa 1',
        monto: 120000,
        montoPagado: 0,
        saldo: 120000,
        estado: 'Pendiente',
        modalidad: 'Mensual',
      );
      expect(itemTitulo.tituloCuota, 'Septiembre — Cuota 1');
    });
  });
}
