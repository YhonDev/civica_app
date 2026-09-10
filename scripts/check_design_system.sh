#!/usr/bin/env bash
# Guardián del sistema de diseño — hace cumplir la filosofía de tokens.
#
# Falla si reaparecen fuera de su archivo de tokens:
#   - `NumberFormat(`  → fuera de core/format/app_currency.dart  (dinero)
#   - `fontSize:`      → fuera de core/theme/app_typography.dart (tipografía)
#   - `Color(0x...)`   → fuera de core/theme/app_colors.dart     (color)
#
# Así, cambiar el formato de dinero, la escala tipográfica o la paleta
# se hace en UN archivo y se aplica a toda la app, sin depender de
# disciplina manual en revisión de código.

set -uo pipefail
cd "$(dirname "$0")/../apps/mobile"

fail=0

check() {
  local pattern="$1" name="$2" allowed="$3"
  local violations
  violations=$(grep -rnE "$pattern" lib --include='*.dart' | grep -v "$allowed" || true)
  if [ -n "$violations" ]; then
    echo "::error::[guardián $name] uso fuera del archivo de tokens — usa el token global:"
    echo "$violations"
    fail=1
  else
    echo "✓ $name: 0 violaciones"
  fi
}

check 'NumberFormat\(' 'moneda' 'core/format/app_currency.dart'
check 'fontSize:' 'tipografía' 'core/theme/app_typography.dart'
check 'Color\(0x' 'color' 'core/theme/app_colors.dart'

if [ "$fail" -ne 0 ]; then
  echo ""
  echo "El sistema de diseño quedó erosionado. Corrige usando los tokens"
  echo "(AppCurrency / AppTypography / AppColors) o actualiza el token en"
  echo "su archivo de origen si el cambio es global."
fi

exit "$fail"
