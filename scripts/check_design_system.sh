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

check 'NumberFormat\(' 'moneda'
check 'fontSize:' 'tipografía'
check 'Color\(0x' 'color'
check 'BorderRadius\.circular\(\s*[0-9]' 'radio de borde'
check 'Radius\.circular\(\s*[0-9]' 'radio (Radius)'

if [ "$fail" -ne 0 ]; then
  echo ""
  echo "El sistema de diseño quedó erosionado. Corrige usando los tokens"
  echo "(AppCurrency / AppTypography / AppColors / AppSpacing) o actualiza"
  echo "el token en su archivo de origen si el cambio es global."
fi

exit "$fail"
