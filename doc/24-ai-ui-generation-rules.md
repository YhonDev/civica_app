# VigiVecino
## AI UI Generation Rules

Version: 1.0

Target:
Claude Code
Cursor
Gemini CLI
GitHub Copilot
OpenAI Codex
Cline
Aider

Platform

Flutter

Architecture

Clean Architecture

Material Design 3

---

# Objetivo

Este documento define las reglas obligatorias que cualquier agente de IA debe seguir para generar la interfaz de usuario de VigiVecino.

Estas reglas tienen prioridad sobre cualquier decisión que tome el agente.

Si alguna pantalla no cumple estas reglas debe regenerarse.

---

# Principio Principal

El agente NO está diseñando una aplicación.

Está construyendo un producto.

Toda decisión debe priorizar:

Experiencia de usuario.

Consistencia.

Escalabilidad.

Mantenibilidad.

No únicamente que el código compile.

---

# El agente NO puede inventar

El agente nunca podrá inventar:

Pantallas.

Colores.

Widgets.

Flujos.

Navegación.

Permisos.

Componentes.

Tarjetas.

Información.

Todo debe respetar la documentación existente.

---

# El agente SI puede

Crear widgets reutilizables.

Optimizar layouts.

Extraer componentes.

Reducir duplicación.

Mejorar rendimiento.

Optimizar animaciones.

Corregir accesibilidad.

Mejorar responsive.

Sin modificar la experiencia definida.

---

############################################################
ARQUITECTURA
############################################################

La interfaz debe respetar Clean Architecture.

feature/

presentation/

pages/

widgets/

controllers/

bloc/

providers/

application/

domain/

infrastructure/

Nunca mezclar responsabilidades.

---

# Organización

Cada pantalla vive dentro de su Feature.

Ejemplo

features

dashboard

presentation

pages

dashboard_page.dart

widgets

metric_card.dart

balance_card.dart

activity_card.dart

quick_actions.dart

---

Nunca colocar widgets de Dashboard dentro de otra Feature.

---

############################################################
REUTILIZACIÓN
############################################################

Si un componente ya existe.

Debe reutilizarse.

Nunca duplicarse.

Ejemplo.

StatusCard

↓

Dashboard

↓

Timeline

↓

Ticket

↓

Perfil

Todos reutilizan el mismo widget.

---

############################################################
WIDGETS
############################################################

Crear widgets pequeños.

Nunca páginas gigantes.

Objetivo.

Máximo.

250 líneas por Widget.

Máximo.

400 líneas por pantalla.

Si supera eso.

Dividir.

---

############################################################
ESTADO
############################################################

Toda pantalla debe contemplar.

Loading

Success

Error

Offline

Empty

Nunca asumir que siempre existen datos.

---

############################################################
NAVEGACIÓN
############################################################

Utilizar GoRouter.

Nunca Navigator.push directamente.

Toda ruta debe declararse.

Nunca rutas anónimas.

---

############################################################
BOTTOM SHEET
############################################################

Utilizar cuando.

Seleccionar.

Visualizar.

Confirmar.

Detalles rápidos.

Filtros.

---

Nunca crear una pantalla completa para una acción simple.

---

############################################################
DIALOG
############################################################

Únicamente para.

Eliminar.

Cerrar sesión.

Cancelar.

Operaciones irreversibles.

Nunca mostrar información simple.

---

############################################################
FORMULARIOS
############################################################

Utilizar asistentes cuando existan muchos datos.

Nunca formularios enormes.

Agrupar información.

Validar inmediatamente.

---

############################################################
ANIMACIONES
############################################################

Utilizar únicamente.

Fade.

Slide.

Hero.

Scale.

Nunca Bounce.

Nunca animaciones exageradas.

---

############################################################
LOADING
############################################################

Toda pantalla debe utilizar Skeleton Loading.

Nunca CircularProgressIndicator ocupando toda la pantalla.

---

############################################################
SCROLL
############################################################

Una sola dirección.

Nunca Nested Scroll innecesario.

Preferir:

CustomScrollView

Slivers

ListView.builder

GridView.builder

Nunca Column gigantes.

---

############################################################
LISTAS
############################################################

Toda lista larga.

Builder.

Nunca List.generate dentro de Column.

---

############################################################
RESPONSIVE
############################################################

Utilizar LayoutBuilder.

MediaQuery.

Breakpoints.

Nunca tamaños fijos.

---

############################################################
TEMA
############################################################

Toda pantalla debe funcionar correctamente en.

Light.

Dark.

Nunca utilizar colores hardcodeados.

Siempre usar Theme.

ColorScheme.

---

############################################################
ICONOS
############################################################

Utilizar únicamente Material Symbols Outlined.

Nunca mezclar librerías de iconos.

---

############################################################
TIPOGRAFÍA
############################################################

Toda tipografía proviene del Theme.

Nunca tamaños escritos manualmente.

---

############################################################
COLORES
############################################################

Utilizar únicamente.

Theme.of(context)

ColorScheme

AppColors

Nunca escribir.

Colors.red

Colors.green

Colors.blue

Directamente.

---

############################################################
ESPACIADO
############################################################

Utilizar constantes.

AppSpacing.sm

AppSpacing.md

AppSpacing.lg

Nunca números mágicos.

---

############################################################
BORDES
############################################################

Utilizar constantes.

AppRadius.sm

AppRadius.md

AppRadius.lg

---

############################################################
SOMBRAS
############################################################

Utilizar únicamente AppElevation.

Nunca BoxShadow personalizados.

---

############################################################
COMPONENTES
############################################################

Toda pantalla debe construirse reutilizando.

StatusCard

MetricCard

PaymentCard

TimelineCard

TicketCard

ChartCard

BalanceCard

QuickActionCard

SectionHeader

SearchBar

BottomSheet

FAB

---

Nunca crear variantes innecesarias.

---

############################################################
DASHBOARD
############################################################

Nunca colocar lógica de negocio.

El Dashboard únicamente consume información.

Toda lógica pertenece a la capa Application.

---

############################################################
BLOC / PROVIDER
############################################################

Nunca acceder directamente al Repository desde un Widget.

Toda comunicación pasa por.

Bloc.

Cubit.

Provider.

Riverpod.

Según la arquitectura elegida.

---

############################################################
ACCESIBILIDAD
############################################################

Todo botón.

Tooltip.

Semantics.

Contraste.

Área mínima táctil.

Nunca depender únicamente del color.

---

############################################################
RENDIMIENTO
############################################################

Utilizar const cuando sea posible.

Evitar rebuilds innecesarios.

Separar widgets.

Utilizar Keys.

---

############################################################
OFFLINE
############################################################

Nunca bloquear la UI.

Mostrar estado.

Continuar trabajando.

Sincronizar después.

---

############################################################
ERRORES
############################################################

Nunca mostrar excepciones.

Nunca mostrar StackTrace.

Siempre mensajes amigables.

---

############################################################
DOCUMENTACIÓN
############################################################

Todo widget reutilizable debe tener comentarios.

Qué hace.

Dónde utilizarlo.

Qué parámetros recibe.

---

############################################################
PRUEBAS
############################################################

Toda pantalla debe permitir.

Widget Test.

Golden Test.

Responsive Test.

Sin modificaciones.

---

############################################################
PROHIBIDO
############################################################

No crear widgets gigantes.

No duplicar código.

No hardcodear colores.

No hardcodear textos.

No usar Navigator directamente.

No usar estilos inline.

No usar números mágicos.

No crear componentes fuera del Design System.

No romper Clean Architecture.

No ignorar estados de carga.

No asumir conexión permanente.

No modificar la experiencia de usuario definida.

---

############################################################
ANTES DE GENERAR UNA PANTALLA
############################################################

El agente debe responder internamente estas preguntas:

¿Existe ya un componente reutilizable?

¿La pantalla respeta el Design System?

¿Respeta la filosofía Mobile First?

¿La tarea puede realizarse en pocos toques?

¿La pantalla muestra solo la información necesaria?

¿Se adapta a Light y Dark Mode?

¿Es accesible?

¿Funciona correctamente Offline si aplica?

¿Respeta el rol del usuario?

¿Sigue exactamente la documentación funcional?

Si alguna respuesta es NO, la implementación debe corregirse antes de continuar.

---

############################################################
OBJETIVO FINAL
############################################################

La IA no debe intentar ser creativa.

Debe ser consistente.

Debe generar una aplicación que parezca diseñada por un único equipo de producto.

Cada pantalla debe sentirse parte del mismo ecosistema.

La experiencia completa debe transmitir la sensación de una aplicación móvil premium de 2026, enfocada en rapidez, simplicidad, confianza y mantenibilidad.
