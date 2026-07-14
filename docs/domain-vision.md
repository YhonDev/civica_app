# Domain Vision: Sistema Inteligente de Gestion de Recauda Residencial

> El sistema administra el recaudo de una comunidad residencial. Cada vivienda activa genera automaticamente un ciclo de cobro segun su modalidad de recaudo. Los propietarios o residentes gestionan sus obligaciones, los cobradores ejecutan el recaudo y el administrador supervisa y controla todo el proceso. El recaudo es el eje central de la aplicacion; los pagos son unicamente la evidencia de que un cobro fue atendido.

---

## Principio fundamental

**La vivienda es la entidad permanente del sistema.**

- La casa nunca cambia.
- Los residentes (propietarios/inquilinos) cambian.
- El historial queda atado a la casa, no a la persona.

---

## Flujo del dominio

```
Casa
  |
  Residente (Propietario/Inquilino)
  |
  Modalidad de recaudo
  |
  Periodo de recaudo
  |
  Cobros programados
  |
  Pago registrado
  |
  Ticket
```

El pago aparece al final porque el sistema vive de los cobros.

---

## La modalidad NO cambia el valor mensual

La modalidad unicamente cambia el calendario de cobro.

| Modalidad | Cobros por mes | Monto por cobro | Total mensual |
|-----------|----------------|-----------------|---------------|
| SEMANAL | 4 | $10.000 | $40.000 |
| QUINCENAL | 2 | $20.000 | $40.000 |
| MENSUAL | 1 | $40.000 | $40.000 |

La deuda mensual siempre es **$40.000**.

---

## Ciclo automatico de recaudo

Cuando una casa adquiere un residente:

1. Se asigna la modalidad de recaudo.
2. Se activa el ciclo de recaudo.
3. Se genera el calendario de cobros automaticamente.
4. Los cobros aparecen en el dashboard del cobrador y del propietario.

Ningun administrador debe crear cobros manualmente.

---

## Meta de recaudo

El dashboard del administrador muestra **metas**, no listas de pagos.

```
Meta del mes:    $4.000.000
Recaudado:       $2.850.000
Porcentaje:      71%
```

**Como se calcula la meta:**

```
Casas activas
  -> Residentes activos
    -> Monto mensual por modalidad
      -> Meta mensual total
```

Ejemplo: 3 casas activas x $40.000 = $120.000 meta mensual.

---

## Vocabulario del sistema

### Entidades

| Entidad | Descripcion |
|---------|-------------|
| Casa | Vivienda permanente en el conjunto. Nunca se elimina. |
| Residente | Persona que habita la casa actualmente (propietario o inquilino). |
| Modalidad de recaudo | Frecuencia de cobro: SEMANAL, QUINCENAL o MENSUAL. |
| Periodo | Mes/año del ciclo de recaudo. |
| Cobro | Obligacion de pago generada automaticamente para un periodo. |
| Pago | Evidencia de que un cobro fue atendido. |
| Ticket | Comprobante generado al registrar un pago. |
| Visita de cobro | Solicitud del residente para que un cobrador pase por la vivienda. |

### Dashboards

| Rol | Lenguaje correcto |
|-----|-------------------|
| Administrador | Meta de recaudo, recaudado, pendiente, casas al dia, casas con mora, solicitudes de visita |
| Cobrador | Visitas pendientes, cobros solicitados, cobros vencidos, pagos en revision |
| Propietario | Proximos cobros, historial de cobros, solicitar visita de cobro |

### Acciones

| Incorrecto | Correcto |
|------------|----------|
| Solicitar cobro | Solicitar visita de cobro |
| Proximos pagos | Proximos cobros |
| Solicitudes | Visitas pendientes |
| Pagos realizados | Meta de recaudo vs Recaudado |

---

## Modelo de entidades

```
Casa (permanente)
  |
  Tenencia (residente activo)
  |
  CuentaCartera (modalidad asignada)
  |
  Cobro (generado por periodo)
  |
  Pago (evidencia de cumplimiento)
  |
  Ticket (comprobante)
```

---

## Dashboard del propietario

```
Proximos cobros
──────────────
Julio - Cobro 3        $10.000
Vence: 26 Julio        Pendiente
[Ver detalle]

Julio - Cobro 4        $10.000
Vence: 2 Agosto        Pendiente
[Ver detalle]
```

Detalle del cobro:
- Cobro / Monto / Fecha / Estado / Modalidad / Observaciones
- Boton unico: **Solicitar visita de cobro**

---

## Dashboard del cobrador

```
Visitas pendientes
──────────────
Casa 15   Solicito visita   Hace 10 minutos
Casa 22   Cobro vence manana
Casa 10   Pago en revision
```

---

## Dashboard del administrador

```
Meta del mes           $4.000.000
Recaudado              $2.850.000  (71%)
Pendiente              $1.150.000

Casas al dia           84
Casas con mora         12
Solicitudes de revision   4
Solicitudes de visita    7
```
