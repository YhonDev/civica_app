# VigiVecino
## Screen Specifications

Version: 1.0

Platform: Flutter

Architecture: Clean Architecture

Design System: Material 3 (Custom)

---

# Objetivo

Este documento especifica cada pantalla de la aplicación.

Cada pantalla define:

- Objetivo
- Información
- Componentes
- Acciones
- Navegación
- Estados
- Reglas UX

No define widgets.

Define el comportamiento esperado.

---

############################################################
LOGIN
############################################################

Objetivo

Autenticar al usuario de forma rápida.

---

Debe mostrar

Logo.

Nombre de la aplicación.

Correo.

Contraseña.

Botón Ingresar.

Olvidé mi contraseña.

Versión.

---

No mostrar

Selector de rol.

Registro.

Configuraciones.

---

Acciones

Ingresar.

Recuperar contraseña.

---

Al iniciar sesión

↓

Backend obtiene rol

↓

Carga Dashboard correspondiente

---

Estados

Loading.

Credenciales incorrectas.

Sin Internet.

Servidor no disponible.

---

############################################################
NOTIFICACIONES
############################################################

Objetivo

Mostrar únicamente información importante.

---

Debe mostrar

Nuevos pagos.

Solicitudes.

Cambios importantes.

Avisos administrativos.

Recordatorios de pago.

---

No mostrar

Publicidad.

Mensajes innecesarios.

---

Cada notificación

Título.

Descripción.

Fecha.

Estado.

---

Click

↓

Abre directamente el módulo correspondiente.

---

############################################################
PERFIL
############################################################

Objetivo

Gestionar únicamente la información personal.

---

Debe mostrar

Foto.

Nombre.

Correo.

Teléfono.

Rol.

Conjunto.

Cerrar sesión.

---

Acciones

Editar datos permitidos.

Cambiar contraseña.

Tema claro / oscuro.

Idioma (futuro).

---

No mostrar

Información administrativa.

---

############################################################
BUSCADOR
############################################################

Objetivo

Encontrar cualquier propietario rápidamente.

---

Debe buscar por

Nombre.

Documento.

Casa.

Manzana.

Etapa.

Teléfono.

---

Mientras escribe

↓

Actualizar resultados.

---

Debe permitir filtros.

Conjunto.

Etapa.

Manzana.

Estado.

Modalidad.

---

############################################################
PROPIETARIO
############################################################

Objetivo

Consultar información general.

---

Debe mostrar

Nombre.

Casa.

Documento.

Teléfono.

Correo.

Etapa.

Manzana.

Modalidad.

Estado.

---

Acciones

Llamar.

WhatsApp.

Editar (si tiene permiso).

Registrar Pago.

---

Nunca mostrar

Auditoría.

Logs.

IDs técnicos.

---

############################################################
REGISTRAR PROPIETARIO
############################################################

Objetivo

Crear un nuevo propietario sin generar fatiga.

---

Wizard

Paso 1

Información personal.

Nombre.

Documento.

Teléfono.

Correo.

---

Paso 2

Ubicación.

Conjunto.

Etapa.

Manzana.

Casa.

---

Paso 3

Modalidad

Semanal.

Quincenal.

Mensual.

Fecha inicial.

Monto.

---

Paso 4

Resumen.

Confirmar.

Crear.

---

Duración

Menos de un minuto.

---

############################################################
REGISTRAR PAGO
############################################################

Objetivo

Registrar un pago en menos de quince segundos.

---

Debe mostrar

Nombre.

Casa.

Modalidad.

Valor sugerido.

Saldo.

Método.

Observaciones.

---

Botón principal

Registrar Pago.

---

Al registrar

↓

Animación breve.

↓

Ticket generado.

↓

Volver automáticamente.

---

No mostrar

Información histórica.

Reportes.

Configuraciones.

---

############################################################
TICKET DIGITAL
############################################################

Objetivo

Visualizar el comprobante del pago.

---

Abrir

Bottom Sheet.

---

Debe mostrar

Número.

Fecha.

Hora.

Propietario.

Casa.

Valor.

Método.

Estado.

Cobrador.

---

Botones

Cerrar.

---

Futuro

Descargar PDF.

Compartir.

Enviar por correo.

---

Nunca almacenar PDF.

El PDF se genera bajo demanda.

---

############################################################
HISTORIAL
############################################################

Objetivo

Consultar pagos anteriores.

---

Vista

Timeline.

---

Cada elemento

Mes.

Estado.

Fecha.

Valor.

---

Click

↓

Abrir Ticket.

---

Límite

Últimos doce meses.

Botón

Ver más.

Para cargar históricos antiguos.

---

############################################################
SOLICITUD DE REVISIÓN
############################################################

Objetivo

Permitir informar inconsistencias.

---

Flujo

Seleccionar pago.

↓

Escribir descripción.

↓

Enviar.

↓

Confirmación.

---

Nunca permitir

Editar pago.

Eliminar pago.

Confirmar pago.

Rechazar pago.

---

############################################################
GESTIÓN DE CASAS
############################################################

Objetivo

Administrar viviendas.

---

Debe mostrar

Casa.

Manzana.

Etapa.

Estado.

Propietario.

---

Acciones

Crear.

Editar.

Cambiar propietario.

Ver información.

---

Eliminar

Solo Administrador.

---

############################################################
GESTIÓN DE ETAPAS
############################################################

Administrador únicamente.

---

Debe mostrar

Nombre.

Cantidad de manzanas.

Cantidad de casas.

Cantidad de propietarios.

---

Acciones

Crear.

Editar.

Eliminar.

---

############################################################
GESTIÓN DE MANZANAS
############################################################

Administrador únicamente.

---

Debe mostrar

Nombre.

Número de casas.

Estado.

---

Acciones

Crear.

Editar.

Eliminar.

---

############################################################
GESTIÓN DE COBRADORES
############################################################

Administrador únicamente.

---

Debe mostrar

Nombre.

Estado.

Etapas asignadas.

Última actividad.

---

Acciones

Crear.

Editar.

Asignar etapas.

Desactivar.

---

Nunca eliminar historial.

---

############################################################
REPORTES
############################################################

Administrador únicamente.

---

Debe mostrar

Resumen.

Balance.

Cobrado.

Pendiente.

Mora.

---

Filtros

Mes.

Año.

Etapa.

Manzana.

Modalidad.

Cobrador.

---

Exportar

PDF.

CSV.

---

############################################################
BALANCES
############################################################

Objetivo

Mostrar comportamiento financiero.

---

Resumen mensual.

↓

Resumen anual.

↓

Detalle.

---

Nunca mostrar tablas inicialmente.

Utilizar tarjetas.

Gráficas simples.

Indicadores.

---

############################################################
SOLICITUDES
############################################################

Administrador

Visualiza todas.

Aprueba.

Rechaza.

Resuelve.

---

Propietario

Solo visualiza las propias.

Puede crear nuevas.

---

Cobrador

No administra solicitudes.

Solo puede consultarlas si el administrador lo permite.

---

############################################################
SIN INTERNET
############################################################

Cobrador

Puede continuar trabajando.

Registrar pagos.

Registrar propietarios.

Editar información permitida.

---

Administrador

Solo lectura de información cacheada.

---

Propietario

Consultar últimos datos sincronizados.

---

############################################################
ERROR
############################################################

Nunca mostrar errores técnicos.

Incorrecto

500 Internal Server Error

Correcto

No fue posible completar la operación.

Intenta nuevamente.

---

############################################################
EMPTY STATE
############################################################

Toda pantalla debe tener.

Ilustración.

Título.

Descripción.

Acción.

---

Ejemplo

No existen pagos registrados.

Registrar primer pago.

---

############################################################
REGLA GENERAL
############################################################

Toda pantalla debe responder una sola pregunta.

Debe permitir completar una tarea.

Debe evitar mostrar información innecesaria.

El usuario nunca debe sentirse dentro de un sistema administrativo tradicional.

La experiencia debe sentirse como una aplicación móvil premium, rápida y enfocada en la tarea actual.
