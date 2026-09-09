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
}
