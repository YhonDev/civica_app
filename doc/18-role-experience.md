# VigiVecino
## Role Experience Specification

Version: 1.0

Platform: Flutter

---

# Objetivo

Este documento define la experiencia completa de cada tipo de usuario.

No define componentes.

No define widgets.

No define endpoints.

Define qué debe sentir el usuario desde que abre la aplicación hasta que la cierra.

Cada rol representa una experiencia completamente distinta.

Comparten el mismo Design System.

Comparten la misma navegación.

Pero nunca la misma experiencia.

---

# Filosofía

No existen tres aplicaciones.

Existe una sola aplicación.

Pero cada usuario vive una experiencia diseñada exclusivamente para él.

El usuario nunca debe ver opciones que no necesita.

La interfaz debe adaptarse al trabajo que realiza.

No al rol almacenado en la base de datos.

---

##############################################################
# ADMINISTRADOR
##############################################################

# Objetivo

El administrador abre la aplicación para conocer el estado del conjunto y tomar decisiones.

Nunca para llenar formularios.

Nunca para navegar entre listas enormes.

Su Dashboard debe responder tres preguntas.

¿Cómo va el recaudo?

¿Qué necesita atención?

¿Qué ocurrió hoy?

---

# Primera impresión

Después del login.

Debe aparecer inmediatamente el Dashboard Ejecutivo.

No listas.

No tablas.

No CRUD.

Debe sentirse como un Centro de Control.

---

# Dashboard

Orden obligatorio.

## 1.

Selector de período.

Siempre inicia mostrando el período actual.

Ejemplo.

Agosto 2026

El selector puede abrir un Bottom Sheet para cambiar de mes.

Toda la pantalla cambia al seleccionar otro período.

Nunca solamente una tarjeta.

---

## 2.

Tarjeta Principal.

Recaudo del mes.

Debe ocupar el mayor protagonismo visual.

Debe mostrar.

Monto recaudado.

Porcentaje de cumplimiento.

Progreso visual.

No mostrar demasiados números.

---

## 3.

Indicadores rápidos.

Ejemplo.

Propietarios al día.

Propietarios pendientes.

Valor en mora.

Solicitudes abiertas.

Cobros del día.

Estos indicadores son tarjetas pequeñas.

Nunca tablas.

---

## 4.

Actividad reciente.

Debe sentirse como un feed.

Ejemplo.

Carlos registró un pago.

Ana creó un propietario.

Luis editó una vivienda.

Pedro resolvió una solicitud.

Siempre mostrar pocas actividades.

Nunca un historial completo.

---

## 5.

Acciones rápidas.

Nuevo propietario.

Nuevo cobrador.

Nueva vivienda.

Registrar pago.

Ver reportes.

---

# Qué NO debe mostrar el Dashboard

No mostrar.

CRUD completos.

Tablas.

Listados enormes.

Configuraciones.

Auditoría.

Eso pertenece a otros módulos.

---

# Flujo Mental

El administrador siempre trabaja así.

Observa.

↓

Analiza.

↓

Decide.

↓

Actúa.

La aplicación debe seguir exactamente ese flujo.

---

##############################################################
# COBRADOR
##############################################################

# Objetivo

El cobrador trabaja caminando.

Cada segundo cuenta.

Toda la experiencia debe reducir desplazamientos y toques.

Su aplicación es una herramienta de trabajo.

No un sistema administrativo.

---

# Primera impresión

Después del login.

Debe aparecer.

Mi Jornada.

Nunca estadísticas complejas.

---

# Dashboard

Debe mostrar.

Buenos días.

Nombre.

Fecha.

Estado de conexión.

---

Después.

Cobros pendientes.

Cobros realizados.

Monto esperado.

Monto recaudado.

---

Después.

Botón principal.

Iniciar Jornada.

Cuando ya inició.

Continuar Jornada.

---

Después.

Lista de cobros.

Ordenada automáticamente.

Cada tarjeta representa una vivienda.

Nunca una tabla.

---

Cada tarjeta muestra.

Nombre.

Casa.

Etapa.

Modalidad.

Estado.

Botón Cobrar.

Botón Ver.

Nada más.

---

# Registrar Pago

El registro del pago debe tomar menos de 15 segundos.

La pantalla debe mostrar.

Propietario.

Casa.

Valor sugerido.

Método de pago.

Observaciones.

Registrar.

Nada adicional.

---

# Registrar Propietario

No mostrar un formulario enorme.

Debe ser un asistente.

Paso 1.

Información personal.

Paso 2.

Ubicación.

Paso 3.

Modalidad de cobro.

Paso 4.

Resumen.

Crear.

---

# Consulta de Propietario

El cobrador puede consultar.

Nombre.

Documento.

Teléfono.

Correo.

Conjunto.

Etapa.

Manzana.

Casa.

Modalidad.

Estado.

Debe tener acciones rápidas.

Llamar.

WhatsApp.

Editar datos.

Registrar pago.

Nunca debe visualizar la auditoría.

Nunca debe eliminar pagos.

Nunca debe acceder a reportes financieros.

---

# Experiencia Offline

La aplicación debe comportarse igual.

Con Internet.

Sin Internet.

El cobrador nunca debe preocuparse por la sincronización.

Eso es responsabilidad del sistema.

---

# Flujo Mental

Buscar.

↓

Cobrar.

↓

Registrar.

↓

Continuar.

Todo debe sentirse extremadamente rápido.

---

##############################################################
# PROPIETARIO
##############################################################

# Objetivo

El propietario únicamente desea saber cómo está su vivienda.

No administra.

No registra pagos.

No configura procesos.

Consulta.

---

# Primera impresión

Después del login.

Debe aparecer.

Mi Estado.

No un menú.

No un listado.

Una vista clara.

---

# Dashboard

Debe contener.

## Tarjeta Principal

Nombre.

Casa.

Conjunto.

Estado.

Al día.

Pendiente.

En Mora.

Debe ser la información más importante.

---

## Próximo Cobro

Debe indicar.

Fecha estimada.

Modalidad.

Valor.

Estado.

Si ya fue pagado.

Debe mostrar.

Último pago realizado.

Nunca mostrar ambas cosas al mismo tiempo.

---

## Últimos Movimientos

Mostrar solamente los dos últimos.

Cada movimiento abre.

Ticket Digital.

No mostrar diez pagos.

Existe una pantalla específica para el historial.

---

## Solicitudes

Mostrar únicamente.

Cantidad.

Estado.

Acceso para crear una nueva.

---

# Historial

Debe utilizar Timeline.

Nunca tablas.

Cada elemento representa un período.

Cada elemento puede abrir.

Ticket.

Nunca el PDF directamente.

---

# Ticket

Debe abrirse como una tarjeta.

Debe contener.

Número del Ticket.

Fecha.

Valor.

Método.

Cobrador.

Estado.

Botón.

Cerrar.

En futuras versiones.

Descargar PDF.

Compartir.

---

# Solicitud de Revisión

El propietario nunca confirma un pago.

Nunca modifica un pago.

Nunca rechaza un pago.

Solo puede solicitar una revisión.

La experiencia debe ser sencilla.

Selecciona el pago.

↓

Solicitar revisión.

↓

Describe el inconveniente.

↓

Enviar.

Nada más.

---

# Flujo Mental

Consultar.

↓

Entender.

↓

Solicitar ayuda si es necesario.

Nunca más.

---

##############################################################
# EXPERIENCIA COMPARTIDA
##############################################################

Todos los roles comparten.

La misma identidad visual.

Las mismas animaciones.

Las mismas tarjetas.

Los mismos estados.

Los mismos colores.

La misma tipografía.

Solo cambia la información.

Nunca el lenguaje visual.

---

# Personalización Automática

La aplicación adapta automáticamente.

Dashboard.

Menús.

Permisos.

Acciones.

Módulos.

Sin que el usuario deba configurarlo.

---

# Estados

Toda experiencia debe contemplar.

Cargando.

Vacío.

Sin conexión.

Error.

Sin resultados.

Nunca mostrar pantallas incompletas.

---

# Acciones Principales

Administrador

Analizar.

Administrar.

Supervisar.

Auditar.

---

Cobrador

Cobrar.

Registrar.

Consultar.

Actualizar.

---

Propietario

Consultar.

Visualizar.

Solicitar revisión.

---

# Regla de Oro

Cada rol debe sentir que la aplicación fue diseñada exclusivamente para él.

Si un usuario ve funciones que nunca utilizará, la experiencia está mal diseñada.

La mejor interfaz no es la que muestra más opciones.

Es la que muestra únicamente las opciones correctas en el momento correcto.
