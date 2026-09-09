# Responsive & Adaptive UI — patrón oficial (apps/mobile)

> Regla de oro: **el ancho se decide por breakpoint; el alto y el contenido son siempre dinámicos.**
> Nada de anchos fijos en módulos: cajas elásticas (`Expanded`/`Flexible`), `maxLines` + `ellipsis`,
> alturas determinadas por el contenido.

## Breakpoints (`core/theme/app_breakpoints.dart`)

| Token | Valor | Uso |
|---|---|---|
| `AppBreakpoints.compact` | `< 600px` | Teléfono (portrait). Layout de 1 columna. |
| `AppBreakpoints.medium` | `>= 1024px` | Desktop / widescreen. Hasta 3 columnas. |
| `AppBreakpoints.maxFormWidth` | `440px` | Ancho máximo de formularios enfocados (login, diálogos). |
| `AppBreakpoints.maxContentWidth` | `1200px` | Ancho máximo de contenido en 4K/ultrawide. |

## Helpers de contexto (ya disponibles)

```dart
context.isCompact     // < 600
context.isMedium      // 600–1023 (tablet)
context.isExpanded    // >= 1024 (desktop)
context.isWideScreen  // >= 600 → tablet y desktop
context.gridColumns   // 1 móvil / 2 tablet / 3 desktop — para grids de tarjetas
```

## Cuándo usar qué

1. **Listas de tarjetas** (cobros, residentes, solicitudes): usar `context.gridColumns`
   con `GridView` o `SliverGrid` cuando `isWideScreen`. En móvil sigue siendo lista.
   Referencia: `cartera_screen`, `residentes_screen`, `casas_explorer_screen`.
2. **Layouts de dos paneles** (dashboard admin/residente): partir en columnas con
   `isWideScreen`; apilar en móvil.
3. **Formularios y bottom sheets**: centrar con `ContentConstrainedBox(maxWidth: AppBreakpoints.maxFormWidth)`
   — nunca ancho completo en tablet/desktop.
4. **Pantallas de ancho controlado**: envolver el body con
   `ContentConstrainedBox()` (usa `maxContentWidth`) para evitar estirado extremo.
5. **Montos y cifras**: siempre dentro de `FittedBox(fit: BoxFit.scaleDown)` para que
   `$ 1.234.567` nunca rompa la caja en pantallas angostas.
6. **Textos**: `maxLines` + `TextOverflow.ellipsis` en toda fila horizontal flexible.

## Reglas de contenido dinámico (alto variable)

- Los móviles difieren en alto y ancho: **no fijar alturas** de pantallas/módulos;
  usar `Expanded`, `Flexible`, `mainAxisSize: MainAxisSize.min` y `SingleChildScrollView`
  cuando el contenido pueda exceder.
- `SafeArea` + scroll en cada pantalla raíz.
- Los `SkeletonCard(height: …)` son la única excepción aceptable (placeholder de carga).

## Tipografía y tamaño global

- Nada de `fontSize:` inline: usar tokens de `AppTypography`
  (title, sectionHeader, display, subtitle, stat, body, bodySmall, cardTitle,
  cardValue, caption, label, small, smallBold, micro, displayMicro).
- Cambiar una escala = editar `app_typography.dart`; cambia en toda la app.
- Tarjetas: usar `AppCardStyles` (kpi, cobro, badge, list) — cambiar color/tamaño
  de las 4 familias = editar `app_card_styles.dart`.

## Moneda

- Nunca instanciar `NumberFormat` inline: usar `AppCurrency`
  (`format`, `formatCOP`, `formatCompact`, `formatOrNull`, `parse`).
- Formato canónico: `$ 10.000`.
