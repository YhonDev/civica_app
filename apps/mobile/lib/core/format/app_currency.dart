import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Única fuente de verdad para el formato de dinero en toda la app.
///
/// Formato canónico: `$ 10.000` — símbolo `$` seguido de espacio,
/// separador de miles con punto y sin decimales (COP).
///
/// Cambiar el formato aquí lo aplica automáticamente a TODA la app
/// (admin, cobrador y residente). Nunca crees un `NumberFormat` inline:
/// usa siempre [AppCurrency].
abstract final class AppCurrency {
  static final NumberFormat _number = NumberFormat('#,##0', 'es_CO');

  /// `$ 10.000` (negativos: `-$ 5.000`)
  static String format(num amount) {
    final formatted = _number.format(amount.abs());
    return amount < 0 ? '-\$ $formatted' : '\$ $formatted';
  }

  /// `$ 10.000 COP` — para textos donde se explicita la moneda.
  static String formatCOP(num amount) => '\$ ${_number.format(amount)} COP';

  /// Tolera nulos de la API: `formatOrNull(null)` → `$ 0`.
  static String formatOrNull(num? amount, {int fallback = 0}) =>
      format(amount ?? fallback);

  /// `$ 1,2 M` / `$ 850 K` — para charts y tooltips con poco espacio.
  static String formatCompact(num amount) {
    final value = amount.abs();
    if (value >= 1000000) {
      return '\$ ${_decimalComma(_trimTrailingZero((amount / 1000000).toStringAsFixed(1)))} M';
    }
    if (value >= 1000) {
      return '\$ ${(amount / 1000).toStringAsFixed(0)} K';
    }
    return format(amount);
  }

  static String _trimTrailingZero(String s) =>
      s.endsWith('.0') ? s.substring(0, s.length - 2) : s;

  /// Convención decimal es: coma en vez de punto (`1.2` → `1,2`).
  static String _decimalComma(String s) => s.replaceFirst('.', ',');

  /// Convierte texto como `'$ 10.000'`, `'10.000'` o `'10000'` a [num].
  ///
  /// Complemento de [AppCurrencyInputFormatter]: parsea lo que el usuario
  /// ve en el campo (con separadores) al enviar.
  static num parse(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9-]'), '');
    return num.tryParse(cleaned) ?? 0;
  }

  /// `10.000` — dígitos agrupados para el input de monto (sin símbolo;
  /// el `$ ` lo aporta el `prefixText` del campo).
  static String formatInput(int amount) => _number.format(amount);

  // ── Conversión de unidades ──────────────────────────────────────────────────

  /// Convierte cantidades en centavos (entero) a pesos (entero).
  ///
  /// El backend y el motor de recaudo trabajan en centavos (1 peso = 100
  /// centavos). Esta función es la única forma de convertir centavos → pesos:
  /// evita la heurística `'si > 1000 entonces /100'` que corría mal en
  /// cualquier monto ya expresado en pesos (p. ej. 1.500 pesos en centavos
  /// → se partiría a 15, en pesos → se mostraría mal).
  static int centsToPesos(int cents) => (cents / 100).round();

  /// Convierte pesos (entero) a centavos (entero).
  static int pesosToCents(int pesos) => pesos * 100;

  /// Parsea un código JSON numérico de centavos a pesos.
  ///
  /// Equivalente seguro a `((json['monto'] as int) / 100).round()`:
  /// la función documenta la convención de unidades y aisla el round.
  static int centsFromJson(dynamic value) =>
      centsToPesos((value is num ? value.toDouble() : double.tryParse(value.toString()) ?? 0).round());

  /// Convierte centavos → pesos en formato `$ 10.000` en un paso.
  static String formatCents(int cents) => format(centsToPesos(cents));
}

/// Formatea el monto mientras se escribe: `10000` → `10.000`.
///
/// Mantiene el cursor después del último dígito editado y elimina todo
/// carácter no numérico. Usar junto a [AppCurrency.parse] al enviar.
class AppCurrencyInputFormatter extends TextInputFormatter {
  static final RegExp _digit = RegExp(r'[0-9]');

  /// Instanciable como const: la clase es stateless (el RegExp es estático).
  const AppCurrencyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');

    final digitsBeforeCursor = _countDigitsBefore(newValue);
    final formatted = groupThousands(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: _cursorAfter(formatted, digitsBeforeCursor),
      ),
    );
  }

  /// Agrupa de a 3 dígitos desde la derecha con punto: `1000000` → `1.000.000`.
  ///
  /// Expuesto solo para tests (`@visibleForTesting`); el código de producción
  /// usa el formatter vía [formatEditUpdate] o [AppCurrency.formatInput].
  @visibleForTesting
  static String groupThousands(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      final remaining = digits.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
    }
    return buffer.toString();
  }

  static int _countDigitsBefore(TextEditingValue value) {
    final limit = value.selection.baseOffset.clamp(0, value.text.length);
    var count = 0;
    for (var i = 0; i < limit; i++) {
      if (_digit.hasMatch(value.text[i])) count++;
    }
    return count;
  }

  static int _cursorAfter(String formatted, int digitsBefore) {
    if (digitsBefore <= 0) return 0;
    var count = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (_digit.hasMatch(formatted[i])) {
        count++;
        if (count == digitsBefore) return i + 1;
      }
    }
    return formatted.length;
  }
}
