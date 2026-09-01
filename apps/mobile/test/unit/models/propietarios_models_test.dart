import 'package:flutter_test/flutter_test.dart';

import 'package:civica_pago_mobile/features/propietarios/models/propietarios_models.dart';

void main() {
  group('PropietarioResumen', () {
    test('constructor con todos los campos', () {
      final resumen = const PropietarioResumen(
        totalPropiedades: 100,
        ocupadas: 85,
        vacantes: 15,
      );

      expect(resumen.totalPropiedades, 100);
      expect(resumen.ocupadas, 85);
      expect(resumen.vacantes, 15);
    });

    test('Equatable -> igualdad por valor', () {
      const a = PropietarioResumen(totalPropiedades: 50, ocupadas: 40, vacantes: 10);
      const b = PropietarioResumen(totalPropiedades: 50, ocupadas: 40, vacantes: 10);
      const c = PropietarioResumen(totalPropiedades: 51, ocupadas: 40, vacantes: 10);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('PropietarioItem', () {
    const baseItem = PropietarioItem(
      id: 'P1',
      nombre: 'Juan Pérez',
      telefono: '555-0100',
      casa: 'Casa 14',
      etapa: 'Etapa 1',
      casaId: 'casa-1',
      manzanaId: 'manzana-1',
      etapaId: 'etapa-1',
      email: 'juan@email.com',
      modalidadPago: 'Mensual',
      estadoFinanciero: 'Al Día',
      saldoPendiente: 120000,
    );

    test('constructor asigna campos correctamente', () {
      expect(baseItem.id, 'P1');
      expect(baseItem.nombre, 'Juan Pérez');
      expect(baseItem.telefono, '555-0100');
      expect(baseItem.casa, 'Casa 14');
      expect(baseItem.etapa, 'Etapa 1');
      expect(baseItem.casaId, 'casa-1');
      expect(baseItem.manzanaId, 'manzana-1');
      expect(baseItem.etapaId, 'etapa-1');
      expect(baseItem.email, 'juan@email.com');
      expect(baseItem.modalidadPago, 'Mensual');
      expect(baseItem.estadoFinanciero, 'Al Día');
      expect(baseItem.saldoPendiente, 120000);
    });

    test('email puede ser null', () {
      final item = PropietarioItem(
        id: 'P2',
        nombre: 'Sin Email',
        telefono: '555-0200',
        casa: 'Casa 5',
        etapa: 'Etapa 2',
        modalidadPago: 'Quincenal',
        estadoFinanciero: 'Mora',
        saldoPendiente: 240000,
      );

      expect(item.email, isNull);
      expect(item.casaId, isNull);
      expect(item.manzanaId, isNull);
      expect(item.etapaId, isNull);
    });

    test('Equatable -> igualdad por valor', () {
      const a = baseItem;
      const b = PropietarioItem(
        id: 'P1', nombre: 'Juan Pérez', telefono: '555-0100',
        casa: 'Casa 14', etapa: 'Etapa 1', casaId: 'casa-1', manzanaId: 'manzana-1',
        etapaId: 'etapa-1', email: 'juan@email.com',
        modalidadPago: 'Mensual', estadoFinanciero: 'Al Día', saldoPendiente: 120000,
      );
      const c = PropietarioItem(
        id: 'P2', nombre: 'María', telefono: '555-0300',
        casa: 'Casa 20', etapa: 'Etapa 1',
        modalidadPago: 'Semanal', estadoFinanciero: 'Pendiente', saldoPendiente: 0,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('Equatable -> props incluyen campos nullables', () {
      final a = PropietarioItem(
        id: 'P1', nombre: 'A', telefono: 'T', casa: 'C', etapa: 'E',
        modalidadPago: 'M', estadoFinanciero: 'Al Día', saldoPendiente: 0,
        email: 'a@b.com',
      );
      final b = PropietarioItem(
        id: 'P1', nombre: 'A', telefono: 'T', casa: 'C', etapa: 'E',
        modalidadPago: 'M', estadoFinanciero: 'Al Día', saldoPendiente: 0,
        email: null,
      );

      expect(a, isNot(equals(b)));
    });
  });
}
