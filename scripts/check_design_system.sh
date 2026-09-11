#!/usr/bin/env bash
# Guardián del sistema de diseño — hace cumplir la filosofía de tokens.
#
# Falla si reaparecen fuera de core/theme / core/format:
#   - `NumberFormat(`  → dinero (AppCurrency)
#   - `fontSize:`      → tipografía (AppTypography)
#   - `Color(0x...)`   → color (AppColors)
#   - `BorderRadius.circular(<literal>)` / `Radius.circular(<literal>)`
#     → radios (tokens de AppSpacing)
#
# La versión completa y precisa (EdgeInsets tokenizados, línea/columna,
# regla infringida) vive en apps/mobile/test/design_token_guard_test.dart;
# este script es el espejo rápido para pre-commit y CI.

set -uo pipefail
cd "$(dirname "$0")/../apps/mobile"

fail=0

check() {
  local pattern="$1" name="$2"
  local violations
  violations=$(grep -rnE "$pattern" lib --include='*.dart' \
    | grep -v 'core/theme/' | grep -v 'core/format/' || true)
  if [ -n "$violations" ]; then
    echo "::error::[guardián $name] uso fuera de core/theme — usa el token global:"
    echo "$violations"
    fail=1
  else
    echo "✓ $name: 0 violaciones"
  fi
}

# Regla 9.7 — el error crudo jamás llega a la UI ni a logs de release.
# El árbol de decisiones fino (campos acotados permitidos en logs, exención
# por sanitizeApiError, harness lib/debug/) vive en el guard Dart.
check_97() {
  local name="$1"; shift
  local pattern="$1"; shift
  local exceptions=("$@")
  local violations
  violations=$(grep -rnE "$pattern" lib --include='*.dart' || true)
  for ex in "${exceptions[@]}"; do
    violations=$(echo "$violations" | grep -vE "$ex" || true)
  done
  if [ -n "$violations" ]; then
    echo "::error::[guardián $name] error crudo en superficie prohibida:"
    echo "$violations"
    fail=1
  else
    echo "✓ $name: 0 violaciones"
  fi
}

check 'NumberFormat\(' 'moneda'
check 'fontSize:' 'tipografía'
check 'Color\(0x' 'color'
check 'BorderRadius\.circular\(\s*[0-9]' 'radio de borde'
check 'Radius\.circular\(\s*[0-9]' 'radio (Radius)'

# 9.7a — UI: error crudo en SnackBar/toast sin sanitizeApiError
check_97 '9.7 UI' \
  '(SnackBar|showSnackBar|TopToast|Toast).*(\$(e|err|error|ex|exception|failure)\b|\$\{\s*(e|err|error|ex|exception|failure)\b)' \
  'sanitizeApiError' \
  'lib/debug/'

# 9.7b — logs: objeto de error crudo en debugPrint sin gate kDebugMode
# (gates de bloque `if (kDebugMode) {` en la línea anterior o misma línea
# quedan cubiertos por la ventana de contexto de 1 línea del guard Dart;
# este espejo solo detecta el caso más burdo, sin gate alguno cerca).
violations_97b=$(grep -rnE 'debugPrint\(.*(\$e\b|\$\{\s*e\s*\})' lib --include='*.dart' \
  | grep -v 'lib/debug/' \
  | while IFS= read -r line; do
      f=$(echo "$line" | cut -d: -f1)
      n=$(echo "$line" | cut -d: -f2)
      prev=$((n-1))
      if ! sed -n "${prev}p;${n}p" "$f" | grep -q 'kDebugMode'; then
        echo "$line"
      fi
    done || true)
if [ -n "$violations_97b" ]; then
  echo "::error::[guardián 9.7 logs] objeto de error crudo en debugPrint sin gate kDebugMode:"
  echo "$violations_97b"
  fail=1
else
  echo "✓ 9.7 logs: 0 violaciones"
fi

# 9.8 — notificaciones: estándar único TopToast
# (espejo del guard Dart: ignora el texto de comentarios al evaluar)
pat98='\b(SnackBar|ScaffoldMessenger|showSnackBar)\b'
violations_98=$(grep -rnE "$pat98" lib --include='*.dart' \
  | grep -v 'lib/core/widgets/top_toast.dart' \
  | while IFS= read -r line; do
      stripped=$(printf '%s' "$line" | sed 's|//.*||')
      if printf '%s' "$stripped" | grep -qE "$pat98"; then printf '%s\n' "$line"; fi
    done)
if [ -n "$violations_98" ]; then
  echo "::error::[guardián 9.8] notificaciones fuera del estándar TopToast:"
  echo "$violations_98"
  fail=1
else
  echo "✓ 9.8 notificaciones: 0 violaciones"
fi

# 9.9 — showError recibe el OBJETO de error; componer con sanitizeApiError
# en el call site está vetado (la sanitización vive dentro de showError).
# Espejo del guard Dart: ignora comentarios y excluye top_toast.dart.
pat99='showError\(.*sanitizeApiError'
violations_99=$(grep -rnE "$pat99" lib --include='*.dart' \
  | grep -v 'lib/core/widgets/top_toast.dart' \
  | while IFS= read -r line; do
      stripped=$(printf '%s' "$line" | sed 's|//.*||')
      if printf '%s' "$stripped" | grep -qE "$pat99"; then printf '%s\n' "$line"; fi
    done)
if [ -n "$violations_99" ]; then
  echo "::error::[guardián 9.9] showError debe recibir el objeto de error (la sanitización es interna; usa prefix: para el contexto):"
  echo "$violations_99"
  fail=1
else
  echo "✓ 9.9 showError object-error: 0 violaciones"
fi

if [ "$fail" -ne 0 ]; then
  echo ""
  echo "El sistema de diseño quedó erosionado. Corrige usando los tokens"
  echo "(AppCurrency / AppTypography / AppColors / AppSpacing) o actualiza"
  echo "el token en su archivo de origen si el cambio es global."
fi

exit "$fail"
