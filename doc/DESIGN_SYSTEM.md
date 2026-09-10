# Design System — Cívica Pago Mobile

> Fuente de verdad para tokens visuales, formato de dinero y reglas de construcción de UI.
> Cambios de moneda, tipografía, color, espaciado o breakpoints se versionan aquí y se
> propagan mediante las clases `App*` del `apps/mobile/lib/core/theme` y `core/format`.

## 1. Propósito

Este documento describe las reglas que usan los contribuyentes y agentes de código para
mantener la UI consistente en todos los roles (admin, cobrador, residente) y en todos los
form factors (móvil, tablet, desktop). Cuando el código repetía colores o tamaños inline,
el trabajo reciente los consolidó en las clases `AppColors`, `AppTypography`, `AppCurrency`,
`AppSpacing`, `AppBreakpoints` y `AppCardStyles`. Este doc es la contraparte humana de esa
consolidación.

## 2. Alcance

- **Moneda / formato numérico:** `AppCurrency` y el formato canónico de COP.
- **Tipografía:** `AppTypography` y la regla de única fuente de verdad de tamaños.
- **Color:** `AppColors`, paletas light/dark, semántica y acentos de módulos.
- **Espaciado y radios:** `AppSpacing`.
- **Breakpoints y layout responsive:** `AppBreakpoints` + extensiones de contexto.
- **Tarjetas:** `AppCardStyles` como punto de ajuste para las familias de tarjeta.
- **Reglas de guardian:** qué hacer y qué no cuando cambias estos tokens.

## 3. Moneda y formato numérico

### 3.1 Moneda primaria

- Moneda canónica: **COP (pesos colombianos)**.
- Formato canónico mostrado a usuarios: **`$ 10.000`**.
  - Símbolo `$` + espacio + separador de miles con punto + sin decimales.
  - Negativos: `-$ 5.000`.
- Texto explícito de moneda: **`$ 10.000 COP`**.

### 3.2 Formato y paridad de espacio

- **Regla de guardian:** nunca instancies `NumberFormat` inline. Usa siempre `AppCurrency`.
- `AppCurrency` es el punto de verdad único para formato y parseo; cambiar algo allí
  cambia la app completa (admin, cobrador, residente).
- Formatos disponibles:
  - `format(num)` → `$ 10.000` (canónico).
  - `formatCOP(num)` → `$ 10.000 COP`.
  - `formatOrNull(num?)` → `$ 0` si el monto es nulo (compatible con respuestas de API).
  - `formatCompact(num)` → `$ 1,2 M` / `$ 850 K` para charts y tooltips con poco espacio.
  - `formatInput(int)` → `10.000` (dígitos agrupados, para el input de monto).
  - `parse(String)` → `num` a partir del texto visible (con separadores).
  - conversiones de unidades: `centsToPesos`, `pesosToCents`, `centsFromJson`, `formatCents`.

### 3.3 Conversión de unidades

- Backend y motor de recaudo trabajan en **centavos (entero)**: `1 peso = 100 centavos`.
- No uses heurística como `"si > 1000 entonces /100"` para decidir unidades.
- Conversión oficial centavos → pesos: `AppCurrency.centsToPesos(int)`.
- Conversión oficial pesos → centavos: `AppCurrency.pesosToCents(int)`.
- Parseo seguro de JSON numérico de centavos a pesos: `AppCurrency.centsFromJson(dynamic)`.
- Formato de centavos en un paso: `AppCurrency.formatCents(int)`.

### 3.4 Input de monto

- Usa `AppCurrencyInputFormatter` para formatear mientras se escribe.
- `AppCurrencyInputFormatter` es `const`; el RegExp es estático.
- Grupo de miles desde la derecha con punto: `1000000` → `1.000.000`.
- Para enviar el monto puedes usar `AppCurrency.parse(textoVisible)`.

### 3.5 Convención decimal en texto interno

- En transformaciones de texto, la convención decimal usa coma en vez de punto.
- `AppCurrency` expone `_decimalComma` como detalle interno; la regla visible es:
  el formato mostrado es el canónico COP (`$ 10.000`), no variante decimal local.

## 4. Tipografía

### 4.1 Única fuente de verdad

- Archivo fuente: `apps/mobile/lib/core/theme/app_typography.dart`.
- **Regla de guardian:** no uses `fontSize:` inline. Usa los tokens de `AppTypography`.
- `copyWith` está permitido solo para **color/peso/espaciado**. Nunca para tamaño.
- Cambiar una escala se hace editando `app_typography.dart`; el cambio aplica a toda la app.

### 4.2 Escala base

| Token | Tamaño | Peso | Uso |
|---|---|---|---|
| `title` | 28 | w700 | Títulos principales |
| `sectionHeader` | 26 | w700 | Headers de sección/lista |
| `display` | 32 | w700 | Cifras hero (tickets, modos inmersivos) |
| `subtitle` | 20 | w600 | Subtítulos |
| `stat` | 22 | w800 | Cifras destacadas en dashboards |
| `body` | 16 | w400 | Cuerpo |
| `bodyMedium` | 16 | w500 | Cuerpo con énfasis moderado |
| `bodySmall` | 14 | w500 | Texto intermedio (listas densas) |
| `cardTitle` | 15.5 | w800 | Título principal de tarjeta |
| `cardValue` | 18 | w800 | Monto/cifra de tarjeta |
| `caption` | 13 | w400 | Captiones |
| `label` | 12 | w600 | Texto secundario de tarjeta/chips |
| `small` | 11 | w400 | Texto pequeño |
| `smallBold` | 11 | w600 | Pequeño con peso semibold |
| `micro` | 10 | w700 | Badges compactos |
| `displayMicro` | 9.5 | w700 | Meta-texto ultra compacto |
| `emoji` | 18 | — | Glifos decorativos (sin altura fija) |

### 4.3 Notas de construcción

- Espaciado de letras por defecto usa `-0.02` en la mayoría de estilos.
- `cardTitle` usa espaciado de letras `-0.2` por separado.
- `toTextTheme()` convierte los tokens en un `TextTheme` canónico para el tema.
- Los px mencionados son valores de diseño; se mantienen como constantes plasmadas en el código.

## 5. Color

### 5.1 Estructura

- Archivo fuente: `apps/mobile/lib/core/theme/app_colors.dart`.
- La paleta tiene tres capas: tokens light, tokens dark y colores dinámicos que se
  calculan según el modo actual.
- Para cambiar la paleta se edita **solo** este archivo, igual que `AppCurrency` para el dinero.

### 5.2 Tokens light

- `lightBackground` → `0xFFF1F5F9`
- `lightCard` → `0xFFFFFFFF`
- `lightSurface` → `0xFFE2E8F0`
- `lightTextPrimary` → `0xFF111827`
- `lightTextSecondary` → `0xFF64748B`
- `lightTextDisabled` → `0xFF9CA3AF`
- `lightBorder` → `0xFFCBD5E1`

### 5.3 Tokens dark

- `darkBackground` → `0xFF121417`
- `darkCard` → `0xFF23272D`
- `darkSurface` → `0xFF1B1E22`
- `darkTextPrimary` → `0xFFFFFFFF`
- `darkTextSecondary` → `0xFF94A3B8`
- `darkTextDisabled` → `0xFF64748B`
- `darkBorder` → `0xFF32373E`

### 5.4 Modo actual (dinámico)

- `background` → `lightBackground` / `darkBackground`.
- `card` → `lightCard` / `darkCard`.
- `surface` → `lightSurface` / `darkSurface`.
- `textPrimary` → `lightTextPrimary` / `darkTextPrimary`.
- `textSecondary` → `lightTextSecondary` / `darkTextSecondary`.
- `textDisabled` → `lightTextDisabled` / `darkTextDisabled`.
- `border` → `lightBorder` / `darkBorder`.

### 5.5 Tarjeta elevada

- `elevatedCard` → `darkCard` / `lightCard`.
- `elevatedCardText` → texto de énfasis sobre tarjeta elevada.
- `elevatedCardTextSecondary` → texto secundario sobre tarjeta elevada.
- `elevatedCardBorder` → borde de tarjeta elevada.

### 5.6 Semántica

- `success` → `0xFF22C55E`
- `error` → `0xFFEF4444`
- `warning` → `0xFFF59E0B`
- `info` → `0xFF3B82F6`
- Superficies tintadas por estado:
  - `successSurface` / `errorSurface` / `warningSurface`.

### 5.7 Acentos de categoría y característica

- `accentPurple` → `0xFF8B5CF6`
- `accentOrange` → `0xFFF97316`
- `accentTeal` → `0xFF14B8A6`

### 5.8 Módulo cobrador / modo inmersivo

- Estos tokens reemplazan literales dispersos como `0xFF0F172A`, `0xFF1E293B`,
  `0xFFF8FAFC`, `0xFF334155`, etc.
- Cambiar la paleta del flujo cobrador se hace **solo** en `AppColors`.
- Tokens cobrador:
  - `screenBackground`
  - `immersiveBackground`
  - `cobradorCard`
  - `cobradorSubcard`
  - `cobradorHighlight`
  - `borderStrong`
  - `track`
  - `inkStrong`
  - `successSurface`, `errorSurface`, `warningSurface` (también pertenecen a la capa semántica)
- Toast (`top_toast`):
  - `toastSurface`, `toastTitle`, `toastBody`, `toastSuccess`, `toastError`, `toastWarning`, `toastInfo`.

## 6. Espaciado y radios

- Archivo fuente: `apps/mobile/lib/core/theme/app_spacing.dart`.
- Gaps:
  - `xs` 4, `sm` 8, `md` 16, `lg` 24, `xl` 32.
- Padding:
  - `screenPadding` 20, `cardPadding` 20, `cardInnerPadding` 16.
- Radios:
  - `cardRadius` 16, `chipRadius` 20, `buttonRadius` 12, `inputRadius` 12,
    `bottomSheetRadius` 20.
  - Escala completa de radios: `radiusSm` 6, `radiusMd` 8, `radiusLg` 10,
    `radiusProgress` 4 (barras de progreso/pills finas), `radiusXl` 22
    (tiles héroe), `heroRadius` 28 (contenedores héroe del modo inmersivo),
    `radiusCircle` 999 (círculos perfectos).
- Helpers:
  - `screenEdgeInsets`, `cardEdgeInsets`.

## 7. Breakpoints y layout responsive / adaptive

> Fuente única del patrón responsive/adaptive. El antiguo
> `apps/mobile/doc/RESPONSIVE_PATTERN.md` se consolidó aquí y queda como puntero —
> edita las reglas de esta sección, no allí.

### 7.1 Regla de oro

- **El ancho se decide por breakpoint; el alto y el contenido son siempre dinámicos.**
- Nada de anchos fijos en módulos: cajas elásticas (`Expanded`/`Flexible`), `maxLines` +
  `ellipsis`, alturas determinadas por el contenido.
- Los móviles difieren en alto y ancho: no fijar alturas de pantallas/módulos.
- Usar `Expanded`, `Flexible`, `mainAxisSize: MainAxisSize.min` y
  `SingleChildScrollView` cuando el contenido pueda exceder.
- `SafeArea` + scroll en cada pantalla raíz.
- `SkeletonCard(height: …)` es la única excepción aceptable (placeholder de carga).

### 7.2 Breakpoints

- Fuente: `apps/mobile/lib/core/theme/app_breakpoints.dart`.
- Basados en Material Design 3.
- `compact` → `< 600px`: móvil portrait, layout de 1 columna.
- `medium` → `1024px`: umbral para desktop/widescreen.
- `expanded` → `1440px`: umbral interno adicional.
- `maxFormWidth` → `440px`: ancho máximo de formularios enfocados (login, diálogos).
- `maxContentWidth` → `1200px`: ancho máximo de contenido en 4K/ultrawide.

### 7.3 Helpers de contexto

- `context.isCompact` → `< 600`.
- `context.isMedium` → `600–1023`.
- `context.isExpanded` → `>= 1024`.
- `context.isWideScreen` → `>= 600` (tablet y desktop).
- `context.gridColumns` → 1 móvil / 2 tablet / 3 desktop.

### 7.4 Cuándo usar qué

1. **Listas de tarjetas** (cobros, residentes, solicitudes): usar `context.gridColumns`
   con `GridView`/`SliverGrid` cuando `isWideScreen`. En móvil sigue siendo lista.
2. **Layouts de dos paneles** (dashboard admin/residente): partir en columnas con
   `isWideScreen`; apilar en móvil.
3. **Formularios y bottom sheets**: centrar con
   `ContentConstrainedBox(maxWidth: AppBreakpoints.maxFormWidth)`.
4. **Pantallas de ancho controlado**: envolver el body con `ContentConstrainedBox()`
   (usa `maxContentWidth`) para evitar estirado extremo.
5. **Montos y cifras**: siempre dentro de `FittedBox(fit: BoxFit.scaleDown)` para que
   `$ 1.234.567` nunca rompa la caja en pantallas angostas.
6. **Textos**: `maxLines` + `TextOverflow.ellipsis` en toda fila horizontal flexible.

### 7.5 Tipografía y moneda en layout responsive

- Nada de `fontSize:` inline: usar tokens de `AppTypography`.
- Nunca instanciar `NumberFormat` inline: usar `AppCurrency`.
- Tarjetas: usar `AppCardStyles` para cambiar color/tamaño de las familias.

### 7.6 Escalado de texto del sistema

- La app acota el `textScaler` del sistema al rango **[1.0, 1.3]**
  (`AppBreakpoints.maxTextScale`) en el builder compartido de `MaterialApp`
  (`main.dart`). Es el único punto donde se toca el escalado global.
- Las alturas fijas que contienen texto (filas de chips, extents de grid,
  badges altos) deben multiplicarse por `context.scaleForText`
  (`app_breakpoints.dart`), que devuelve el factor efectivo ya acotado.
  Ejemplo: `height: 32 * context.scaleForText`.
- Nunca escales tamaños de fuente a mano: el texto escala solo vía el
  `textScaler`; los tokens de `AppTypography` son valores de diseño px.
- Prohibido `SizedBox(height: fijo)` alrededor de widgets cuya altura
  depende del texto (chips, badges): se recortan con fuente grande.
  Usa la altura escalada o `minHeight` cuando el contenedor lo permita.

## 8. Tarjetas

- Archivo fuente: `apps/mobile/lib/core/theme/app_card_styles.dart`.
- Punto de ajuste único para las familias de tarjeta; el cambio se aplica a toda la app
  sin importar el rol.
- Familias:
  1. `kpi` — tarjetas de métrica (KPICard, MiniStatCard, ModuleSummaryCard).
  2. `cobro` — tarjetas de cobro/estado (CobroCard, EstadoCuentaCard).
  3. `badge` — badges/píldoras de estado dentro de tarjetas.
  4. `list` — tarjetas de lista genérica (SolicitudCard, filas de actividad).
- Estilos de tipografía por familia:
  - `cardTitle`, `cardValue`, `cardLabel`, `cardCaption`, `badgeText`.
  - variantes KPI: `kpiValue`, `kpiTitle`, `kpiLabel`, `kpiStatValue`, `bigStat`.
  - variantes cobro: `cobroTitle`, `cobroSubtitle`, `cobroValue`, `heroValue`, `metaChipText`.
  - variantes lista: `listTitle`, `listSubtitle`, `listMeta`, `listRowLabel`, `cardAction`,
    `badgePillText`, `statusText`.
- Contenedores:
  - `elevatedCard`, `listCard`, `heroCard`, `sectionCard`, `tintedCard`, `iconTile`,
    `badge`, `metaChip`, `conceptChip`.
- Padding estándar de tarjeta: `cardPadding`.

## 9. Reglas de guardian

> **Chequeo automático (dos capas):**
> 1. `apps/mobile/test/design_token_guard_test.dart` (incluido en `flutter test` y como
>    paso explícito `Design token guard (test)` en CI) escanea `lib/` y falla si detecta
>    `fontSize:` inline, `NumberFormat`, hex `Color(0x…)`, radios con literal
>    (`BorderRadius.circular(<n>)` / `Radius.circular(<n>)`) o `EdgeInsets` compuestos
>    solo de valores tokenizados {4, 8, 16, 20, 24, 32} escritos con números — todo
>    fuera de `core/theme/` y `core/format/`. El fallo incluye ruta, línea, columna y
>    la regla infringida.
> 2. `scripts/check_design_system.sh` (paso `Design system guard` en CI) es el espejo
>    rápido de los patrones de texto.
>
> Estas reglas se aplican en la práctica, no solo en papel; si el guard marca tu PR,
> mueve el valor a un token.

### 9.1 Reglas generales

- Cambiar moneda, formato numérico, tipografía, color, espaciado o breakpoints se hace
  **en los archivos de `core/theme` o `core/format`**, no dispersando literais por screens.
- Privilegia tokens existentes antes de crear nuevos. Si un color o tamaño aparece en más de
  un lado, debe vivir en `AppColors`, `AppTypography`, `AppSpacing`, `AppBreakpoints` o
  `AppCardStyles`.

### 9.2 Moneda

- No instancies `NumberFormat` inline.
- Usa `AppCurrency` para formato y `AppCurrencyInputFormatter` para el input.
- Si la app muestra dinero, pasa por `AppCurrency`; no armes formatos ad-hoc.
- El formato canónico es `$ 10.000` y el formato con moneda explícita es `$ 10.000 COP`.

### 9.3 Tipografía

- No uses `fontSize:` inline; usa `AppTypography`.
- `copyWith` solo para color/peso/espaciado, no para tamaño.
- Para tarjetas, usa `AppCardStyles` en vez de reconstruir estilos a mano.
- Cambiar una escala implica editar `app_typography.dart`.

### 9.4 Color

- Cambiar la paleta la aplicación se hace editando `app_colors.dart`.
- No uses literales dispersos para los colores que ya tienen token, especialmente en el
  módulo cobrador y el toast.
- Si necesitas un tinte/alpha, deriva de un token existente en vez de inventar un hex nuevo.
- Los colores semánticos (`success`, `error`, `warning`, `info`) existen para estados y
  feedback; usarlos como semántica, no como paleta decorativa arbitraria.

### 9.5 Espaciado y radios

- Reusa `AppSpacing` antes de declarar offsets a mano.
- Mantener radios consistentes mediante `AppSpacing.cardRadius`, `buttonRadius`,
  `radiusSm`… — nunca `BorderRadius.circular(<literal>)` fuera de `core/theme/`.
- Un `EdgeInsets` cuyos valores son todos tokens de espaciado (4, 8, 16, 20, 24, 32)
  debe escribirse con los tokens (`AppSpacing.xs/sm/md/screenPadding/lg/xl`); los
  offsets posicionales no tokenizados siguen permitidos.

### 9.6 Responsive

- El ancho se decide por breakpoint; el alto y el contenido son dinámicos.
- No fijar anchos de módulos; usar `Expanded`/`Flexible`/`ContentConstrainedBox`.
- No fijar alturas de pantallas; usar `Expanded`/`Flexible`/`SingleChildScrollView`.
- Textos y montos en contenedores elásticos deben protegerse con `maxLines` +
  `ellipsis` y `FittedBox` respectivamente.

## 10. Referencias rápidas

- Moneda: `AppCurrency` (`apps/mobile/lib/core/format/app_currency.dart`).
- Tipografía: `AppTypography` (`apps/mobile/lib/core/theme/app_typography.dart`).
- Color: `AppColors` (`apps/mobile/lib/core/theme/app_colors.dart`).
- Espaciado: `AppSpacing` (`apps/mobile/lib/core/theme/app_spacing.dart`).
- Breakpoints: `AppBreakpoints` + `ResponsiveContext`
  (`apps/mobile/lib/core/theme/app_breakpoints.dart`).
- Tarjetas: `AppCardStyles` (`apps/mobile/lib/core/theme/app_card_styles.dart`).
- Patrón responsive/adaptive: sección 7 de este documento (antes
  `apps/mobile/doc/RESPONSIVE_PATTERN.md`, ahora solo un puntero).
