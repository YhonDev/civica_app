/// Guardian del sistema de diseño: verifica que ningún archivo fuera de los
/// archivos de tokens vuelva a introducir los patrones prohibidos.
///
/// Detecta seis tipos de regesión de tokens (reglas de guardian de
/// doc/DESIGN_SYSTEM.md):
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
      }
    }

    expect(violations, isEmpty,
        reason: 'Regesión de tokens del sistema de diseño:\n'
            '${violations.join('\n')}\n\n'
            'Consulta doc/DESIGN_SYSTEM.md (reglas de guardian).');
  });
}
