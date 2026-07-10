# VigiVecino — Role Experience & Dashboards

> Cada rol abre la app con una pregunta distinta.
> Cada dashboard está diseñado para responder esa pregunta en menos de 10 segundos.
>
> Este documento fusiona dos guías previas: `ROLE_DASHBOARDS.md` (versión
> resumida) y la especificación completa de experiencia por rol.

---

## Filosofía Central

| Rol         | Pregunta                              | El dashboard es...               |
|-------------|---------------------------------------|----------------------------------|
| Propietario | ¿Cómo está mi cuenta y qué debo hacer? | Un **estado de cuenta**         |
| Cobrador    | ¿Qué viviendas debo visitar hoy?      | Una **agenda de trabajo**        |
| Administrador | ¿Cómo está el conjunto y qué requiere atención? | Un **panel ejecutivo**    |

Los tres dashboards comparten el mismo lenguaje visual (colores, tipografía,
tarjetas, animaciones), pero cada uno se siente diseñado específicamente
para su usuario.

---

# 1. Experiencia del Administrador

## Objetivo

El administrador abre la aplicación para conocer el estado del conjunto y
tomar decisiones. Nunca para llenar formularios. Nunca para navegar entre
listas enormes.

Su Dashboard debe responder tres preguntas:

1. ¿Cómo va el recaudo?
2. ¿Qué necesita atención?
3. ¿Qué ocurrió hoy?

## Primera impresión

Después del login debe aparecer inmediatamente el **Dashboard Ejecutivo**.
No listas. No tablas. No CRUD. Debe sentirse como un Centro de Control.

## Dashboard

### 1. Selector de período
- Siempre inicia mostrando el período actual (ej. `Agosto 2026`).
- Al tocar: Bottom Sheet para cambiar de mes (nunca DatePicker).
- Al cambiar el período: **toda la pantalla se actualiza**, no solo una tarjeta.

### 2. Tarjeta Principal
- **Recaudo del mes**: monto recaudado, % de cumplimiento, progreso visual.
- Ocupa el mayor protagonismo visual. No más números innecesarios.

### 3. Indicadores rápidos (4 tarjetas pequeñas)
- Propietarios al día
- Propietarios pendientes
- Valor en mora
- Solicitudes abiertas / cobros del día

### 4. Actividad reciente
- Feed con los últimos 5 eventos (no más).
- Ej: "Carlos registró un pago · hace 5 min".

### 5. Acciones rápidas
- Nuevo Propietario
- Nuevo Cobrador
- Nueva Vivienda
- Registrar Pago
- Ver Reportes

## Qué NO debe mostrar el Dashboard

- CRUD completos
- Tablas
- Listados enormes
- Configuraciones
- Auditoría (eso es módulo aparte)

## Flujo mental

Observa → Analiza → Decide → Actúa. La app debe seguir exactamente ese flujo.

## Layout (referencia visual)

```
┌────────────────────────────────────────┐
│  Agosto 2026                    ▼      │  ← Selector de mes (chip)
├────────────────────────────────────────┤
│  ┌────────────────────────────────┐    │
│  │  Recaudo del Mes               │    │  ← Tarjeta principal
│  │  $12.580.000                   │    │
│  │  ████████████████░░ 82%        │    │
│  │  82% de la meta mensual        │    │
│  └────────────────────────────────┘    │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐  │
│  │  ✔ 184  │ │  ⚠ 23   │ │  💰 $2.3M│  │  ← Mini indicadores
│  │ Pagaron │ │ Pend.   │ │ Mora    │  │
│  └─────────┘ └─────────┘ └─────────┘  │
│  ┌────────────────────────────────┐    │
│  │  📈 Evolución del recaudo     │    │  ← Gráfico de línea
│  └────────────────────────────────┘    │
│  ┌──────────────┐ ┌──────────────┐    │
│  │  📊 Estado   │ │  📌 Cobros   │    │  ← Modalidades + Donut
│  │  Mensual 82% │ │  Pagados 82% │    │
│  │  Quincen 91% │ │  Pend.   14% │    │
│  │  Semanal 76% │ │  Revis.   4% │    │
│  └──────────────┘ └──────────────┘    │
│  ┌────────────────────────────────┐    │
│  │  ⚡ Actividad reciente         │    │  ← Timeline feed
│  └────────────────────────────────┘    │
│  ┌────────────────────────────────┐    │
│  │  ＋ Nuevo Propietario          │    │  ← Acciones rápidas
│  │  ＋ Registrar Pago             │    │
│  │  ＋ Crear Cobrador             │    │
│  │  Ver Reportes ›                │    │
│  └────────────────────────────────┘    │
└────────────────────────────────────────┘
```

### Comportamiento del selector de mes
- Por defecto: mes actual.
- Chips `◄ Agosto 2026 ►` para navegar.
- Al tocar: Bottom Sheet con lista de meses del año.

### Dashboard ≠ Reportes

| Dashboard                | Reportes                                    |
|--------------------------|---------------------------------------------|
| ¿Cómo vamos?            | Muéstrame todos los pagos de febrero        |
| Visualización ejecutiva  | Filtros, tablas, exportar                   |
| KPIs y gráficos simples  | Excel, PDF, imprimir                        |
| Una sola pregunta        | Búsqueda avanzada                           |

Son módulos separados. El dashboard es para decidir. Los reportes para investigar.

---

# 2. Experiencia del Cobrador

## Objetivo

El cobrador trabaja caminando. Cada segundo cuenta. Su aplicación es una
herramienta de trabajo, no un sistema administrativo.

## Primera impresión

Después del login debe aparecer **Mi Jornada**. Nunca estadísticas complejas.

## Dashboard

Debe mostrar:
- Saludo (buenos días, nombre)
- Fecha
- Estado de conexión (online/offline)

Después:
- Cobros pendientes / realizados
- Monto esperado / recaudado

Después:
- Botón principal: **Iniciar Jornada** (o **Continuar Jornada** si ya inició)

Después:
- Lista de cobros del día: cada tarjeta es una vivienda
  (Nombre, Casa, Etapa, Modalidad, Estado, Botón Cobrar, Botón Ver).

## Registrar Pago (≤ 15 segundos)
Pantalla mínima con: Propietario, Casa, Valor sugerido, Método, Observaciones,
botón **Registrar**. Al registrar → animación breve → ticket → volver.

## Registrar Propietario (asistente)
Paso 1: Info personal → Paso 2: Ubicación → Paso 3: Modalidad → Paso 4: Resumen.

## Consulta de Propietario
Nombre, Documento, Teléfono, Correo, Conjunto, Etapa, Manzana, Casa,
Modalidad, Estado. Acciones rápidas: Llamar, WhatsApp, Editar datos, Registrar pago.

> **Nunca** debe visualizar la auditoría, eliminar pagos ni acceder a reportes
> financieros.

## Experiencia Offline
La app debe comportarse igual con o sin Internet. El cobrador nunca debe
preocuparse por la sincronización — eso es responsabilidad del sistema.

## Flujo mental

Buscar → Cobrar → Registrar → Continuar. Todo debe sentirse extremadamente rápido.

## Layout (referencia visual)

```
┌────────────────────────────────────────┐
│  Buenos días, Carlos                   │
│  Jueves, 10 de agosto                  │
├────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐        │
│  │  📋 12      │ │  💰 $4.2M   │        │
│  │  Cobros     │ │  Esperado   │        │
│  └─────────────┘ └─────────────┘        │
│  ┌────────────────────────────────┐    │
│  │  ▶  Iniciar Jornada            │    │  ← Acción principal
│  └────────────────────────────────┘    │
│  ┌────────────────────────────────┐    │
│  │  Casa 101 — Juan Pérez         │    │
│  │  $40.000  ● Pendiente          │    │
│  ├────────────────────────────────┤    │
│  │  Casa 102 — María García       │    │
│  │  $40.000  ● Pendiente          │    │
│  └────────────────────────────────┘    │
│                          [＋ FAB]       │  ← Registrar pago/propietario
└────────────────────────────────────────┘
```

---

# 3. Experiencia del Propietario

## Objetivo

El propietario únicamente desea saber cómo está su vivienda. No administra.
No registra pagos. No configura procesos. Solo **consulta**.

## Primera impresión

Después del login debe aparecer **Mi Estado**. No un menú, no un listado.

## Dashboard

### Tarjeta Principal (protagonismo)
- Nombre, Casa, Conjunto, Estado (`Al día` / `Pendiente` / `En Mora`).

### Próximo Cobro (o Último Pago)
- Si hay cuota pendiente: Fecha, Valor, Modalidad, Estado.
- Si no: mostrar último pago realizado. **Nunca ambas tarjetas a la vez.**

### Últimos Movimientos
- Solo los **dos últimos**. Cada uno abre el Ticket Digital.

### Solicitudes
- Cantidad, Estado, acceso para crear nueva.

## Historial
- Timeline (nunca tablas). Cada elemento = un período. Click → Ticket.
- Máximo 12 meses visibles + botón "Ver más".

## Ticket Digital
- Se abre como Bottom Sheet. Contiene: Número, Fecha, Hora, Propietario,
  Casa, Valor, Método, Estado, Cobrador, botón Cerrar.
- PDF solo bajo demanda (futuro).

## Solicitud de Revisión
- Flujo: Seleccionar pago → Solicitar revisión → Describir → Enviar.
- El propietario **nunca** confirma, modifica ni rechaza un pago.

## Flujo mental

Consultar → Entender → Solicitar ayuda si es necesario. Nunca más.

## Layout (referencia visual)

```
┌────────────────────────────────────────┐
│  Hola, Juan                            │
│  Casa 101 — Etapa 1                    │
├────────────────────────────────────────┤
│  ┌────────────────────────────────┐    │
│  │  🟢  AL DÍA                    │    │  ← Estado principal
│  │  Saldo actual: $0              │    │
│  │  Próximo cobro: 01/09/2026     │    │
│  └────────────────────────────────┘    │
│  ┌────────────────────────────────┐    │
│  │  Últimos movimientos           │    │  ← Timeline comprimido
│  │  10/08  Pago recibido  $40.000 │    │
│  │  01/08  Cuota mensual  $40.000 │    │
│  │                       Ver todos ›│    │
│  └────────────────────────────────┘    │
│  ┌────────────────────────────────┐    │
│  │  💬 Solicitudes                │    │
│  │  Revisión de cargo — Pendiente │    │
│  └────────────────────────────────┘    │
└────────────────────────────────────────┘
```

---

# 4. Navegación General

```
Bottom Navigation (siempre visible):

  Home        │  Cobro         │  Cuenta      │  Más
  (rol)       │  (hoy)         │  (mío)       │
  ────────────┴────────────────┴──────────────┘

Para Admin:
  Dashboard   │  Cartera       │  Propiet.    │  Más

Para Cobrador:
  Jornada     │  Cobrar        │              │  Más

Para Propietario:
  Mi Estado   │  Pagar         │              │  Más
```

---

# 5. Lo que NO va en ningún dashboard

- ❌ Tablas de datos
- ❌ Listas interminables
- ❌ Filtros complejos
- ❌ Exportar datos
- ❌ Edición en línea
- ❌ Reportes detallados

Todo eso pertenece a **módulos específicos** (Cartera, Reportes,
Propietarios, etc.), no al dashboard.

---

# 6. Acciones principales por rol

| Rol           | Acciones                                                               |
|---------------|------------------------------------------------------------------------|
| Administrador | Analizar · Administrar · Supervisar · Auditar                          |
| Cobrador      | Cobrar · Registrar · Consultar · Actualizar                            |
| Propietario   | Consultar · Visualizar · Solicitar revisión                            |

---

# 7. Regla de Oro

Cada rol debe sentir que la aplicación fue diseñada **exclusivamente** para él.

Si un usuario ve funciones que nunca utilizará, la experiencia está mal diseñada.

La mejor interfaz no es la que muestra más opciones. Es la que muestra
únicamente las opciones correctas en el momento correcto.
