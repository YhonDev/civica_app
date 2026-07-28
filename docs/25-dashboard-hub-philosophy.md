# VigiVecino
# Dashboard & Module Philosophy

Version 1.0

---

# Visión General

VigiVecino no es una aplicación compuesta por muchas pantallas independientes.

Es un conjunto de módulos especializados.

Cada módulo tiene una responsabilidad específica.

El Dashboard no intenta reemplazar esos módulos.

Su única función es resumir el estado del sistema y dirigir al usuario hacia el módulo correcto.

La aplicación debe sentirse como un Centro de Operaciones y no como una colección de pantallas.

---

# Filosofía Principal

Cada módulo contiene la lógica completa.

El Dashboard solamente consume pequeños resúmenes de cada módulo.

Nunca debe mostrar toda la información.

Debe mostrar únicamente el contexto suficiente para responder una pregunta y permitir que el usuario tome una decisión.

Cada tarjeta representa la entrada a un módulo completo.

Nunca una funcionalidad completa.

---

# Flujo Mental del Administrador

Cuando el administrador abre la aplicación debe responder estas preguntas, en este orden.

1. ¿Cómo está la comunidad hoy?

2. ¿Qué requiere atención inmediata?

3. ¿Qué ocurrió recientemente?

4. ¿Qué acción puedo realizar ahora?

5. ¿En qué módulo debo profundizar?

Toda la estructura del Dashboard debe seguir este flujo.

---

# Filosofía del Dashboard

El Dashboard es una colección de mini dashboards. (Actúa como un **Hub de Decisiones**)

Cada tarjeta resume únicamente una pequeña parte de un módulo.

Ejemplo

Dashboard

↓

Resumen de Pagos

↓

Resumen de Reportes

↓

Resumen de Propietarios

↓

Resumen de Solicitudes

↓

Resumen de Comunidad

↓

Actividad Reciente

↓

Acciones Rápidas

Nunca mostrar el módulo completo.

Siempre mostrar únicamente un resumen.

---

# Filosofía de las Tarjetas

Cada tarjeta actúa como una **ventana inteligente** hacia un módulo y responde únicamente tres preguntas.

¿Cuál es el estado actual?

¿Qué requiere atención?

¿Cómo entro al módulo correspondiente?

Nunca intentar resolver completamente una funcionalidad dentro del Dashboard.

Ejemplo

Cobros

42 pendientes

31 en mora

Gestionar Cobros →

No mostrar listas completas.

No mostrar filtros.

No mostrar tablas.

Eso pertenece al módulo.

---

# Filosofía de Navegación

Toda tarjeta del Dashboard debe dirigir exactamente al lugar donde vive esa información.

Nunca abrir una pantalla genérica.

Siempre abrir el módulo ya contextualizado.

Ejemplos

42 propietarios pendientes

↓

Abrir módulo Cobros

↓

Filtro Estado = Pendiente

--------------------

31 propietarios en mora

↓

Abrir módulo Cobros

↓

Filtro Estado = Mora

--------------------

84 % de recaudo

↓

Abrir módulo Reportes

↓

Período = Mes actual

--------------------

Actividad de hoy

↓

Abrir Historial

↓

Filtro = Hoy

La navegación siempre conserva el contexto.

---

# Filosofía de los Módulos

Todos los módulos (Lugares donde se trabaja) siguen exactamente la misma estructura.

Resumen

↓

Información principal

↓

Herramientas de análisis

↓

Filtros

↓

Detalle

↓

Acciones

Nunca comenzar una pantalla mostrando filtros.

Primero mostrar información útil.

Después permitir modificar la vista.

---

# Estado Inicial Inteligente

Todos los módulos deben mostrar información útil apenas el usuario entra.

Nunca iniciar con una pantalla vacía esperando que el usuario configure filtros.

Ejemplo

Dashboard

Siempre muestra el estado actual.

Reportes

Siempre muestra el período actual.

Cobros

Siempre muestra los cobros pendientes del período actual.

Solicitudes

Siempre muestra las solicitudes pendientes.

Propietarios

Siempre muestra todos los propietarios activos.

El usuario puede cambiar posteriormente esa vista.

---

# Filosofía de los Reportes

El módulo Reportes es el lugar donde vive el análisis completo del sistema.

El Dashboard únicamente muestra un pequeño resumen.

Dentro de Reportes se puede profundizar completamente.

La estructura recomendada es.

Resumen General

↓

Indicadores

↓

Gráfico Principal

↓

Distribuciones

↓

Comparativas

↓

Tablas

↓

Filtros Avanzados

↓

Exportar

El Dashboard nunca debe competir con este módulo.

---

# Manejo de Períodos

Todo módulo que trabaja con tiempo debe tener un período predeterminado.

Reporte Mensual

Mostrar siempre el mes actual.

Reporte Semanal

Mostrar siempre la semana actual.

Reporte Anual

Mostrar siempre el año actual.

Después el usuario puede cambiar el período mediante filtros.

Nunca obligar al usuario a configurar filtros antes de ver información.

---

# Alcance de los Filtros

Los filtros deben afectar únicamente al módulo donde fueron aplicados.

Ejemplo

Si el usuario cambia el mes dentro de Reportes.

Solo cambia Reportes.

El Dashboard continúa mostrando información del período actual.

Los demás módulos conservan su propio contexto.

Cada módulo mantiene su independencia.

---

# Filosofía de la Información

Toda la aplicación trabaja por niveles.

Nivel 1

Estado General.

Nivel 2

Información que requiere atención.

Nivel 3

Actividad reciente.

Nivel 4

Análisis.

Nivel 5

Histórico.

Nunca mostrar información histórica antes de mostrar el estado actual.

---

# Dashboard del Administrador (Hub de Decisiones)

El Dashboard del Administrador representa el estado completo de la comunidad.

No representa módulos.

Representa decisiones.

Debe permitir comprender la situación completa en menos de cinco segundos.

Su estructura es.

Hero Principal

↓

Indicadores

↓

Casos que requieren atención

↓

Actividad reciente

↓

Acciones rápidas

↓

Resumen de módulos

Cada sección dirige al módulo correspondiente.

Nunca intenta reemplazarlo.

---

# Filosofía del Desarrollo

La aplicación se desarrolla comenzando por la experiencia del usuario.

Primero se construyen las pantallas utilizando datos simulados.

Se valida completamente la experiencia de navegación, los flujos y la organización visual.

Una vez aprobada la experiencia, se conecta el backend.

El backend debe adaptarse a la experiencia diseñada y no al contrario.

De esta manera la arquitectura técnica respeta la experiencia del usuario desde el inicio.

---

# Objetivo Final

El usuario nunca debe sentir que navega entre pantallas independientes.

Debe sentir que toda la aplicación es un único sistema conectado.

Cada módulo tiene una responsabilidad.

Cada tarjeta resume un módulo.

Cada clic lleva exactamente al lugar donde esa información vive.

El Dashboard no reemplaza la aplicación.

El Dashboard es la puerta de entrada al sistema completo.
