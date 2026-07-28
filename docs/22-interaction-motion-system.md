# VigiVecino
## Interaction & Motion System

Version: 1.0

Platform: Flutter

Material Design 3 (Custom)

---

# Objetivo

Este documento define cómo se siente la aplicación.

No define colores.

No define componentes.

No define pantallas.

Define el comportamiento de toda interacción entre el usuario y la interfaz.

Una buena interfaz no solamente se ve bonita.

Debe sentirse viva.

Natural.

Fluida.

Rápida.

Elegante.

---

# Filosofía

La interfaz nunca debe sentirse mecánica.

Debe responder inmediatamente a cada acción.

Toda interacción debe transmitir confianza.

Nunca ansiedad.

Nunca incertidumbre.

El usuario siempre debe saber qué ocurrió después de tocar la pantalla.

---

############################################################
FILOSOFÍA DE MOVIMIENTO
############################################################

Toda animación existe para comunicar.

Nunca para decorar.

Las animaciones deben:

Guiar.

Confirmar.

Conectar.

Enfatizar.

Nunca distraer.

---

############################################################
DURACIÓN
############################################################

Micro interacción

100 ms

---

Botones

150 ms

---

Cambio de tarjeta

200 ms

---

Bottom Sheet

250 ms

---

Cambio de pantalla

250–300 ms

---

Cambio de Dashboard

300 ms

---

Nunca utilizar animaciones superiores a 400 ms.

La aplicación debe sentirse rápida.

---

############################################################
CURVAS
############################################################

Utilizar únicamente curvas suaves.

Ease Out

Ease In Out

Fast Out Slow In

Nunca Bounce.

Nunca Elastic.

Nunca Overscroll exagerado.

---

############################################################
TRANSICIONES ENTRE PANTALLAS
############################################################

Pantallas normales

Slide horizontal.

---

Detalles

Fade + Slide.

---

Bottom Sheet

Slide desde abajo.

---

Dialogs

Scale + Fade.

---

Hero Animation

Únicamente para tarjetas importantes.

Nunca abusar.

---

############################################################
APERTURA DE TARJETAS
############################################################

Al tocar una tarjeta.

Debe reducir ligeramente su escala.

98%.

↓

Abrir.

Nunca cambiar de color abruptamente.

---

############################################################
BOTONES
############################################################

Al presionar.

Ligera reducción de escala.

↓

Ripple muy suave.

↓

Acción.

---

Después.

Feedback inmediato.

Nunca esperar la respuesta del servidor para animar el botón.

---

############################################################
FAB
############################################################

Administrador

Al tocar.

Expandir Speed Dial.

Animación radial.

---

Cobrador

Expandir.

Registrar Pago.

Registrar Propietario.

Registrar Vivienda.

---

Propietario

No utiliza FAB.

---

############################################################
BOTTOM SHEET
############################################################

Siempre abrir desde abajo.

Debe ocupar.

40 %

60 %

90 %

Según el contenido.

---

Nunca pantalla completa si no es necesario.

---

Debe poder cerrarse.

Swipe abajo.

Botón cerrar.

Toque fuera.

---

############################################################
SCROLL
############################################################

Natural.

Suave.

Sin rebotes exagerados.

---

Las tarjetas aparecen mediante Fade.

A medida que entran en pantalla.

---

Nunca animar todos los elementos simultáneamente.

---

############################################################
PULL TO REFRESH
############################################################

Disponible únicamente cuando tenga sentido.

Administrador

Dashboard.

Reportes.

---

Cobrador

Cobros.

Jornada.

---

Propietario

Dashboard.

Historial.

---

La actualización debe mostrar.

Indicador pequeño.

Nunca bloquear la pantalla.

---

############################################################
BÚSQUEDA
############################################################

Mientras escribe.

Resultados aparecen inmediatamente.

No esperar botón Buscar.

---

La transición de resultados debe ser.

Fade.

150 ms.

---

############################################################
FILTROS
############################################################

Los filtros aparecen mediante Bottom Sheet.

Al aplicar.

La lista cambia suavemente.

Nunca recargar toda la pantalla.

---

############################################################
CAMBIO DE MES
############################################################

Al cambiar el período.

Toda la información cambia.

La transición debe deslizar horizontalmente.

Como si cambiara una página.

Nunca simplemente desaparecer.

---

############################################################
MICROINTERACCIONES
############################################################

Pago registrado.

↓

Check animado.

↓

Mensaje corto.

↓

Volver automáticamente.

---

Solicitud enviada.

↓

Ícono enviado.

↓

Mensaje.

↓

Cerrar.

---

Sincronización completada.

↓

Badge cambia.

↓

Desaparece.

---

############################################################
HAPTIC FEEDBACK
############################################################

Android

Utilizar vibración ligera.

---

Acciones

Registrar pago.

Eliminar.

Enviar solicitud.

Guardar cambios.

---

Nunca vibrar por navegación.

---

############################################################
LOADING
############################################################

Nunca mostrar pantalla completamente vacía.

Utilizar Skeleton.

La información aparece gradualmente.

No toda al mismo tiempo.

---

############################################################
SIN INTERNET
############################################################

Al perder conexión.

Mostrar Banner superior.

Trabajando sin conexión.

---

No utilizar Dialog.

---

Al recuperar.

Mostrar.

Conexión restaurada.

↓

Desaparece automáticamente.

---

############################################################
SINCRONIZACIÓN
############################################################

Solo Cobrador.

---

Estados

Pendiente.

↓

Sincronizando.

↓

Completado.

↓

Ocultar.

---

Error.

↓

Mostrar Badge rojo.

↓

Permitir reintentar.

---

Nunca bloquear el trabajo.

---

############################################################
NOTIFICACIONES
############################################################

In-App

Pequeño Banner.

Desde arriba.

---

Nunca Popup invasivo.

---

Duración.

3 segundos.

---

############################################################
TOAST
############################################################

Utilizar únicamente para confirmar acciones rápidas.

Ejemplo.

Pago registrado.

Datos guardados.

Solicitud enviada.

---

Nunca para errores importantes.

---

############################################################
ERRORES
############################################################

Los errores aparecen mediante Banner.

No mediante Alert.

---

Debe explicar.

Qué ocurrió.

Qué hacer.

---

Ejemplo.

No fue posible registrar el pago.

Reintentar.

---

############################################################
GESTOS
############################################################

Permitidos.

Tap.

Double Tap.

Long Press.

Swipe.

Pull to Refresh.

---

No utilizar gestos ocultos.

Todo gesto importante debe tener una alternativa visible.

---

############################################################
TIMELINE
############################################################

Los elementos aparecen progresivamente.

No todos al mismo tiempo.

---

Al tocar.

Expanden.

↓

Bottom Sheet.

↓

Ticket.

---

############################################################
GRÁFICAS
############################################################

Animación al cargar.

1 segundo máximo.

Nunca animaciones repetitivas.

---

############################################################
ESTADOS
############################################################

Cada estado debe tener transición.

Loading

↓

Contenido

---

Contenido

↓

Vacío

---

Offline

↓

Online

---

Pendiente

↓

Pagado

---

Nunca cambios bruscos.

---

############################################################
ACCESIBILIDAD
############################################################

Toda animación debe respetar las preferencias del sistema.

Si el usuario reduce movimiento.

La aplicación también.

---

Nunca depender únicamente de animaciones para comunicar cambios.

Siempre acompañar con cambios visuales.

---

############################################################
SENSACIÓN GENERAL
############################################################

El usuario debe sentir que la interfaz responde antes de terminar de pensar.

Las acciones deben sentirse inmediatas.

Las transiciones deben ser casi invisibles.

La interfaz nunca debe llamar más la atención que el contenido.

---

############################################################
REGLAS PROHIBIDAS
############################################################

No utilizar.

Bounce.

Animaciones largas.

Parallax exagerado.

Fondos animados.

Animaciones infinitas.

Rotaciones innecesarias.

Cards que salten.

Botones que reboten.

Sombras animadas.

---

############################################################
PRINCIPIO FINAL
############################################################

La mejor animación es aquella que el usuario apenas nota, pero cuya ausencia haría que la aplicación se sintiera rígida.

El objetivo de VigiVecino no es impresionar con efectos visuales.

Es transmitir velocidad, confianza, claridad y una sensación de producto premium construido para 2026.
