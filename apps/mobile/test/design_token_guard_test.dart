/// Guardian del sistema de diseño: verifica que ningún archivo fuera de los
/// archivos de tokens vuelva a introducir los patrones prohibidos.
///
/// Detecta ocho tipos de regesión (reglas de guardian de doc/DESIGN_SYSTEM.md):
///
/// 1. `fontSize:` inline fuera de `lib/core/theme/` (tipografía).
/// 2. `NumberFormat` fuera de `lib/core/format/` (la única fuente de verdad
///    del formato de dinero).
/// 3. `Color(0x…)` (hex hardcodeado) fuera de `lib/core/theme/` (color).
/// 4. `BorderRadius.circular(<literal>)` / `Radius.circular(<literal>)`
///    fuera de `lib/core/theme/` (radios — usa tokens de `AppSpacing`).
/// 5. `EdgeInsets` totalmente tokenizado (todos sus literales ∈ {4, 8, 16,
///    20, 24, 32}) escrito con números en vez de tokens `AppSpacing`.
///    (EdgeInsets con offsets posicionales NO tokenizados sigue permitido.)
/// 6. `BorderRadius` construido con `lerp`/aritmética sobre literales queda
///    cubierto por la regla 4 vía el escaneo línea a línea.
/// 7. Interpolación cruda de errores (`$e`) en superficies de UI (SnackBar,
///    TopToast) sin pasar por `sanitizeApiError` — regla 9.7.
/// 8. `debugPrint` con error crudo (`$e`) sin gate `kDebugMode` en la misma
///    línea o en la línea anterior — regla 9.7 (los logs en release
///    no deben construirse interpolando errores).
/// 9. `SnackBar`/`ScaffoldMessenger` fuera de `lib/core/widgets/top_toast.dart`
///    — regla 9.8: el estándar único de notificaciones es `TopToast`.
///
/// Ejecutar con: `flutter test test/design_token_guard_test.dart`
/// (incluido en `flutter test` y en CI). Diseñado para fallar cerrado:
/// cualquier archivo nuevo que rompa una regla aparece con ruta, línea y
/// columna y el texto de la regla infringida.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Archivos fuente de tokens. Un patrón solo es legal en SU archivo.
const Map<String, String> kTokenSourceFiles = {
  'lib/core/theme/app_typography.dart': 'tokens de tipografía',
  'lib/core/format/app_currency.dart': 'tokens de moneda (AppCurrency)',
  'lib/core/theme/app_colors.dart': 'tokens de color',
  'lib/core/theme/app_spacing.dart': 'tokens de espaciado y radios',
};

/// Prefijos de ruta exentos: son ellos mismos el sistema de diseño.
const List<String> kTokenSourcePrefixes = [
  'lib/core/theme/',
  'lib/core/format/',
];

/// Valores de gap/padding que ya tienen token en `AppSpacing`; un
/// EdgeInsets compuesto solo de estos valores debe usar los tokens.
const Set<String> kTokenizedSpacingValues = {'4', '8', '16', '20', '24', '32'};

/// (patrón, prefijo de archivo permitido, regla de guardian infringida)
final List<(RegExp, String, String)> kForbiddenPatterns = [
  (
    RegExp(r'\bfontSize\s*:'),
    'lib/core/theme/',
    'Regla 9.3 — nunca `fontSize:` inline; usa tokens de `AppTypography`',
  ),
  (
    RegExp(r'\bNumberFormat\b'),
    'lib/core/format/',
    'Regla 9.2 — nunca `NumberFormat` inline; usa `AppCurrency`',
  ),
  (
    RegExp(r'\bColor\s*\(\s*0x[0-9a-fA-F]{8}\s*\)'),
    'lib/core/theme/',
    'Regla 9.4 — nunca hex hardcodeado; usa un token de `AppColors`',
  ),
  (
    RegExp(r'\bBorderRadius\.circular\s*\(\s*[0-9.]'),
    'lib/core/theme/',
    'Regla 9.5 — radios con literal; usa tokens de `AppSpacing` '
        '(cardRadius, buttonRadius, radiusSm…)',
  ),
  (
    RegExp(r'\bRadius\.circular\s*\(\s*[0-9.]'),
    'lib/core/theme/',
    'Regla 9.5 — radios con literal; usa tokens de `AppSpacing` '
        '(cardRadius, buttonRadius, radiusSm…)',
  ),
];

final RegExp _edgeInsetsExpr =
    RegExp(r'EdgeInsets\.(all|symmetric|only|fromLTRB)\(([^()]*)\)');

/// Objeto de error crudo interpolado SIN llaves: `$e`, `$err`, `$error`…
/// Con frontera de palabra: `$extra` NO cuenta. OJO con Dart:
/// `'$err.message'` interpola el OBJETO `err` (el `.message` es texto
/// literal), así que una `.` tras el identificador sigue siendo fuga cruda.
final RegExp _bareRawError =
    RegExp(r'\$(?:e|err|error|ex|exception|failure)\b');

/// Interpolación con llaves que es EXACTAMENTE el objeto de error:
/// `${e}` / `${error}` — el toString crudo completo.
final RegExp _bracedRawErrorExact =
    RegExp(r'\$\{\s*(?:e|err|error|ex|exception|failure)\s*\}');

/// Interpolación con llaves enraizada en el objeto de error, incluido el
/// acceso a campos: `${e}` y también `${e.message}`. Para UI son bypass del
/// sanitizador por igual; para logs, el acceso a campos acotado es legítimo.
final RegExp _bracedRawErrorRoot =
    RegExp(r'\$\{\s*(?:e|err|error|ex|exception|failure)\b');

/// Marcadores de superficie de usuario donde un error crudo se mostraría.
final RegExp _uiErrorMarker =
    RegExp(r'\b(SnackBar|showSnackBar|TopToast|Toast)\b');

/// El harness de depuración (`lib/debug/`) no corre en release.
bool _isDebugHarness(String posixPath) => posixPath.startsWith('lib/debug/');

/// Regla 9.7 (UI): un SnackBar/toast nunca interpola el error crudo; pasa
/// por `sanitizeApiError`. Las líneas que ya lo usan están exentas.
List<String> uiRawErrorViolations(String code, String posixPath, int lineNo) {
  if (_isDebugHarness(posixPath)) return [];
  if (code.contains('sanitizeApiError')) return [];
  if (code.contains('debugPrint(')) return []; // dominio de la regla de logging
  if (!_uiErrorMarker.hasMatch(code)) return [];
  final bare = _bareRawError.firstMatch(code);
  final braced = _bracedRawErrorRoot.firstMatch(code);
  final hit = _earliest(bare, braced);
  if (hit == null) return [];
  return [
    '$posixPath:$lineNo:${hit.start + 1}: '
        'Regla 9.7 — un SnackBar/toast nunca muestra el error crudo (`\$e` '
        'ni `\${e.message}`); usa `sanitizeApiError(e)` '
        '(core/network/error_messages.dart)',
  ];
}

/// Regla 9.7 (logging): `debugPrint` con error crudo solo si está gated por
/// `kDebugMode` — en la misma línea (`if (kDebugMode) debugPrint(…)`) o en
/// la línea de código anterior (`if (kDebugMode) {`). Límite documentado:
/// un gate por rama `else` (o condicional multilínea) no es detectable línea
/// a línea; en ese caso usa el gate en la misma línea.
List<String> debugPrintRawErrorViolations(
  String code,
  String previousCodeLine,
  String posixPath,
  int lineNo,
) {
  if (_isDebugHarness(posixPath)) return [];
  if (!code.contains('debugPrint(')) return [];
  // El objeto CRUDO es la fuga (`$e` —y ojo: `$err.message` sin llaves
  // también interpola el objeto—, o `${e}` exacto). El acceso a campos
  // acotado (`${e.code}`, `${e.message}`) es divulgación deliberada y
  // legítima en un log.
  final bare = _bareRawError.firstMatch(code);
  final braced = _bracedRawErrorExact.firstMatch(code);
  final hit = _earliest(bare, braced);
  if (hit == null) return [];
  if (code.contains('kDebugMode')) return []; // gate en la misma línea
  if (previousCodeLine.contains('kDebugMode')) return []; // gate de bloque
  return [
    '$posixPath:$lineNo:${hit.start + 1}: '
        'Regla 9.7 — debugPrint con el objeto de error crudo (`\$e`) debe '
        'estar gated por `kDebugMode` (misma línea o `if (kDebugMode) {` '
        'arriba); en release el log no debe construirse',
  ];
}

Match? _earliest(RegExpMatch? a, RegExpMatch? b) {
  if (a == null) return b;
  if (b == null) return a;
  return a.start <= b.start ? a : b;
}

/// Devuelve las violaciones de la regla EdgeInsets tokenizada para una
/// línea de código. Un EdgeInsets se considera "tokenizable" cuando TODOS
/// sus literales numéricos pertenecen a [kTokenizedSpacingValues].
List<String> edgeInsetsViolations(String code, String posixPath, int lineNo) {
  final violations = <String>[];
  for (final match in _edgeInsetsExpr.allMatches(code)) {
    final args = match.group(2)!;
    final numbers = RegExp(r'[0-9.]+').allMatches(args).toList();
    if (numbers.isEmpty) continue; // EdgeInsets.zero / sin literales
    final allTokenized = numbers.every((n) => kTokenizedSpacingValues.contains(n.group(0)));
    if (!allTokenized) continue; // offsets posicionales: permitidos
    violations.add(
      '$posixPath:$lineNo:${match.start + 1}: Regla 9.5 — EdgeInsets con '
      'valores tokenizados escrito con literales; usa AppSpacing '
      '(xs/sm/md/screenPadding/lg/xl)',
    );
  }
  return violations;
}

/// Regla 9.8 (notificaciones): el único estándar de notificación es
/// `TopToast`. `SnackBar`/`ScaffoldMessenger` solo pueden existir dentro
/// del propio componente (`lib/core/widgets/top_toast.dart`).
List<String> snackBarViolations(String code, String posixPath, int lineNo) {
  if (posixPath == 'lib/core/widgets/top_toast.dart') return [];
  final pattern = RegExp(r'\b(SnackBar|ScaffoldMessenger|showSnackBar)\b');
  final hit = pattern.firstMatch(code);
  if (hit == null) return [];
  return [
    '$posixPath:$lineNo:${hit.start + 1}: '
        'Regla 9.8 — notificaciones solo con `TopToast` '
        '(core/widgets/top_toast.dart); `SnackBar`/`ScaffoldMessenger` '
        'están prohibidos fuera del propio componente',
  ];
}

/// Regla 9.9 (sanitización de errores): `TopToast.showError` recibe el
/// OBJETO de error y sanitiza internamente. Componer en el call site
/// (`showError(ctx, 'X: ${sanitizeApiError(e)}')`) queda prohibido: es el
/// punto de re-fuga — basta un `'$e'` en vez de `sanitizeApiError(e)`.
List<String> showErrorViolations(String code, String posixPath, int lineNo) {
  if (posixPath == 'lib/core/widgets/top_toast.dart') return [];
  if (!code.contains('showError(')) return [];
  if (!code.contains('sanitizeApiError')) return [];
  final hit = RegExp(r'\bshowError\s*\(').firstMatch(code);
  return [
    '$posixPath:$lineNo:${hit!.start + 1}: '
        'Regla 9.9 — `showError` recibe el objeto de error directamente: '
        '`showError(context, e, prefix: \'X\')`; la sanitización interna '
        'hace imposible el bypass — no componer con `sanitizeApiError` '
        'en el call site',
  ];
}

void main() {
  test('guardián de tokens: sin regesión de tipografía/moneda/color/radios/espaciado', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue,
        reason: 'ejecutar desde apps/mobile (flutter test)');

    final violations = <String>[];
    final dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    bool isTokenSource(String posixPath) =>
        kTokenSourcePrefixes.any(posixPath.startsWith);

    for (final file in dartFiles) {
      final posixPath = file.path.replaceAll('\\', '/');
      final lines = file.readAsLinesSync();
      var previousCodeLine = '';

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Ignora comentarios: las reglas se documentan con este texto.
        final code = line.contains('//') ? line.substring(0, line.indexOf('//')) : line;
        if (code.trim().isEmpty) continue;
        if (isTokenSource(posixPath)) continue; // los archivos fuente deciden

        for (final (pattern, allowed, rule) in kForbiddenPatterns) {
          for (final match in pattern.allMatches(code)) {
            final fuente = kTokenSourceFiles[allowed];
            violations.add(
              '$posixPath:${i + 1}:${match.start + 1}: $rule '
              '(solo permitido en $allowed${fuente != null ? ' — $fuente' : ''})',
            );
          }
        }

        violations.addAll(edgeInsetsViolations(code, posixPath, i + 1));
        violations.addAll(uiRawErrorViolations(code, posixPath, i + 1));
        violations.addAll(
          debugPrintRawErrorViolations(code, previousCodeLine, posixPath, i + 1),
        );
        violations.addAll(snackBarViolations(code, posixPath, i + 1));
        violations.addAll(showErrorViolations(code, posixPath, i + 1));

        previousCodeLine = code;
      }
    }

    expect(violations, isEmpty,
        reason: 'Regesión de tokens del sistema de diseño:\n'
            '${violations.join('\n')}\n\n'
            'Consulta doc/DESIGN_SYSTEM.md (reglas de guardian).');
  });
}
