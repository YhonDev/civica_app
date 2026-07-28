# VigiVecino
## Design System

Version: 1.0

Platform: Flutter (Material 3 personalizado)

---

# Objetivo

Este documento define el lenguaje visual oficial de VigiVecino.

Todo componente nuevo debe construirse siguiendo estas reglas.

No se permite crear componentes con estilos diferentes.

Toda la aplicación debe parecer desarrollada por un único equipo de diseño.

---

# Filosofía Visual

El diseño debe transmitir:

- Modernidad
- Simplicidad
- Claridad
- Rapidez
- Confianza

La interfaz debe sentirse ligera.

Nunca pesada.

Nunca saturada.

Nunca empresarial.

---

# Estilo General

Inspiración:

- Linear
- Revolut
- Stripe
- Apple Wallet
- Airbnb
- Notion Mobile
- Arc Browser

No copiar su apariencia.

Adoptar su filosofía.

---

# Color Palette

## Primary

Primary 500

#2563EB

Uso:

Botones principales.

Links.

Estados activos.

Indicadores importantes.

---

Primary Dark

#1D4ED8

Hover.

Pressed.

---

Primary Light

#DBEAFE

Fondos suaves.

Cards informativas.

---

## Success

#22C55E

Pagado.

Éxito.

Confirmaciones.

Estados positivos.

---

## Warning

#F59E0B

Pendiente.

Próximo vencimiento.

Información importante.

---

## Danger

#EF4444

En mora.

Errores.

Alertas.

Operaciones destructivas.

---

## Info

#06B6D4

Información.

Notificaciones.

Ayuda.

---

# Background

Light

#F8FAFC

Nunca usar blanco puro como fondo principal.

---

Surface

#FFFFFF

Tarjetas.

Bottom Sheets.

Dialogs.

---

Border

#E5E7EB

Separadores.

Inputs.

Cards.

---

# Typography

Fuente recomendada

Inter

o

SF Pro

(Android puede usar Inter)

---

Display

32

Bold

Solo Home.

---

Headline

28

Bold

Títulos principales.

---

Title

22

SemiBold

Título de sección.

---

Subtitle

18

Medium

Tarjetas.

---

Body

16

Regular

Texto principal.

---

Caption

13

Regular

Información secundaria.

---

Overline

11

Medium

Etiquetas.

---

# Espaciado

Unidad base

8 px

Todo debe construirse con múltiplos de 8.

8

16

24

32

40

48

64

Nunca usar espacios aleatorios.

---

# Bordes

Cards

20 px

Bottom Sheet

28 px

Botones

16 px

Inputs

16 px

FAB

Circular

Dialogs

24 px

---

# Sombras

Muy suaves.

No usar sombras oscuras.

Elevation baja.

La profundidad debe sentirse elegante.

No dramática.

---

# Iconografía

Estilo

Outlined

Minimalista.

Consistente.

Nunca mezclar estilos Filled y Outlined en una misma pantalla.

---

Iconos principales

Home

Payments

House

User

Search

Settings

Notifications

History

Chart

Calendar

Call

WhatsApp

Email

Receipt

Filter

Edit

Delete

Add

Arrow

Back

Forward

---

# Botones

## Primary Button

Color Primary.

Texto blanco.

Altura

56 px

Radio

16

Ancho completo.

Uso:

Acción principal.

---

## Secondary Button

Borde.

Fondo transparente.

Uso:

Acciones secundarias.

---

## Text Button

Sin fondo.

Solo texto.

Uso:

Cancelar.

Cerrar.

Ver más.

---

## Floating Action Button

Siempre visible.

Siempre circular.

Nunca más de un FAB por pantalla.

Acciones:

Registrar Pago

Nuevo Propietario

Nueva Casa

---

# Cards

Las Cards son el componente principal de la aplicación.

Toda la información importante vive dentro de Cards.

No usar contenedores planos.

Toda Card debe tener:

Padding interno

20 px

Radio

20

Separación externa

16 px

---

Tipos

Information Card

Status Card

Payment Card

Timeline Card

Chart Card

Quick Action Card

Property Card

User Card

---

# Inputs

Altura

56

Placeholder corto.

Label siempre visible.

No depender únicamente del Placeholder.

---

Estados

Normal

Focused

Error

Disabled

Success

---

# Search

Siempre arriba.

Siempre accesible.

Nunca ocultar detrás de un menú.

Debe buscar mientras escribe.

---

# Chips

Uso:

Filtros.

Estados.

Etiquetas.

Nunca botones.

---

Ejemplo

Mensual

Semanal

Pagado

Pendiente

En Mora

---

# Badges

Pequeños.

Color sólido.

Texto blanco.

Uso:

Cantidad.

Alertas.

Notificaciones.

---

# Bottom Navigation

Máximo cinco opciones.

Siempre visible.

Nunca más de cinco.

Administrador

Inicio

Operaciones

Comunidad

Finanzas

Perfil

---

Cobrador

Inicio

Cobros

Propietarios

Registrar

Perfil

---

Propietario

Inicio

Historial

Solicitudes

Perfil

---

# Bottom Sheets

Componente obligatorio.

Debe utilizarse para:

Filtros.

Detalle rápido.

Seleccionar mes.

Seleccionar etapa.

Seleccionar casa.

Seleccionar modalidad.

Confirmaciones.

Nunca usar Dialog cuando un Bottom Sheet sea suficiente.

---

# Dialogs

Solo para:

Eliminar.

Operaciones críticas.

Cerrar sesión.

Acciones irreversibles.

---

# Timeline

Componente oficial para historial.

Nunca usar tablas para mostrar movimientos.

Cada elemento contiene:

Estado

Fecha

Monto

Descripción

Acción

---

# Charts

Estilo minimalista.

Una línea.

Un color principal.

Mucho espacio.

Nunca mostrar más de dos gráficas por pantalla.

---

# Empty States

Toda pantalla sin datos debe tener:

Ilustración sencilla.

Título.

Descripción.

Botón de acción.

Nunca dejar una pantalla vacía.

---

Ejemplo

No hay pagos registrados.

Registrar primer pago.

---

# Loading

Usar Skeleton Loading.

Nunca Spinner en toda la pantalla.

El usuario debe percibir velocidad.

---

# Estados Visuales

## Pagado

Verde

Ícono Check

---

## Pendiente

Amarillo

Ícono Clock

---

## Mora

Rojo

Ícono Alert

---

## Revisión

Azul

Ícono Search

---

## Offline

Gris

Ícono Cloud Off

---

# Animaciones

Todas las animaciones:

200–300 ms

Curvas suaves.

Nunca rebotes exagerados.

Tipos permitidos:

Fade

Slide

Scale

Hero

---

# Accesibilidad

Contraste mínimo AA.

Botones grandes.

Texto mínimo

16 px

Toda acción importante debe poder ejecutarse con una mano.

Nunca depender únicamente del color para comunicar estados.

Siempre acompañar con un icono.

---

# Responsive

La aplicación está diseñada primero para teléfonos.

Debe adaptarse correctamente a tablets.

Nunca estirar componentes.

Reorganizar el layout.

---

# Dark Mode

Debe existir desde la primera versión.

No es una funcionalidad futura.

Todos los componentes deben tener versión Light y Dark.

Nunca invertir simplemente los colores.

Debe rediseñarse cada superficie.

---

# Componentes Prohibidos

No usar:

DataTable

Drawer lateral clásico

Menús infinitos

Tarjetas con mucho texto

Gráficos de pastel excesivos

Sombras fuertes

Gradientes exagerados

Fondos con imágenes

Botones pequeños

Formularios extremadamente largos

Pantallas saturadas

---

# Regla Final

Si un componente rompe la sensación de simplicidad, rapidez o claridad, debe rediseñarse.

El Design System existe para garantizar que cualquier pantalla nueva parezca haber sido diseñada el mismo día, por el mismo equipo y bajo la misma filosofía.

---

# Anexo: Detalles Técnicos Complementarios

> Esta sección preserva tokens de implementación concretos que existían
> en la versión anterior del Design System y que sirven como referencia
> técnica para el equipo de desarrollo Flutter. Complementa, no reemplaza,
> las reglas descritas arriba.

## Paleta de colores (tokens para `AppColors`)

```dart
// Light theme
const primary = Color(0xFF2563EB);     // base
const primaryLight = Color(0xFF60A5FA);
const primaryDark  = Color(0xFF1D4ED8);

const bgPrimary = Color(0xFFF8FAFC);   // fondo general
const bgCard    = Color(0xFFFFFFFF);   // tarjetas
const bgSurface = Color(0xFFF1F5F9);   // superficies secundarias

const textPrimary   = Color(0xFF111827);
const textSecondary = Color(0xFF6B7280);
const textDisabled  = Color(0xFF9CA3AF);

const success = Color(0xFF22C55E);
const error   = Color(0xFFEF4444);
const warning = Color(0xFFF59E0B);
const info    = Color(0xFF3B82F6);

const borderDefault = Color(0xFFE2E8F0);
const borderFocus   = Color(0xFF2563EB);
```

## Uso semántico del color (icono acompañante obligatorio)

| Estado          | Color              | Icono             |
|-----------------|--------------------|-------------------|
| Al día / Pagado | Verde `#22C55E`    | checkmark circle  |
| Pendiente       | Amarillo `#F59E0B` | clock             |
| En mora         | Rojo `#EF4444`     | alert circle      |
| En revisión     | Azul `#3B82F6`     | info              |

> Regla: nunca depender únicamente del color. Siempre acompañar con icono.

## Tipografía (tokens para `AppTypography`)

```dart
const fontFamily = 'Inter'; // SF Pro en iOS, Inter en Android

const titleSize   = 28.0;
const subtitleSize = 20.0;
const bodySize    = 16.0;
const captionSize = 13.0;
const smallSize   = 11.0;

const bold     = FontWeight.w700;
const semibold = FontWeight.w600;
const medium   = FontWeight.w500;
const regular  = FontWeight.w400;

const lineHeight   = 1.4;
const letterSpacing = -0.02;
```

## Motion tokens

```dart
const fast   = Duration(milliseconds: 200);
const normal = Duration(milliseconds: 250);
const slow   = Duration(milliseconds: 300);

const entryCurve = Curves.easeOutCubic;
const exitCurve  = Curves.easeInCubic;

// Transiciones
// push           → slideForward (250ms)
// pop            → slideBackward (250ms)
// modal          → scale + fade (200ms)
// bottomSheet    → slideUp (300ms)
// fab            → scale (200ms)
// chip selection → fade (200ms)
```

## Spacing tokens (`AppSpacing`)

```dart
const screen   = 20.0;
const card     = 20.0;
const cardInner = 16.0;

const sm = 8.0;
const md = 16.0;
const lg = 24.0;
const xl = 32.0;
```

## Border radius tokens (`AppRadius`)

```dart
const card       = 16.0;
const chip       = 20.0;
const button     = 12.0;
const input      = 12.0;
const bottomSheet = 20.0;
```

## Card — sombra estándar

```dart
BoxShadow(
  color: Color.fromRGBO(0, 0, 0, 0.06),
  blurRadius: 3,
  offset: Offset(0, 1),
)
```

> Sombra sutil, casi imperceptible. La profundidad se siente, no se ve.

## Dark Mode — paleta extendida

```dart
// Dark theme
const bgPrimaryDark = Color(0xFF0F172A);
const bgCardDark    = Color(0xFF1E293B);
const bgSurfaceDark = Color(0xFF334155);

const textPrimaryDark   = Color(0xFFF8FAFC);
const textSecondaryDark = Color(0xFF94A3B8);

const borderDefaultDark = Color(0xFF334155);
```

> Los colores semánticos (`success`, `error`, `warning`, `info`) se mantienen
> idénticos en dark mode; nunca invertir simplemente.

## Componentes reutilizables (catálogo)

| Componente       | Descripción                                                                 |
|------------------|-----------------------------------------------------------------------------|
| Card             | Flotante, radius 16, padding 20, sombra sutil.                              |
| Bottom Sheet     | Toda acción secundaria. Altura dinámica. Swipe-down para cerrar.            |
| Timeline         | Feed vertical con bullet, íconos y marcas de tiempo.                        |
| Chip             | Selectores compactos (meses, filtros, estados). Radius 20.                  |
| Search           | Barra con debounce 300ms, icono lupa, limpiar.                             |
| FAB              | Acción primaria de la pantalla. Uno por pantalla.                          |
| Dialog           | Confirmaciones, alertas, información crítica.                              |
| Badge            | Contador. Notificaciones, pendientes.                                      |
| Avatar           | Iniciales + círculo de color.                                              |
| Empty State      | Ilustración + mensaje + acción opcional.                                   |
| Snackbar         | Feedback de acciones. Inferior, 3s.                                        |
| Progress Bar     | Delgada. % de recaudo, metas.                                              |
| Donut Chart      | Circular minimalista. Distribución de estados.                             |
| Line Chart       | Línea simple. Evolución de recaudo.                                        |

## Componentes prohibidos (recordatorio)

- ❌ DataTables / tablas de datos en dashboard
- ❌ Drawer lateral como menú principal
- ❌ Menús enormes
- ❌ Diez colores en una misma pantalla
- ❌ Iconos innecesarios
- ❌ Tarjetas llenas de texto
- ❌ Formularios gigantes
- ❌ Sombras fuertes
- ❌ Gradientes exagerados
- ❌ Material clásico sin personalizar (usar solo como base)

## Accesibilidad — mínimos

- Todo usable con una mano
- Botones mínimo 48px táctil (recomendado 44x44)
- Texto mínimo 13px (cuerpo 16px)
- Contraste AA: 4.5:1 texto normal, 3:1 texto grande
- No depender del color solo — siempre icono acompañante
- Áreas táctiles ≥ 44x44px
