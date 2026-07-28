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

---

# Arquitectura de Dominio — Filosofía Cívica Pago (Motor de Recaudo)

> **Principio fundamental**
>
> Cívica Pago **no es un CRUD de propietarios**.
>
> Cívica Pago es un **Motor de Recaudo**.
>
> Todo el dominio existe para administrar correctamente el ciclo completo del recaudo.

---

# 1. Lenguaje Ubicuo (Ubiquitous Language)

Todo el sistema debe hablar exactamente el mismo idioma.

No importa si estamos en:

* Frontend
* Backend
* Base de datos
* API
* Documentación
* Diseño UI
* Dominio
* Equipo de desarrollo

Todos utilizan exactamente los mismos términos.

---

## Proyecto

Conjunto residencial administrado.

Ejemplo

> Urbanización San Sebastián

---

## Etapa

División principal del proyecto.

Ejemplo

> Etapa 1

---

## Manzana

Agrupación física de casas.

Ejemplo

> Manzana A

---

## Casa

Unidad física.

Es la pieza central del dominio físico.

Nunca "vivienda".

Nunca "unidad".

Siempre:

> Casa

Ejemplo

Casa 23

---

## Residente

Persona que actualmente ocupa una casa.

Puede ser

* Propietario
* Inquilino

El sistema no cobra personas.

El sistema cobra la obligación asociada a una casa ocupada.

---

## Modalidad de Pago

Define cómo se divide el recaudo mensual.

Puede ser

* Semanal
* Quincenal
* Mensual

---

## Mes de Cobro

Unidad principal del recaudo.

Todo comienza aquí.

Ejemplo

Julio 2026

Agosto 2026

Cada Mes de Cobro genera automáticamente sus cuotas.

---

## Cuota

División del cobro mensual.

Ejemplo

Julio

Pago 1

Pago 2

Pago 3

Pago 4

---

## Cobro

Es una obligación pendiente.

Existe antes del pago.

Lo utiliza principalmente el cobrador.

---

## Pago

Resultado de un cobro realizado.

Lo visualiza principalmente el residente.

---

## Solicitud

Evento generado por un usuario.

Ejemplos

Solicitud de Cobro

Solicitud de Revisión

---

## Actividad

Registro histórico del sistema.

Todo genera actividad.

---

# 2. Filosofía General

Todo gira alrededor del recaudo.

No alrededor del usuario.

No alrededor del CRUD.

No alrededor de las pantallas.

El dominio debe responder una sola pregunta.

> ¿Cómo garantizar que cada casa genere correctamente su recaudo?

Todo lo demás es consecuencia.

---

# 3. Jerarquía del Dominio

```
Proyecto

    ↓

Etapa

    ↓

Manzana

    ↓

Casa

    ↓

Residente

    ↓

Modalidad de Pago

    ↓

Mes de Cobro

    ↓

Cuotas

    ↓

Cobros

    ↓

Pagos

    ↓

Historial
```

Nunca al revés.

---

# 4. Ciclo de Vida del Recaudo

## Paso 1

Se crea una Casa.

Todavía no existe recaudo.

---

## Paso 2

Se asigna un Residente.

En ese momento comienza la obligación de recaudo.

---

## Paso 3

El sistema crea automáticamente

Mes de Cobro actual.

---

## Paso 4

Según la modalidad

Genera automáticamente las cuotas.

Ejemplo

Semanal

↓

4 cuotas

Quincenal

↓

2 cuotas

Mensual

↓

1 cuota

---

## Paso 5

Cada cuota obtiene

* fecha programada
* estado
* valor

---

## Paso 6

Las cuotas aparecen automáticamente en

Dashboard del Residente

Agenda del Cobrador

Dashboard del Administrador

---

## Paso 7

Cuando llega la fecha

La cuota entra en estado

Pendiente

---

## Paso 8

El cobrador registra el pago.

---

## Paso 9

El sistema actualiza automáticamente

Recaudo

Dashboard

Historial

Actividad

Reportes

Todo.

---

# 5. Estados de una Cuota

```
Programada

↓

Pendiente

↓

Solicitada

↓

En Cobro

↓

Pagada
```

o

```
Pendiente

↓

Vencida
```

o

```
Pendiente

↓

Pago Parcial

↓

Pagada
```

Nunca existen estados ambiguos.

---

# 6. Motor de Recaudo

Es el corazón del sistema.

Debe encargarse de

## Generación automática

Crear cuotas.

---

## Calendario

Calcular fechas.

---

## Estados

Actualizar automáticamente.

---

## Mora

Detectar vencimientos.

---

## Pago parcial

Aceptar abonos.

---

## Pago completo

Cerrar cuota.

---

## Pago superior

Distribuir automáticamente.

Ejemplo

Cuota vale

20.000

Usuario paga

40.000

↓

Paga cuota actual

↓

Abona siguiente cuota.

---

Usuario paga

25.000

↓

20.000

↓

Cuota pagada

↓

5.000

↓

Abono siguiente cuota.

---

Usuario paga

15.000

↓

Cuota continúa abierta

↓

Saldo pendiente

5.000

---

# 7. Motor de Agenda

El cobrador nunca busca propietarios.

Trabaja por territorio.

Siempre.

Orden

```
Etapa

↓

Manzana

↓

Casa
```

Nunca

Propietario

↓

Casa

---

La agenda organiza automáticamente

* Cobros pendientes
* Cobros vencidos
* Solicitudes de cobro

Todo ordenado por ruta.

---

# 8. Responsabilidad por Rol

## Residente

Responsabilidad

Administrar su obligación.

Visualiza

* Próximas cuotas
* Historial
* Solicitudes
* Estado del recaudo

Puede

Solicitar cobro.

Solicitar revisión.

Actualizar datos personales permitidos.

---

## Cobrador

Responsabilidad

Administrar el recaudo.

Visualiza

* Agenda
* Casas
* Estado del recaudo
* Solicitudes

Puede

Registrar pago.

Registrar abono.

Consultar información básica del residente.

Generar observaciones.

No puede

Eliminar pagos.

Modificar cuotas.

Cambiar modalidad.

---

## Administrador

Responsabilidad

Administrar todo el ecosistema.

Puede

Crear proyectos.

Crear etapas.

Crear manzanas.

Crear casas.

Asignar residentes.

Administrar cobradores.

Administrar modalidades.

Resolver solicitudes.

Consultar actividades.

Generar reportes.

Nunca realiza el recaudo.

Supervisa el recaudo.

---

# 9. Arquitectura de Eventos

Todo genera un evento.

Ejemplos

```
Casa creada

↓

Residente asignado

↓

Cuotas generadas

↓

Solicitud creada

↓

Cobro registrado

↓

Pago registrado

↓

Pago revisado

↓

Cuota vencida

↓

Modalidad actualizada

↓

Residente cambiado
```

Los eventos alimentan

* Actividad
* Dashboard
* Reportes
* Notificaciones
* Auditoría

---

# 10. Dashboards

Los dashboards nunca administran.

Solo resumen información.

---

## Dashboard Residente

Debe responder

¿Cuánto debo?

¿Qué sigue?

¿Qué pagué?

---

Widgets

* Estado del recaudo
* Próximas cuotas
* Últimos pagos
* Solicitudes activas

---

## Dashboard Cobrador

Debe responder

¿Qué debo cobrar hoy?

Widgets

* Meta del mes
* Recaudo actual
* Cobros pendientes
* Cobros vencidos
* Solicitudes nuevas
* Ruta del día

---

## Dashboard Administrador

Debe responder

¿Cómo va el recaudo general?

Widgets

* Meta mensual
* Recaudo actual
* Porcentaje alcanzado
* Casas activas
* Casas con mora
* Solicitudes
* Actividad reciente

---

# 11. UI basada en el dominio

La interfaz no se diseña alrededor de pantallas.

Se diseña alrededor del flujo de recaudo.

Cada pantalla responde una pregunta del usuario.

**Residente**

* ¿Qué debo pagar?
* ¿Cuándo vence?
* ¿Qué ya pagué?
* ¿Necesito solicitar un cobro o revisar un pago?

**Cobrador**

* ¿Qué casas debo visitar?
* ¿Cuál es mi ruta?
* ¿Qué pagos debo registrar?
* ¿Qué solicitudes debo atender?

**Administrador**

* ¿Cómo va el recaudo?
* ¿Qué requiere atención?
* ¿Dónde hay mora?
* ¿Qué solicitudes están pendientes?

---

# 12. Componentes reutilizables de UI

Toda la aplicación debe reutilizar componentes consistentes alineados con el dominio:

* **KPI Card** (meta, recaudo, mora, progreso).
* **Card de Casa** (Etapa → Manzana → Casa, residente y estado).
* **Card de Cuota** (mes, número de cuota, valor, vencimiento y estado).
* **Card de Pago** (detalle del pago, cobrador, comprobante y acciones).
* **Timeline** de actividades.
* **Lista de Solicitudes**.
* **Filtros** por Etapa, Manzana y estado.
* **Indicadores de estado** (Programada, Pendiente, En Cobro, Pagada, Parcial, Vencida).
* **Bottom Sheets** para acciones rápidas (Registrar pago, Solicitar cobro, Solicitar revisión).

---

# 13. Principios que nunca deben romperse

1. El **motor de recaudo** es el núcleo del sistema.
2. El lenguaje ubicuo debe ser el mismo en frontend, backend, base de datos y documentación.
3. La **Casa** es el centro físico del dominio; el residente puede cambiar, la casa permanece.
4. Todo residente asignado a una casa activa entra automáticamente al ciclo de recaudo.
5. Toda cuota pertenece a un **Mes de Cobro**.
6. Todo pago nace de un cobro.
7. Todo evento deja trazabilidad.
8. Los dashboards informan; los módulos gestionan.
9. Los roles se diferencian por responsabilidades, no por duplicar funcionalidades.
10. La UI debe priorizar rapidez, claridad y eficiencia para el recaudo, manteniendo un diseño moderno, consistente y orientado a la productividad del usuario.
