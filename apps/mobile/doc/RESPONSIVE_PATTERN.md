# Responsive & Adaptive UI — patrón oficial (apps/mobile)

> **Este documento se consolidó en el sistema de diseño.** La fuente de verdad única para
> responsive/adaptive es ahora la **sección 7 de [`doc/DESIGN_SYSTEM.md`](../../doc/DESIGN_SYSTEM.md)**
> (breakpoints, helpers de contexto, cuándo usar qué, reglas de contenido dinámico,
> tipografía y moneda en layout responsive).
>
> Este archivo se mantiene solo como puntero para quien llegue desde `apps/mobile`;
> no agregues reglas aquí — edítalas en el sistema de diseño.

Regla de oro (resumen): **el ancho se decide por breakpoint; el alto y el contenido son
siempre dinámicos.** Nada de anchos fijos en módulos: cajas elásticas (`Expanded`/`Flexible`),
`maxLines` + `ellipsis`, alturas determinadas por el contenido.
