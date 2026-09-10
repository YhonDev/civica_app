import 'package:flutter_test/flutter_test.dart';
import 'package:civica_pago_mobile/core/format/app_currency.dart';

void main() {
  group('AppCurrency.format', () {
    test('formato canónico \$ 10.000', () {
      expect(AppCurrency.format(10000), '\$ 10.000');
    });

    test('cero', () {
      expect(AppCurrency.format(0), '\$ 0');
    });

    test('millones con puntos de miles', () {
      expect(AppCurrency.format(1234567), '\$ 1.234.567');
    });

    test('negativos', () {
      expect(AppCurrency.format(-5000), '-\$ 5.000');
    });

    test('dobles se redondean a entero', () {
      expect(AppCurrency.format(10000.49), '\$ 10.000');
      expect(AppCurrency.format(10000.51), '\$ 10.001');
    });
  });

  group('AppCurrency.formatCOP', () {
    test('incluye sufijo COP', () {
      expect(AppCurrency.formatCOP(10000), '\$ 10.000 COP');
    });
  });

  group('AppCurrency.formatOrNull', () {
    test('null usa fallback', () {
      expect(AppCurrency.formatOrNull(null), '\$ 0');
      expect(AppCurrency.formatOrNull(null, fallback: 20000), '\$ 20.000');
    });
  });

  group('AppCurrency.formatCompact', () {
    test('millones', () {
      expect(AppCurrency.formatCompact(1200000), '\$ 1,2 M');
    });

    test('miles', () {
      expect(AppCurrency.formatCompact(850000), '\$ 850 K');
    });

    test('menor a mil usa formato completo', () {
      expect(AppCurrency.formatCompact(500), '\$ 500');
    });
  });

  group('AppCurrency.parse', () {
    test('con símbolo y separadores', () {
      expect(AppCurrency.parse('\$ 10.000'), 10000);
    });

    test('texto plano', () {
      expect(AppCurrency.parse('10000'), 10000);
      expect(AppCurrency.parse('10.000'), 10000);
    });

    test('inválido devuelve 0', () {
      expect(AppCurrency.parse('abc'), 0);
      expect(AppCurrency.parse(''), 0);
    });
  });

  group('AppCurrency.centsToPesos', () {
    test('conversión exacta', () {
      expect(AppCurrency.centsToPesos(100), 1);
      expect(AppCurrency.centsToPesos(150000), 1500);
      expect(AppCurrency.centsToPesos(1000000), 10000);
    });

    test('cero y negativos', () {
      expect(AppCurrency.centsToPesos(0), 0);
      expect(AppCurrency.centsToPesos(-50000), -500);
    });

    test('regresión: NO aplica la heurística "si > 1000 entonces /100"', () {
      // Un monto de 1.500 centavos (15 pesos) y uno de 150.000 centavos
      // (1.500 pesos) se convierten por la misma regla, sin umbrales.
      expect(AppCurrency.centsToPesos(1500), 15);
      expect(AppCurrency.centsToPesos(150000), 1500);
    });
  });

  group('AppCurrency.pesosToCents', () {
    test('conversión exacta', () {
      expect(AppCurrency.pesosToCents(10000), 1000000);
      expect(AppCurrency.pesosToCents(0), 0);
      expect(AppCurrency.pesosToCents(-500), -50000);
    });

    test('ida y vuelta', () {
      // 123456 centavos → 1234,56 pesos → redondea a 1235 → 123500 centavos.
      expect(AppCurrency.pesosToCents(AppCurrency.centsToPesos(123456)), 123500);
    });
  });

  group('AppCurrency.centsFromJson', () {
    test('int', () {
      expect(AppCurrency.centsFromJson(150000), 1500);
    });

    test('double', () {
      expect(AppCurrency.centsFromJson(150000.0), 1500);
    });

    test('string numérica', () {
      expect(AppCurrency.centsFromJson('150000'), 1500);
    });

    test('null o inválido devuelven 0', () {
      expect(AppCurrency.centsFromJson(null), 0);
      expect(AppCurrency.centsFromJson('abc'), 0);
    });
  });

  group('AppCurrency.formatCents', () {
    test('centavos → formato canónico en un paso', () {
      expect(AppCurrency.formatCents(1000000), '\$ 10.000');
      expect(AppCurrency.formatCents(0), '\$ 0');
    });
  });
}
