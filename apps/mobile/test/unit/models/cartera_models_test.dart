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

    test('fromCobros computes dynamic totals and counts correctly', () {
      final cobros = [
        const CobroItem(
          id: '1', residenteId: 'R1', nombre: 'Ana', casa: 'C1',
          manzana: 'A', etapa: '1', monto: 50000, montoPagado: 0,
          saldo: 50000, estado: 'Pendiente', modalidad: 'Mensual',
        ),
        const CobroItem(
          id: '2', residenteId: 'R2', nombre: 'Carlos', casa: 'C2',
          manzana: 'A', etapa: '1', monto: 60000, montoPagado: 0,
          saldo: 60000, estado: 'Mora', modalidad: 'Mensual',
        ),
        const CobroItem(
          id: '3', residenteId: 'R3', nombre: 'Diana', casa: 'C3',
          manzana: 'A', etapa: '1', monto: 70000, montoPagado: 70000,
          saldo: 0, estado: 'Pagado', modalidad: 'Mensual',
        ),
        const CobroItem(
          id: '4', residenteId: 'R4', nombre: 'Elena', casa: 'C4',
          manzana: 'A', etapa: '1', monto: 80000, montoPagado: 20000,
          saldo: 60000, estado: 'Abonado', modalidad: 'Mensual',
        ),
      ];

      final dynamicResumen = CarteraResumen.fromCobros(cobros);

      // Pendiente: 50000 (Pendiente) + 60000 (Abonado) = 110000
      expect(dynamicResumen.totalPendiente, 110000);
      expect(dynamicResumen.cantidadPendientes, 2); // 'Pendiente' + 'Abonado'
      // Mora: 60000
      expect(dynamicResumen.totalMora, 60000);
      expect(dynamicResumen.cantidadMora, 1);
      // Pagado: 70000 (Pagado) + 20000 (Abonado paid part)
      expect(dynamicResumen.totalPagado, 90000);
      expect(dynamicResumen.cantidadPagados, 1);
    });

    test('fromCobros with empty list returns zeroes', () {
      final dynamicResumen = CarteraResumen.fromCobros(const []);
      expect(dynamicResumen.totalPendiente, 0);
      expect(dynamicResumen.totalMora, 0);
      expect(dynamicResumen.totalPagado, 0);
      expect(dynamicResumen.cantidadPendientes, 0);
      expect(dynamicResumen.cantidadMora, 0);
      expect(dynamicResumen.cantidadPagados, 0);
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

    test('comparePorVisitaYCobro ordena por fecha, manzana A-Z, casa numérico y cuota', () {
      const cobro1 = CobroItem(
        id: '1',
        residenteId: 'R-1',
        nombre: 'Carmen',
        casa: 'Casa 1',
        manzana: 'Manzana B',
        etapa: 'Etapa 1',
        fechaVencimiento: '2026-09-12T00:00:00.000Z',
        concepto: 'Septiembre — Cuota 1',
        monto: 100000,
        montoPagado: 0,
        saldo: 100000,
        estado: 'Pendiente',
        modalidad: 'Mensual',
      );

      const cobro2 = CobroItem(
        id: '2',
        residenteId: 'R-2',
        nombre: 'Camilo',
        casa: 'Casa 1',
        manzana: 'Manzana A',
        etapa: 'Etapa 1',
        fechaVencimiento: '2026-09-12T00:00:00.000Z',
        concepto: 'Septiembre — Cuota 2',
        monto: 100000,
        montoPagado: 0,
        saldo: 100000,
        estado: 'Pendiente',
        modalidad: 'Mensual',
      );

      const cobro3 = CobroItem(
        id: '3',
        residenteId: 'R-2',
        nombre: 'Camilo',
        casa: 'Casa 1',
        manzana: 'Manzana A',
        etapa: 'Etapa 1',
        fechaVencimiento: '2026-09-19T00:00:00.000Z',
        concepto: 'Septiembre — Cuota 3',
        monto: 100000,
        montoPagado: 0,
        saldo: 100000,
        estado: 'Pendiente',
        modalidad: 'Mensual',
      );

      const cobro4 = CobroItem(
        id: '4',
        residenteId: 'R-3',
        nombre: 'David',
        casa: 'Casa 10',
        manzana: 'Manzana A',
        etapa: 'Etapa 1',
        fechaVencimiento: '2026-09-12T00:00:00.000Z',
        concepto: 'Septiembre — Cuota 1',
        monto: 100000,
        montoPagado: 0,
        saldo: 100000,
        estado: 'Pendiente',
        modalidad: 'Mensual',
      );

      final list = [cobro1, cobro3, cobro4, cobro2]
        ..sort(CobroItem.comparePorVisitaYCobro);

      // Fecha 12, MzA, Casa 1
      expect(list[0].id, '2');
      // Fecha 12, MzA, Casa 10
      expect(list[1].id, '4');
      // Fecha 12, MzB, Casa 1
      expect(list[2].id, '1');
      // Fecha 19, MzA, Casa 1
      expect(list[3].id, '3');
    });
  });
}
