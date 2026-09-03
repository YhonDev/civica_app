import 'package:flutter_test/flutter_test.dart';

import 'package:civica_pago_mobile/features/residentes/models/cobradores_models.dart';

void main() {
  group('CobradorResumen', () {
    test('constructor asigna campos', () {
      const resumen = CobradorResumen(
        totalCobradores: 10,
        activos: 8,
        inactivos: 2,
      );

      expect(resumen.totalCobradores, 10);
      expect(resumen.activos, 8);
      expect(resumen.inactivos, 2);
    });

    test('Equatable', () {
      const a = CobradorResumen(totalCobradores: 5, activos: 4, inactivos: 1);
      const b = CobradorResumen(totalCobradores: 5, activos: 4, inactivos: 1);
      const c = CobradorResumen(totalCobradores: 6, activos: 4, inactivos: 2);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('CobradorItem', () {
    const baseItem = CobradorItem(
      id: 'C1',
      nombre: 'Carlos Cobrador',
      telefono: '555-1000',
      correo: 'carlos@cobradores.com',
      zonas: ['Etapa 1', 'Etapa 2'],
      activo: true,
      pagosRegistradosSemana: 15,
    );

    test('constructor asigna campos correctamente', () {
      expect(baseItem.id, 'C1');
      expect(baseItem.nombre, 'Carlos Cobrador');
      expect(baseItem.telefono, '555-1000');
      expect(baseItem.correo, 'carlos@cobradores.com');
      expect(baseItem.zonas, ['Etapa 1', 'Etapa 2']);
      expect(baseItem.activo, isTrue);
      expect(baseItem.pagosRegistradosSemana, 15);
    });

    test('zonas puede ser lista vacía', () {
      final item = CobradorItem(
        id: 'C2',
        nombre: 'Nuevo',
        telefono: '555-2000',
        correo: 'nuevo@test.com',
        zonas: [],
        activo: false,
        pagosRegistradosSemana: 0,
      );

      expect(item.zonas, isEmpty);
      expect(item.activo, isFalse);
      expect(item.pagosRegistradosSemana, 0);
    });

    test('Equatable -> igualdad por valor', () {
      const a = baseItem;
      const b = CobradorItem(
        id: 'C1', nombre: 'Carlos Cobrador', telefono: '555-1000',
        correo: 'carlos@cobradores.com', zonas: ['Etapa 1', 'Etapa 2'],
        activo: true, pagosRegistradosSemana: 15,
      );
      const c = CobradorItem(
        id: 'C2', nombre: 'Otro', telefono: '555-3000',
        correo: 'otro@test.com', zonas: [],
        activo: false, pagosRegistradosSemana: 0,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('Equatable -> zonas diferente no es igual', () {
      const a = CobradorItem(
        id: 'C1', nombre: 'A', telefono: 'T', correo: 'e@e.com',
        zonas: ['Z1'], activo: true, pagosRegistradosSemana: 5,
      );
      const b = CobradorItem(
        id: 'C1', nombre: 'A', telefono: 'T', correo: 'e@e.com',
        zonas: ['Z2'], activo: true, pagosRegistradosSemana: 5,
      );

      expect(a, isNot(equals(b)));
    });
  });
}
