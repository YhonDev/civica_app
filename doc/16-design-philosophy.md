# VigiVecino
## Design Philosophy

Version: 1.0

---

# Objetivo

Este documento define las reglas de diseño que toda la aplicación debe seguir.

No describe widgets.

No describe pantallas.

Describe la forma en que la aplicación debe sentirse.

Toda decisión de UI y UX debe respetar estas reglas.

Si alguna pantalla rompe estas reglas, debe rediseñarse.

---

# Filosofía General

VigiVecino debe sentirse como una aplicación móvil premium del año 2026.

No debe parecer un sistema administrativo.

No debe parecer un ERP.

No debe parecer una aplicación desarrollada únicamente para escritorio adaptada a móvil.

Debe sentirse como una aplicación creada primero para dispositivos móviles (Mobile First).

La experiencia debe ser limpia, rápida, elegante y extremadamente intuitiva.

---

# El usuario nunca debe pensar

La aplicación debe ser tan intuitiva que el usuario nunca tenga que preguntarse:

- ¿Dónde está esta opción?
- ¿Qué debo hacer ahora?
- ¿Dónde quedó esta información?
- ¿Qué significa este botón?

La interfaz debe responder esas preguntas antes de que aparezcan.

---

# Una pantalla = Una tarea

Cada pantalla tiene un único propósito.

Incorrecto:

Dashboard

- Balance
- Usuarios
- Casas
- Reportes
- Configuración
- Auditoría
- Gráficas
- CRUD

Correcto:

Dashboard

¿Cómo está el conjunto hoy?

Si el usuario necesita otra información, navega al módulo correspondiente.

Nunca mezclar responsabilidades.

---

# Menos es más

Eliminar cualquier elemento que no aporte valor.

Cada botón debe existir por una razón.

Cada tarjeta debe responder una pregunta.

Cada icono debe comunicar algo.

Si un elemento puede eliminarse sin afectar la experiencia, debe eliminarse.

---

# Prioridad Visual

Toda pantalla debe responder esta jerarquía.

1. Lo más importante.

2. Lo importante.

3. Información secundaria.

4. Información histórica.

Nunca invertir este orden.

---

# No mostrar todo

El error más común de las aplicaciones administrativas es mostrar demasiada información.

VigiVecino debe mostrar únicamente un resumen.

El detalle siempre aparece cuando el usuario lo solicita.

Ejemplo.

Dashboard

Últimos dos pagos.

No mostrar doce.

Si el usuario quiere ver todos,

presiona

"Ver historial"

---

# Progresive Disclosure

La información aparece por niveles.

Nivel 1

Resumen.

↓

Nivel 2

Detalle.

↓

Nivel 3

Información completa.

Nunca mostrar toda la información desde el inicio.

---

# Navegación

La navegación debe sentirse natural.

El usuario nunca debe perder el contexto.

Toda navegación importante debe mantener visible el punto de partida.

Siempre que sea posible usar:

Bottom Sheet

Modal

Slide Panel

antes que abrir una pantalla completamente nueva.

---

# Máximo tres toques

Toda tarea frecuente debe completarse en tres toques o menos.

Registrar un pago.

Consultar una vivienda.

Buscar un propietario.

Solicitar una revisión.

Si requiere más pasos, la experiencia debe simplificarse.

---

# El contenido es el protagonista

Los componentes nunca deben competir con la información.

Los colores ayudan.

No llaman la atención.

Las tarjetas organizan.

No decoran.

Las animaciones acompañan.

No distraen.

---

# Diseño basado en acciones

El usuario abre la aplicación para hacer algo.

No para mirar botones.

Cada pantalla debe responder inmediatamente:

¿Qué puedo hacer aquí?

Las acciones principales siempre deben ser visibles.

---

# Dashboard ≠ Administración

El Dashboard nunca administra.

El Dashboard informa.

Las operaciones administrativas pertenecen a módulos independientes.

Dashboard

↓

Resumen

↓

Indicadores

↓

Actividad

↓

Acciones rápidas

Nunca CRUD completos.

---

# Consistencia absoluta

Todos los módulos utilizan el mismo lenguaje visual.

Las tarjetas tienen el mismo estilo.

Los botones tienen el mismo comportamiento.

Los colores representan siempre lo mismo.

Los iconos representan siempre la misma acción.

Nunca cambiar el significado de un color.

Ejemplo.

Verde

Siempre significa correcto.

Nunca significa información.

---

# Estados

Todo elemento tiene estados claramente definidos.

Activo

Inactivo

Pendiente

Pagado

Parcial

En Mora

Revisión

Sin conexión

Sin resultados

Cargando

Vacío

Nunca dejar un estado sin representación visual.

---

# Microinteracciones

Cada acción importante debe generar una respuesta inmediata.

Guardar.

Registrar.

Eliminar.

Actualizar.

Buscar.

Filtrar.

La aplicación siempre confirma visualmente que la acción ocurrió.

---

# Velocidad percibida

La aplicación debe sentirse rápida incluso cuando espera información.

Siempre utilizar:

Skeleton Loading.

Shimmer.

Indicadores suaves.

Nunca mostrar pantallas completamente vacías esperando datos.

---

# Búsquedas

Buscar debe ser más rápido que navegar.

Siempre que existan más de diez elementos debe existir búsqueda.

Siempre que existan muchos resultados deben existir filtros.

---

# Errores

Nunca mostrar errores técnicos.

Incorrecto.

Error 500.

Correcto.

No fue posible registrar el pago.

Inténtalo nuevamente.

Siempre indicar una posible solución.

---

# Confirmaciones

Solo confirmar acciones destructivas.

Eliminar.

Cerrar jornada.

Cancelar.

Nunca pedir confirmación para acciones frecuentes.

Registrar un pago debe ser rápido.

---

# Formularios

Los formularios deben sentirse ligeros.

Agrupar campos relacionados.

Usar asistentes cuando existan muchos pasos.

Nunca mostrar veinte campos al mismo tiempo.

---

# Scroll

El usuario debe desplazarse naturalmente.

Evitar pantallas extremadamente largas.

Agrupar la información mediante tarjetas.

---

# Diseño emocional

La aplicación debe transmitir confianza.

Nunca ansiedad.

Nunca saturación.

Nunca complejidad.

El usuario debe sentir que entiende la aplicación desde el primer minuto.

---

# Filosofía por Rol

Administrador

Abre la aplicación para tomar decisiones.

No para llenar formularios.

---

Cobrador

Abre la aplicación para trabajar.

Debe registrar pagos rápidamente.

Debe consultar propietarios rápidamente.

Debe moverse rápidamente.

---

Propietario

Abre la aplicación para informarse.

Nunca para administrar.

Debe conocer inmediatamente:

Estado.

Próximo cobro.

Último pago.

Historial.

---

# Regla de Oro

Antes de agregar cualquier componente preguntarse:

¿Este elemento ayuda al usuario a completar su tarea?

Si la respuesta es no,

el componente no debe existir.

---

# Principio Final

La mejor interfaz no es la que tiene más componentes.

Es aquella donde el usuario termina su tarea sin pensar en la interfaz.

Ese es el objetivo de VigiVecino.
