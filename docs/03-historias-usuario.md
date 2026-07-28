# 03 — Historias de Usuario

> **Propósito:** 22 historias de usuario organizadas por Épica y por Rol, con criterios de aceptación (Given/When/Then) para testeabilidad directa.

---

## Épica E1 — Configuración del Conjunto (Admin)

### HU-01: Crear Conjunto
**Como** Admin, **quiero** crear y nombrar el Conjunto residencial, **para** tener una entidad raíz donde organizar etapas y casas.

**Criterios de aceptación:**
- **Given** que estoy autenticado como Admin
- **When** creo un conjunto con nombre "Portal del Prado"
- **Then** el conjunto queda registrado y visible en el panel principal

### HU-02: Crear Etapas
**Como** Admin, **quiero** crear Etapas dentro del Conjunto, **para** agrupar casas por fases constructivas.

**Criterios de aceptación:**
- **Given** que existe un Conjunto
- **When** creo la Etapa "Etapa 1 - Manzana A"
- **Then** la etapa queda asociada al conjunto y aparece en el árbol de navegación

### HU-03: Registrar Casas
**Como** Admin, **quiero** registrar Casas/Unidades dentro de una Etapa, **para** poder asignarlas a propietarios.

**Criterios de aceptación:**
- **Given** que existe una Etapa
- **When** registro la casa "Casa 15" con dirección interna
- **Then** la casa queda disponible para asignación

### HU-04: Definir Tarifas
**Como** Admin, **quiero** definir las tarifas de pago (monto por frecuencia), **para** establecer cuánto debe pagar cada propietario según su modalidad.

**Criterios de aceptación:**
- **Given** que soy Admin
- **When** configuro Semanal=$10.000, Quincenal=$20.000, Mensual=$40.000
- **Then** los valores quedan guardados y se usan para generar cuotas futuras

### HU-05: Editar Tarifas
**Como** Admin, **quiero** editar las tarifas, **para** ajustar montos ante cambios económicos, sin afectar cuotas ya generadas.

**Criterios de aceptación:**
- **Given** que ya existen cuotas generadas con la tarifa anterior
- **When** cambio la tarifa mensual a $45.000
- **Then** las cuotas futuras usan el nuevo valor y las existentes conservan el valor original

### HU-05b: Configurar Montos Predefinidos
**Como** Admin, **quiero** configurar hasta 5 montos predefinidos de pago, **para** que el cobrador pueda seleccionar montos controlados sin digitación manual.

**Criterios de aceptación:**
- **Given** que soy Admin del conjunto
- **When** configuro 3 montos: $10.000, $20.000 y $30.000
- **Then** los montos quedan disponibles para el cobrador al registrar pagos
- **And** si intento agregar un sexto monto, el sistema lo rechaza con mensaje "Máximo 5 montos activos"

---

## Épica E2 — Gestión de Propietarios y Usuarios

### HU-06: Registrar Propietario
**Como** Admin o Cobrador, **quiero** registrar un nuevo propietario con nombre, teléfono, correo y ubicación (Etapa+Casa), **para** incorporarlo al sistema.

**Criterios de aceptación:**
- **Given** que estoy en la pantalla de registro
- **When** ingreso los datos y asigno una Casa
- **Then** el propietario queda creado y asociado a la casa

### HU-07: Múltiples Casas por Propietario
**Como** Admin o Cobrador, **quiero** asignar varias Casas a un mismo propietario, **para** reflejar el caso de un dueño con múltiples unidades.

**Criterios de aceptación:**
- **Given** que el propietario "Juan Pérez" ya existe
- **When** le asigno además la Casa 22
- **Then** Juan aparece vinculado a ambas casas

### HU-08: Crear Usuarios con Roles
**Como** Admin, **quiero** crear usuarios y asignarles un rol (Admin / Cobrador / Propietario), **para** controlar el acceso al sistema.

**Criterios de aceptación:**
- **Given** que soy Admin
- **When** creo el usuario "cobrador1" con rol Cobrador
- **Then** el usuario puede iniciar sesión con los permisos de su rol

### HU-09: Vincular Usuario a Propietario
**Como** Admin, **quiero** vincular un Usuario a un Propietario existente, **para** que el propietario pueda acceder a la app y ver su estado de cartera.

**Criterios de aceptación:**
- **Given** que el propietario ya existe pero no tiene usuario
- **When** le creo credenciales y lo vinculo
- **Then** el propietario puede iniciar sesión y ver solo su información

### HU-10: Asignar Etapas a Cobrador
**Como** Admin, **quiero** asignar Etapas específicas a un Cobrador, **para** limitar su alcance operativo.

**Criterios de aceptación:**
- **Given** que el cobrador "Ana" existe
- **When** le asigno las Etapas 1 y 3
- **Then** Ana solo ve propietarios de esas etapas

---

## Épica E3 — Generación Automática de Cuotas

### HU-11: Generar Cuota por Período
**Como** sistema, **quiero** generar automáticamente una cuota por cada propietario al inicio de cada periodo según su frecuencia, **para** tener la cartera siempre actualizada.

**Criterios de aceptación:**
- **Given** un propietario con frecuencia semanal y tarifa $10.000
- **When** inicia una nueva semana
- **Then** se crea una cuota Pendiente por $10.000 con fecha de vencimiento al final de la semana

### HU-12: Marcar Cuotas Vencidas
**Como** sistema, **quiero** marcar automáticamente como Vencida toda cuota Pendiente cuya fecha límite haya pasado sin pago, **para** disparar la notificación.

**Criterios de aceptación:**
- **Given** una cuota con vencimiento ayer y sin pago
- **When** corre el job nocturno
- **Then** la cuota pasa a estado Vencida y se encola un correo al propietario

---

## Épica E4 — Registro de Pagos

### HU-13: Buscar Propietario
**Como** Cobrador, **quiero** buscar un propietario por Etapa y Casa, **para** localizar rápidamente a quién cobrar.

**Criterios de aceptación:**
- **Given** que estoy en la pantalla de cobro
- **When** filtro por Etapa 1 y Casa 15
- **Then** aparece solo el/los propietario(s) de esa casa

### HU-14: Registrar Pago (con montos predefinidos)
**Como** Cobrador, **quiero** registrar un pago seleccionando uno de los montos predefinidos, **para** digitalizar el recibo físico con control y transparencia.

**Criterios de aceptación:**
- **Given** que seleccioné un propietario y una cuota Pendiente
- **When** selecciono el monto $10.000 de la lista de montos predefinidos y confirmo
- **Then** la cuota se actualiza (Pendiente→Pagada o→Parcial según el monto) y el pago queda auditado con mi usuario
- **And** el pago queda guardado en SQLite local (sync pendiente)

### HU-15: Pago Offline
**Como** Cobrador, **quiero** registrar pagos sin conexión a Internet, **para** no perder cobros hechos en zonas sin señal.

**Criterios de aceptación:**
- **Given** que el dispositivo está offline
- **When** registro un pago
- **Then** el pago queda en cola local (SQLite) y se sincroniza automáticamente al recuperar conexión

### HU-16: Sincronización Automática
**Como** sistema, **quiero** sincronizar la cola de pagos pendientes cuando haya conexión, **para** mantener la base central consistente.

**Criterios de aceptación:**
- **Given** que existen 3 pagos en cola local
- **When** el dispositivo detecta conexión
- **Then** los 3 pagos se envían al backend, se confirman y se eliminan de la cola local

### HU-17: Trazabilidad de Pagos
**Como** Admin, **quiero** ver quién registró cada pago y cuándo, **para** tener trazabilidad y resolver disputas.

**Criterios de aceptación:**
- **Given** un pago registrado
- **When** consulto su detalle
- **Then** veo usuario cobrador, fecha/hora de registro y fecha/hora de sincronización

### HU-17b: Registrar Propietario Inline en Cobro
**Como** Cobrador, **quiero** crear un nuevo propietario durante el flujo de cobro si no lo encuentro, **para** atender a recién mudados o personas sin acceso tecnológico.

**Criterios de aceptación:**
- **Given** que busco un propietario por Casa y no existe
- **When** selecciono "Registrar nuevo propietario" y completo nombre, teléfono y email
- **Then** el propietario queda creado y asociado a la casa, y puedo continuar con el cobro

---

## Épica E5 — Visualización de Cartera

### HU-18: Cartera del Propietario (Calendario)
**Como** Propietario, **quiero** ver un calendario mensual con mis cuotas en verde/amarillo/rojo, **para** conocer de un vistazo mi estado de pago.

**Criterios de aceptación:**
- **Given** que inicié sesión como propietario
- **When** abro la vista de cartera
- **Then** veo cada periodo con color según estado (Pagado=verde, Pendiente=amarillo, Vencido=rojo)

### HU-19: Cartera Consolidada (Admin/Cobrador)
**Como** Admin o Cobrador, **quiero** ver la cartera consolidada de los propietarios de mis etapas asignadas, **para** identificar morosos rápidamente.

**Criterios de aceptación:**
- **Given** que soy cobrador con Etapas 1 y 3 asignadas
- **When** abro el panel de cartera
- **Then** veo el estado de todos los propietarios de esas etapas, con filtros por estado

### HU-20: Reporte de Recaudo
**Como** Admin, **quiero** generar un reporte de recaudo por período, **para** tomar decisiones administrativas.

**Criterios de aceptación:**
- **Given** que selecciono el rango "julio 2026"
- **When** genero el reporte
- **Then** obtengo totales (pagado, pendiente, vencido) y detalle por propietario, exportable a PDF/CSV

---

## Épica E6 — Notificaciones

### HU-21: Notificar Vencimiento por Correo
**Como** Propietario, **quiero** recibir un correo cuando una cuota mía venza sin pago, **para** regularizar a tiempo.

**Criterios de aceptación:**
- **Given** una cuota pasó a Vencida
- **When** el job de notificaciones procesa la cola
- **Then** llega un correo al propietario con monto, período vencido e instrucciones de pago

### HU-22: Reintento de Notificación
**Como** sistema, **quiero** reintentar el envío de correo si falla, **para** garantizar la entrega.

**Criterios de aceptación:**
- **Given** que el primer intento de envío falló
- **When** pasan 15 minutos
- **Then** se reintenta hasta 3 veces con backoff exponencial
- **And** si falla, se marca como "notificación pendiente" para revisión manual
