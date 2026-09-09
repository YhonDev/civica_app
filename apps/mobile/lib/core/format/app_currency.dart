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
  /// Para inputs de monto: combinar con `FilteringTextInputFormatter.digitsOnly`
  /// y parsear al enviar; no se formatea mientras se escribe.
  static num parse(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9-]'), '');
    return num.tryParse(cleaned) ?? 0;
  }
}
