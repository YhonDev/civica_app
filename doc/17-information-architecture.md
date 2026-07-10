# VigiVecino
## Information Architecture

Version: 1.0

Platform: Flutter

---

# Objetivo

Este documento define la arquitectura funcional de la aplicación.

No define el backend.

No define endpoints.

No define entidades.

Define cómo el usuario navega por la aplicación.

Toda la arquitectura está orientada a la experiencia del usuario.

No al modelo de datos.

---

# Filosofía

La navegación debe ser extremadamente sencilla.

El usuario nunca debe preguntarse dónde está una función.

Cada módulo debe tener una responsabilidad clara.

Nunca mezclar responsabilidades.

La información debe organizarse por contexto de trabajo.

No por tablas de base de datos.

---

# Arquitectura General

La aplicación se divide en tres experiencias independientes.

Cada experiencia posee:

- navegación propia
- dashboard propio
- permisos propios
- módulos propios

Aunque compartan el mismo lenguaje visual.

---

Administrador

↓

Centro de Control

---

Cobrador

↓

Centro de Operaciones

---

Propietario

↓

Centro de Consulta

---

# Inicio de la aplicación

Splash

↓

Verificación de sesión

↓

Login

↓

Obtención del rol

↓

Carga del Dashboard correspondiente

Nunca mostrar un selector de rol.

El usuario entra directamente a su experiencia.

---

# Arquitectura del Administrador

El administrador tiene la experiencia más completa.

Su navegación principal será mediante Bottom Navigation.

## Módulos

### Inicio

Dashboard ejecutivo.

Indicadores.

Actividad reciente.

Acciones rápidas.

---

### Operaciones

Todo lo relacionado con el trabajo diario.

Incluye:

- Cobros
- Solicitudes de revisión
- Asignaciones
- Verificaciones
- Auditoría de pagos

Este módulo administra procesos.

No configura información.

---

### Comunidad

Toda la estructura del conjunto.

Aquí vive la jerarquía.

Conjunto

↓

Etapa

↓

Manzana

↓

Casa

↓

Propietario

La navegación siempre mantiene la jerarquía.

Nunca mostrar listas gigantes.

---

### Finanzas

Toda la información económica.

Incluye:

Balance mensual.

Balance anual.

Recaudo.

Mora.

Pagos.

Reportes.

Gráficos.

Exportaciones.

Este módulo responde preguntas.

No registra pagos.

---

### Perfil

Información personal.

Configuración.

Cerrar sesión.

Tema.

Notificaciones.

---

# Arquitectura del Cobrador

El cobrador trabaja caminando.

La aplicación debe minimizar desplazamientos entre pantallas.

## Módulos

### Inicio

Resumen de la jornada.

Cobros pendientes.

Cobros realizados.

Monto esperado.

Monto recaudado.

Botón

"Iniciar Jornada"

---

### Cobros

Lista de cobros programados.

Cada elemento abre la ficha del propietario.

Desde allí se registra el pago.

No existe un formulario independiente.

---

### Propietarios

Directorio.

Permite:

Buscar.

Filtrar.

Consultar.

Editar información permitida.

Registrar nuevos propietarios.

Nunca administrar pagos desde aquí.

---

### Registrar

Acceso rápido.

Puede abrir:

Registrar pago.

Registrar propietario.

Registrar vivienda.

Dependiendo de sus permisos.

Este módulo también puede representarse mediante un FAB permanente.

---

### Perfil

Información personal.

Estado de sincronización.

Configuración.

Cerrar sesión.

---

# Arquitectura del Propietario

El propietario consulta.

Nunca administra.

Nunca configura procesos.

## Módulos

### Inicio

Estado actual.

Próximo cobro.

Último pago.

Estado financiero.

Últimos movimientos.

---

### Historial

Timeline de pagos.

Máximo doce meses visibles.

Cada movimiento abre el Ticket Digital.

Nunca tablas.

---

### Solicitudes

Solicitudes enviadas.

Estado.

Historial.

Nueva solicitud de revisión.

---

### Perfil

Información personal.

Datos de contacto.

Configuración.

Cerrar sesión.

---

# Jerarquía de navegación

La aplicación siempre navega desde lo general hacia lo específico.

Ejemplo.

Dashboard

↓

Lista

↓

Detalle

↓

Acción

↓

Confirmación

Nunca al contrario.

---

# Jerarquía Territorial

La estructura territorial siempre será la misma.

Conjunto

↓

Etapa

↓

Manzana

↓

Casa

↓

Propietario

Nunca alterar este orden.

Todos los filtros deben respetarlo.

---

# Jerarquía Financiera

Periodo

↓

Cuotas

↓

Pago

↓

Ticket

↓

Auditoría

La auditoría únicamente existe para el administrador.

---

# Jerarquía Temporal

La aplicación siempre carga el período actual.

Ejemplo.

Agosto 2026

↓

Si el usuario cambia de período.

Toda la pantalla cambia.

Nunca únicamente una tarjeta.

La pantalla representa siempre un solo período.

---

# Dashboard

Todos los dashboards siguen la misma estructura.

## Nivel 1

Información principal.

---

## Nivel 2

Resumen.

---

## Nivel 3

Actividad.

---

## Nivel 4

Acciones rápidas.

---

Nunca mostrar módulos completos dentro del Dashboard.

---

# Detalles

Toda información detallada debe abrirse desde una tarjeta.

Nunca desde una tabla.

Las opciones preferidas son:

Bottom Sheet

↓

Pantalla secundaria

↓

Modal

En ese orden.

---

# Búsquedas

Las búsquedas tienen prioridad sobre la navegación.

Si un listado supera diez elementos.

Debe existir búsqueda.

Si supera veinte.

Debe existir búsqueda más filtros.

---

# Filtros

Todos los filtros siguen la misma jerarquía.

Periodo

↓

Conjunto

↓

Etapa

↓

Manzana

↓

Casa

↓

Propietario

Nunca invertir el orden.

---

# Información Histórica

Nunca cargar años completos.

Mostrar inicialmente.

Últimos movimientos.

↓

Últimos meses.

↓

Historial completo bajo demanda.

---

# Ticket Digital

Todo pago genera un Ticket Digital.

El ticket no se muestra automáticamente.

Se accede desde:

Timeline

↓

Pago

↓

Ticket

El Ticket es una vista.

No un PDF.

El PDF se genera únicamente cuando el usuario lo solicita.

Nunca almacenar PDFs.

---

# Solicitudes

Las solicitudes poseen un flujo independiente.

Pago

↓

Solicitar revisión

↓

Detalle

↓

Estado

↓

Resolución

Nunca modificar directamente el pago.

---

# Auditoría

La auditoría nunca forma parte del flujo normal.

Solo el administrador puede verla.

Ruta.

Pago

↓

Detalle

↓

Historial

↓

Versiones

↓

Auditoría

---

# Acciones Rápidas

Las acciones frecuentes deben permanecer accesibles.

Administrador

- Nuevo propietario
- Nuevo cobrador
- Nueva casa
- Registrar pago

---

Cobrador

- Registrar pago
- Registrar propietario
- Registrar vivienda

---

Propietario

No posee FAB.

No registra información crítica.

---

# Navegación

Siempre utilizar navegación inferior.

Nunca utilizar Drawer lateral como navegación principal.

El Drawer únicamente podrá utilizarse para herramientas secundarias si en el futuro fueran necesarias.

---

# Flujo Offline

El cobrador nunca pierde acceso al flujo principal.

Sin conexión.

↓

Registrar pago.

↓

Guardar localmente.

↓

Sincronizar automáticamente.

La experiencia debe ser idéntica online y offline.

---

# Estados Vacíos

Toda pantalla debe contemplar.

Sin resultados.

Sin pagos.

Sin propietarios.

Sin solicitudes.

Sin conexión.

Sin actividad.

Nunca mostrar una pantalla completamente vacía.

---

# Escalabilidad

La arquitectura debe permitir agregar nuevos módulos sin modificar la navegación existente.

Ejemplos futuros.

- Pagos por Nequi
- BRE-B
- WhatsApp
- IA
- Notificaciones Push
- Reserva de zonas comunes
- PQRS
- Correspondencia
- Visitantes

Todos estos módulos deberán integrarse respetando esta arquitectura.

---

# Regla Final

La arquitectura debe organizar el trabajo del usuario.

Nunca debe organizar la estructura del backend.

El usuario piensa en tareas.

No piensa en tablas.

Toda la aplicación debe construirse siguiendo esa premisa.
