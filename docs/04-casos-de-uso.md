# 04 — Casos de Uso

> **Propósito:** Los 6 casos de uso principales del sistema. Formato Cockburn simplificado: actores, pre/postcondiciones, flujo principal, alternativos y excepciones.

---

## CU-01: Registrar Pago (el más crítico — offline-first)

| Campo | Valor |
|---|---|
| **Actor primario** | Cobrador (también Admin) |
| **Actor secundario** | Sistema de Notificaciones (si la cuota queda saldada) |
| **Precondiciones** | Cobrador autenticado; existe al menos una cuota Pendiente/Vencida para el propietario |
| **Postcondiciones** | Pago persistido; cuota actualizada (Pagada/Parcial); auditoría registrada |

### Flujo principal

1. Cobrador abre "Registrar Pago".
2. Sistema muestra filtro por Etapa (solo las asignadas al cobrador).
3. Cobrador selecciona Etapa → lista de Casas.
4. Cobrador selecciona Casa → muestra propietario(s) y cuotas abiertas.
5. Cobrador selecciona cuota a pagar.
6. Sistema muestra los **montos predefinidos** disponibles (hasta 5).
7. Cobrador selecciona un monto.
8. Sistema confirma fecha (por defecto hoy) y monto.
9. Sistema valida: monto > 0, cuota no está ya Pagada.
10. Sistema guarda el pago en **SQLite local** con estado `PENDIENTE_SYNC`.
11. Sistema actualiza la cuota: si el monto cubre el saldo → `PAGADA`; si no → `PARCIAL` (el remanente se aplica FIFO a cuotas más antiguas).
12. Sistema muestra confirmación "Pago registrado".
13. Si hay conexión, dispara sincronización asíncrona al backend.

### Flujos alternativos

- **6a. Pago parcial FIFO:** Si el monto seleccionado es menor al saldo de la cuota, el sistema aplica el pago a la cuota más antigua con saldo pendiente y la deja como `PARCIAL`.
- **E2a. Propietario no encontrado:** El cobrador puede registrar un nuevo propietario desde el flujo de cobro (reutiliza HU-06), y luego continuar.

### Excepciones

- **E1.** Cuota ya pagada → sistema muestra error y ofrece ver historial.
- **E2.** Sin conexión → el paso 13 se omite; el pago queda en cola local.
- **E3.** Conflicto de sincronización (clientPaymentId duplicado) → se marca `CONFLICTO` y se notifica al Admin.

---

## CU-02: Configurar Tarifas de Pago

| Campo | Valor |
|---|---|
| **Actor primario** | Admin |
| **Precondiciones** | Admin autenticado |
| **Postcondiciones** | Tarifas actualizadas; nuevas cuotas usarán los nuevos valores |

### Flujo principal

1. Admin abre "Configuración → Tarifas".
2. Sistema muestra valores actuales (Semanal / Quincenal / Mensual).
3. Admin edita uno o más montos.
4. Sistema valida: montos > 0, en COP, sin decimales.
5. Admin confirma.
6. Sistema guarda nueva versión de tarifa con `fechaVigencia`.
7. Sistema informa: "Los cambios aplican a cuotas generadas desde hoy".

### Excepciones

- **E1.** Monto inválido → mensaje de validación, no se guarda.

---

## CU-03: Generación Automática de Cuotas (job)

| Campo | Valor |
|---|---|
| **Actor primario** | Sistema (disparador: cron diario) |
| **Precondiciones** | Tarifas configuradas; propietarios con frecuencia asignada |
| **Postcondiciones** | Cuotas del período creadas en estado Pendiente |

### Flujo principal

1. Cron dispara job a las 00:05.
2. Sistema lista propietarios con frecuencia activa.
3. Por cada propietario, calcula si corresponde generar cuota en la fecha actual según su frecuencia.
4. Crea cuota con monto = tarifa vigente en la fecha de generación, estado `PENDIENTE`, fechaVencimiento según frecuencia.
5. Persiste y registra log.

### Excepciones

- **E1.** Tarifa no configurada → propietario se omite y se registra alerta para Admin.

---

## CU-04: Notificar Vencimiento

| Campo | Valor |
|---|---|
| **Actor primario** | Sistema (disparador: cron diario posterior a CU-03) |
| **Actor secundario** | Servicio de Correo (adaptador) |
| **Precondiciones** | Cuotas en estado Vencido sin notificación enviada |
| **Postcondiciones** | Correos encolados/enviados; notificación marcada como enviada |

### Flujo principal

1. Cron lista cuotas Vencidas con `notificacionEnviada = false`.
2. Por cada una, sistema construye el correo (destinatario, monto, período).
3. Sistema invoca puerto `EmailSender.send()`.
4. Si éxito → marca `notificacionEnviada = true`.
5. Si fallo → incrementa contador de reintentos; si < 3, reencola con backoff; si ≥ 3, marca `notificacionFallida` para revisión.

### Detalle de reintentos

| Intento | Backoff | Ventana |
|---|---|---|
| 1 | 0 (inmediato) | — |
| 2 | 15 minutos | +15 min |
| 3 | 30 minutos | +45 min |
| Fin | Marcar como FALLIDA | Revisión manual |

---

## CU-05: Sincronización Offline → Backend

| Campo | Valor |
|---|---|
| **Actor primario** | Sistema (disparador: detección de conectividad) |
| **Precondiciones** | Pagos en cola local con estado `PENDIENTE_SYNC` |
| **Postcondiciones** | Pagos replicados en backend; cola local vacía o marcada |

### Flujo principal

1. Detector de red informa "conectado".
2. Sistema lee cola local ordenada por `fechaRegistro`.
3. Por cada pago, invoca `PagoRepository.sync(pago)` vía API REST.
4. Backend valida idempotencia (por `clientPaymentId`) y persiste.
5. Backend responde OK → sistema marca pago local como `SYNC_OK`.
6. Al finalizar, sistema actualiza estado de cuotas en local con la respuesta del servidor.

### Excepciones

- **E1.** Conflicto (pago ya registrado por otro dispositivo) → sistema marca local como `CONFLICTO` y notifica al Admin.
- **E2.** Error de red transitorio → reintento con backoff; se mantiene en cola.

---

## CU-06: Visualizar Cartera (Propietario)

| Campo | Valor |
|---|---|
| **Actor primario** | Propietario |
| **Precondiciones** | Propietario autenticado y vinculado a Usuario |
| **Postcondiciones** | Vista renderizada con calendario coloreado |

### Flujo principal

1. Propietario abre "Mi Cartera".
2. Sistema consulta cuotas del propietario ordenadas por período.
3. Sistema asigna color: Pagada=verde, Pendiente vigente=amarillo, Vencida=rojo.
4. Sistema muestra calendario mensual + lista detallada.
5. Propietario puede tocar un período para ver detalle (monto, fecha pago, cobrador).

---

## Mapa de Casos de Uso

```mermaid
flowchart LR
    subgraph Actores
        Admin(("👤 Admin"))
        Cobrador(("👤 Cobrador"))
        Propietario(("👤 Propietario"))
        Sistema(("⚙️ Sistema<br/>(cron/jobs)"))
    end

    subgraph SistemaUC["App de Control de Pagos"]
        UC1[/Configurar Conjunto, Etapas, Casas/]
        UC2[/Configurar Tarifas/]
        UC3[/Gestionar Usuarios y Roles/]
        UC4[/Registrar Propietario/]
        UC5[/Asignar Etapas a Cobrador/]
        UC6[/Registrar Pago/]
        UC7[/Buscar Propietario/]
        UC8[/Generar Cuotas Automáticas/]
        UC9[/Marcar Cuotas Vencidas/]
        UC10[/Enviar Notificación Correo/]
        UC11[/Visualizar Cartera Propia/]
        UC12[/Visualizar Cartera Consolidada/]
        UC13[/Generar Reporte de Recaudo/]
        UC14[/Sincronizar Pagos Offline/]
    end

    Admin --> UC1
    Admin --> UC2
    Admin --> UC3
    Admin --> UC4
    Admin --> UC5
    Admin --> UC6
    Admin --> UC13

    Cobrador --> UC4
    Cobrador --> UC6
    Cobrador --> UC7
    Cobrador --> UC12

    Propietario --> UC11

    Sistema --> UC8
    Sistema --> UC9
    Sistema --> UC10
    Sistema --> UC14

    UC6 -.include.-> UC7
    UC6 -.include.-> UC14
    UC9 -.include.-> UC10
    UC12 ..extend.-> UC5
```
