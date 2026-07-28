# VigiVecino
## Dashboard Specification

Version: 1.0

Platform: Flutter

---

# Objetivo

Este documento define el comportamiento completo de los Dashboard de todos los roles.

No describe widgets específicos.

Describe exactamente qué debe ver el usuario al abrir la aplicación.

Cada Dashboard representa el centro de trabajo del usuario.

Nunca debe sentirse como un menú.

Nunca debe sentirse como un listado.

Debe sentirse como una pantalla viva que resume el estado actual.

---

##########################################################
# PRINCIPIOS GENERALES
##########################################################

Todos los Dashboard deben cumplir las siguientes reglas.

Siempre mostrar información del período actual.

Siempre cargar primero la información más importante.

Nunca saturar la pantalla.

Nunca mostrar tablas.

Nunca mostrar listas enormes.

Nunca mostrar más de cinco bloques principales.

Cada tarjeta debe responder una sola pregunta.

El Dashboard siempre debe poder recorrerse con un solo scroll.

---

# Estructura General

Todos los Dashboard siguen la misma estructura.

1.

Header

↓

2.

Tarjeta Principal

↓

3.

Resumen

↓

4.

Actividad

↓

5.

Acciones rápidas

---

##########################################################
# HEADER
##########################################################

El Header debe ser limpio.

Nunca mostrar demasiados botones.

Debe contener.

Avatar.

Nombre.

Rol.

Período actual.

Notificaciones.

---

Ejemplo.

━━━━━━━━━━━━━━━━━━━━━━

👤 Carlos Gómez

Administrador

Agosto 2026 ▼

🔔

━━━━━━━━━━━━━━━━━━━━━━

---

# Selector de período

Siempre inicia mostrando el período actual.

Ejemplo.

Agosto 2026

Al tocar.

Debe abrir un Bottom Sheet.

Nunca un DatePicker.

El usuario podrá cambiar fácilmente entre meses.

Al cambiar el período.

Toda la pantalla se actualiza.

Nunca únicamente una tarjeta.

---

##########################################################
# DASHBOARD ADMINISTRADOR
##########################################################

Objetivo.

Permitir conocer el estado completo del conjunto en menos de cinco segundos.

---

## Tarjeta Principal

Debe ocupar el mayor protagonismo.

Debe mostrar.

Monto recaudado.

Meta mensual.

Porcentaje alcanzado.

Indicador visual.

No más.

---

Ejemplo.

━━━━━━━━━━━━━━━━━━━━━━

Recaudo Agosto

$12.450.000

82 %

██████████░░░

Meta

$15.000.000

━━━━━━━━━━━━━━━━━━━━━━

---

## Indicadores rápidos

Mostrar cuatro tarjetas pequeñas.

Pagaron.

Pendientes.

Solicitudes.

Mora.

Ejemplo.

━━━━━━━━━━━━━━━━━━━━━━

✔ Pagaron

184

━━━━━━━━━━

⚠ Pendientes

24

━━━━━━━━━━

💬 Revisiones

3

━━━━━━━━━━

💰 Mora

$2.300.000

━━━━━━━━━━━━━━━━━━━━━━

---

## Balance

Debe mostrar una gráfica sencilla.

Nunca más de una gráfica por bloque.

Debe permitir cambiar.

Semanal.

Quincenal.

Mensual.

Anual.

Sin salir del Dashboard.

---

## Distribución

Mostrar.

Semanales.

Quincenales.

Mensuales.

Como barras horizontales.

Nunca gráficos complejos.

---

## Actividad Reciente

Mostrar únicamente.

Últimos cinco eventos.

Ejemplo.

Carlos registró un pago.

Hace 3 minutos.

━━━━━━━━━━

Juan creó un propietario.

Hace 10 minutos.

━━━━━━━━━━

Ana resolvió una revisión.

Hace 30 minutos.

---

## Acciones rápidas

Nuevo Propietario.

Nueva Vivienda.

Nuevo Cobrador.

Registrar Pago.

Ver Reportes.

---

## Qué NO mostrar

No mostrar.

Usuarios.

Casas.

CRUD.

Tablas.

Configuraciones.

Auditoría.

Filtros avanzados.

---

##########################################################
# DASHBOARD COBRADOR
##########################################################

Objetivo.

Que el cobrador pueda comenzar su jornada en menos de diez segundos.

---

## Tarjeta Principal

Mi Jornada.

Debe mostrar.

Cobros pendientes.

Cobros realizados.

Monto esperado.

Monto recaudado.

Estado de sincronización.

---

Ejemplo.

━━━━━━━━━━━━━━━━━━━━━━

Mi Jornada

Pendientes

12

Realizados

7

Esperado

$850.000

Recaudado

$540.000

━━━━━━━━━━━━━━━━━━━━━━

---

## Botón Principal

Debe existir un único botón principal.

Si aún no inició.

"Iniciar Jornada"

Si ya inició.

"Continuar Jornada"

---

## Cobros de Hoy

Lista compacta.

Cada tarjeta representa una vivienda.

Debe mostrar.

Nombre.

Casa.

Etapa.

Modalidad.

Estado.

Botón Cobrar.

---

No mostrar.

Historial.

Auditoría.

Balances.

Gráficas.

---

## Accesos rápidos

Buscar Propietario.

Registrar Propietario.

Registrar Vivienda.

Todos mediante FAB.

Nunca mediante botones grandes.

---

## Estado Offline

Siempre visible.

Si no existe conexión.

Mostrar.

Sin conexión.

Trabajando localmente.

Nunca bloquear la aplicación.

---

##########################################################
# DASHBOARD PROPIETARIO
##########################################################

Objetivo.

Que el propietario conozca inmediatamente su estado financiero.

---

## Tarjeta Principal

Debe mostrar.

Estado.

Al día.

Pendiente.

En Mora.

Debe ocupar el mayor protagonismo.

Nunca mostrar saldos innecesarios.

---

Ejemplo.

━━━━━━━━━━━━━━━━━━━━━━

Casa A-23

Estado

✔ Al día

Último pago

15 Agosto

━━━━━━━━━━━━━━━━━━━━━━

---

## Próximo Cobro

Si existe una cuota pendiente.

Mostrar.

Fecha.

Valor.

Modalidad.

Estado.

---

Si no existe.

Mostrar.

Último pago realizado.

Nunca ambas tarjetas simultáneamente.

---

## Últimos Movimientos

Mostrar solamente.

Dos movimientos.

Cada movimiento.

Abre.

Ticket Digital.

---

## Solicitudes

Mostrar.

Cantidad.

Estado.

Botón.

Solicitar Revisión.

Nunca Confirmar Pago.

Nunca Aprobar Pago.

---

##########################################################
# TICKET DIGITAL
##########################################################

El Ticket Digital siempre se abre desde un movimiento.

Nunca directamente.

Debe abrir mediante Bottom Sheet.

Debe mostrar.

Número.

Fecha.

Valor.

Método.

Cobrador.

Estado.

Botón.

Cerrar.

En futuras versiones.

Compartir.

Descargar PDF.

---

##########################################################
# TARJETAS
##########################################################

Todas las tarjetas siguen el mismo diseño.

Título.

↓

Dato principal.

↓

Dato secundario.

↓

Acción.

Nunca agregar más de cuatro niveles.

---

##########################################################
# LOADING
##########################################################

Todo Dashboard utiliza Skeleton Loading.

Nunca Spinner de pantalla completa.

La información aparece progresivamente.

No toda al mismo tiempo.

---

##########################################################
# ANIMACIONES
##########################################################

Toda tarjeta.

Fade + Slide.

Duración.

200–300 ms.

Cambio de período.

Animación horizontal.

Bottom Sheet.

Deslizar desde abajo.

Nunca rebotes exagerados.

---

##########################################################
# RESPONSIVE
##########################################################

Teléfono.

Una columna.

Tablet.

Dos columnas.

Nunca estirar tarjetas.

Reorganizar el contenido.

---

##########################################################
# REGLA FINAL
##########################################################

El Dashboard debe responder una única pregunta.

Administrador.

¿Cómo está el conjunto hoy?

Cobrador.

¿Qué debo hacer ahora?

Propietario.

¿Cómo está mi vivienda?

Si un Dashboard intenta responder más preguntas, debe simplificarse.

La mejor experiencia es aquella donde el usuario encuentra la información correcta sin buscarla.
