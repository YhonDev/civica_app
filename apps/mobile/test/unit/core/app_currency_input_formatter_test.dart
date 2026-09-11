import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civica_pago_mobile/core/format/app_currency.dart';

/// Simula el estado del campo y aplica el formatter como lo haría Flutter.
TextEditingValue _edit(String currentText, String insert, int caret) {
  final oldValue = TextEditingValue(
    text: currentText,
    selection: TextSelection.collapsed(offset: caret),
  );
  final newText = currentText.replaceRange(caret, caret, insert);
  final newValue = TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: caret + insert.length),
  );
  return const AppCurrencyInputFormatter().formatEditUpdate(oldValue, newValue);
}

void main() {
  group('AppCurrencyInputFormatter', () {
    test('agrupa miles con punto', () {
      expect(AppCurrencyInputFormatter.groupThousands('10000'), '10.000');
      expect(AppCurrencyInputFormatter.groupThousands('1000000'), '1.000.000');
      expect(AppCurrencyInputFormatter.groupThousands('500'), '500');
      expect(AppCurrencyInputFormatter.groupThousands('7'), '7');
    });

    test('formatea al escribir desde vacío', () {
      // "1" → "1", luego "0" → "10", ... hasta "10000" → "10.000"
      var value = const TextEditingValue(text: '');
      const formatter = AppCurrencyInputFormatter();
      const seq = ['1', '0', '0', '0', '0'];
      var caret = 0;
      for (final ch in seq) {
        final old = value;
        final newText = value.text.replaceRange(caret, caret, ch);
        value = formatter.formatEditUpdate(
          old,
          TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: caret + 1),
          ),
        );
        caret = value.selection.baseOffset;
      }
      expect(value.text, '10.000');
      expect(value.selection.baseOffset, 6); // después del último dígito
    });

    test('mantiene el cursor al insertar en medio', () {
      // "10.000" con cursor tras "1" (offset 1); insertar "2"
      // → dígitos "120000" → "120.000", cursor justo tras el "2" (offset 2).
      final result = _edit('10.000', '2', 1);
      expect(result.text, '120.000');
      expect(result.selection.baseOffset, 2);
    });

    test('borrado mantiene el cursor estable', () {
      // "10.000" con cursor al final (7); backspace lógico: quitar último char "0"
      final oldValue = const TextEditingValue(
        text: '10.000',
        selection: TextSelection.collapsed(offset: 6),
      );
      final newValue = const TextEditingValue(
        text: '10.00',
        selection: TextSelection.collapsed(offset: 5),
      );
      const formatter = AppCurrencyInputFormatter();
      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '1.000'); // re-agrupa: quedan 4 dígitos "1000"
      expect(result.selection.baseOffset, 5); // cursor tras el dígito 4º
    });

    test('ignora caracteres no numéricos', () {
      final oldValue = const TextEditingValue(text: '');
      final newValue = const TextEditingValue(
        text: 'abc',
        selection: TextSelection.collapsed(offset: 3),
      );
      final result = const AppCurrencyInputFormatter().formatEditUpdate(oldValue, newValue);
      expect(result.text, '');
    });

    test('campo vacío vuelve a vacío', () {
      final oldValue = const TextEditingValue(
        text: '10.000',
        selection: TextSelection.collapsed(offset: 6),
      );
      final newValue = const TextEditingValue(text: '');
      final result = const AppCurrencyInputFormatter().formatEditUpdate(oldValue, newValue);
      expect(result.text, '');
    });

    test('AppCurrency.parse entiende el texto formateado', () {
      expect(AppCurrency.parse('10.000'), 10000);
      expect(AppCurrency.parse('1.000.000'), 1000000);
      expect(AppCurrency.parse('\$ 10.000'), 10000);
    });
  });
}
