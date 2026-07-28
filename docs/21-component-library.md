# VigiVecino
## Component Library

Version: 1.0

Platform: Flutter

Material 3

---

# Objetivo

Este documento define todos los componentes reutilizables de la aplicación.

Toda pantalla deberá construirse únicamente utilizando estos componentes.

No se deben crear componentes nuevos si uno existente puede reutilizarse.

El objetivo es mantener una experiencia completamente consistente.

---

# Filosofía

Los componentes no son widgets.

Son bloques de construcción.

Cada componente debe resolver un único problema.

Debe ser pequeño.

Flexible.

Reutilizable.

Consistente.

---

############################################################
SECTION HEADER
############################################################

Objetivo

Separar visualmente las diferentes secciones.

---

Contiene

Título

Subtítulo (Opcional)

Botón "Ver todo" (Opcional)

---

Ejemplo

Mis Pagos

Últimos movimientos

                    Ver todo >

---

Uso

Dashboard

Listados

Historial

Notificaciones

---

############################################################
STATUS CARD
############################################################

Objetivo

Mostrar el estado actual de algo.

---

Estados

Pagado

Pendiente

En Mora

En Revisión

Sin conexión

---

Debe contener

Icono

Título

Estado

Descripción corta

---

Ejemplo

━━━━━━━━━━━━━━━━━━

✔ Estado

Al día

Último pago

15 Agosto

━━━━━━━━━━━━━━━━━━

---

Nunca mostrar demasiados datos.

---

############################################################
METRIC CARD
############################################################

Objetivo

Mostrar un indicador importante.

---

Debe contener

Título

Valor

Variación (Opcional)

Icono

---

Ejemplo

━━━━━━━━━━━━━━━━━━

Pagaron

185

+12%

━━━━━━━━━━━━━━━━━━

---

Uso

Dashboard Administrador

Dashboard Cobrador

---

############################################################
PAYMENT CARD
############################################################

Objetivo

Representar un pago.

---

Debe mostrar

Periodo

Valor

Estado

Fecha

---

Opcional

Método

Cobrador

---

Click

↓

Abrir Ticket

---

Nunca mostrar detalles extensos.

---

############################################################
TIMELINE CARD
############################################################

Objetivo

Mostrar un movimiento histórico.

---

Debe contener

Estado

Fecha

Periodo

Monto

---

Click

↓

Detalle

---

Uso

Historial

Dashboard

---

############################################################
PROPERTY CARD
############################################################

Objetivo

Representar una vivienda.

---

Debe mostrar

Casa

Propietario

Etapa

Manzana

Estado

---

Acciones

Cobrar

Ver

Editar

---

Nunca mostrar historial completo.

---

############################################################
OWNER CARD
############################################################

Objetivo

Representar un propietario.

---

Debe mostrar

Nombre

Documento

Casa

Modalidad

Estado

---

Acciones rápidas

Llamar

WhatsApp

Registrar pago

---

No mostrar

Información financiera completa.

---

############################################################
TICKET CARD
############################################################

Objetivo

Mostrar un comprobante digital.

---

Debe contener

Número

Fecha

Hora

Valor

Estado

Método

Cobrador

---

Acciones

Cerrar

---

Futuro

Compartir

PDF

---

############################################################
QUICK ACTION CARD
############################################################

Objetivo

Ejecutar una acción frecuente.

---

Ejemplos

Nuevo propietario

Registrar pago

Nueva vivienda

Ver reportes

Nueva solicitud

---

Debe tener

Icono

Texto

Animación al presionar

---

############################################################
NOTIFICATION CARD
############################################################

Objetivo

Mostrar una notificación.

---

Debe contener

Icono

Título

Descripción

Fecha

Estado leído

---

Click

↓

Abrir módulo correspondiente.

---

############################################################
CHART CARD
############################################################

Objetivo

Mostrar un gráfico sencillo.

---

Permitidos

Línea

Barras

Área

---

No permitir

Pie Chart

Radar

3D

Gráficos complejos

---

############################################################
BALANCE CARD
############################################################

Objetivo

Mostrar el balance financiero.

---

Debe mostrar

Monto

Meta

Porcentaje

Indicador visual

---

No mostrar

Detalle de pagos.

---

############################################################
SEARCH BAR
############################################################

Siempre visible.

---

Debe permitir

Buscar mientras escribe.

Limpiar búsqueda.

Filtro rápido.

---

Nunca ocultarla.

---

############################################################
FILTER CHIP
############################################################

Uso

Filtros.

---

Ejemplos

Mensual

Semanal

Pendiente

Pagado

Etapa

Manzana

---

Nunca utilizar como botón principal.

---

############################################################
BOTTOM SHEET
############################################################

Componente obligatorio.

---

Debe utilizarse para

Filtros

Detalle

Ticket

Seleccionar período

Seleccionar modalidad

Seleccionar etapa

Seleccionar vivienda

---

No utilizar para formularios largos.

---

############################################################
DIALOG
############################################################

Solo para

Eliminar

Cerrar sesión

Cancelar operación

Acciones irreversibles

---

Nunca para mostrar información.

---

############################################################
FAB
############################################################

Floating Action Button

---

Solo uno por pantalla.

---

Administrador

+

Nueva acción

↓

Speed Dial

• Registrar Pago

• Nuevo Propietario

• Nueva Vivienda

• Nuevo Cobrador

---

Cobrador

+

↓

Registrar Pago

Registrar Propietario

Registrar Vivienda

---

Propietario

No utiliza FAB.

---

############################################################
SKELETON
############################################################

Toda carga utiliza Skeleton.

---

Nunca Spinner.

---

Debe respetar el tamaño real del componente.

---

############################################################
EMPTY STATE
############################################################

Debe contener

Ilustración

Título

Descripción

Acción

---

Ejemplo

No existen pagos registrados.

Registrar primer pago.

---

############################################################
LOADING CARD
############################################################

Representa una tarjeta mientras carga.

Debe conservar exactamente el tamaño de la tarjeta real.

---

############################################################
INFO BANNER
############################################################

Objetivo

Mostrar información importante.

---

Ejemplos

Trabajando sin conexión.

Nueva versión disponible.

Pago próximo.

Solicitud respondida.

---

Nunca mostrar publicidad.

---

############################################################
MONTH PICKER
############################################################

Objetivo

Cambiar rápidamente el período.

---

Debe abrir

Bottom Sheet

---

Nunca DatePicker.

---

Debe mostrar

Mes actual.

Últimos meses.

Navegación sencilla.

---

############################################################
CONNECTIVITY BADGE
############################################################

Visible únicamente cuando cambia el estado.

---

Estados

Online

Offline

Sincronizando

Error

---

Debe desaparecer automáticamente.

---

############################################################
SYNC INDICATOR
############################################################

Solo Cobrador.

---

Estados

Pendiente

Sincronizando

Completado

Error

---

Nunca bloquear el uso de la aplicación.

---

############################################################
ACTION TILE
############################################################

Pequeño acceso rápido.

---

Icono

Texto

Chevron

---

Uso

Configuración

Perfil

Reportes

Solicitudes

---

############################################################
AVATAR
############################################################

Debe mostrar

Foto

Iniciales

Estado

---

Opcional

Badge de notificaciones.

---

############################################################
LIST ITEM
############################################################

Elemento reutilizable para listas.

---

Debe contener

Icono

Título

Descripción

Chevron

---

Nunca usar estilos diferentes según la pantalla.

---

############################################################
COMPONENTES EXCLUSIVOS
############################################################

Administrador

DashboardCard

MetricCard

ChartCard

BalanceCard

ActivityCard

---

Cobrador

JourneyCard

PropertyCard

SyncCard

CollectionCard

---

Propietario

StatusCard

TimelineCard

PaymentCard

TicketCard

RequestCard

---

############################################################
REGLAS DE COMPOSICIÓN
############################################################

Una pantalla debe construirse únicamente combinando estos componentes.

No diseñar componentes específicos para cada pantalla.

La reutilización tiene prioridad sobre la personalización.

Cada componente debe ser independiente.

Cada componente debe poder reutilizarse en cualquier módulo sin modificaciones.

---

############################################################
REGLA FINAL
############################################################

Si un diseñador o un agente necesita crear un componente nuevo, primero debe demostrar que ninguno de los componentes definidos aquí resuelve el problema.

La biblioteca de componentes debe crecer lentamente y de forma controlada.

La consistencia visual siempre tiene prioridad sobre la creatividad individual.
