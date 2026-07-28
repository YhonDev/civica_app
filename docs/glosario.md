# Glosario — Lenguaje Ubicuo (Motor de Recaudo)

> **Propósito:** Vocabulario compartido entre frontend, backend, base de datos, diseño UI, dominio y equipo de desarrollo. Todo el sistema debe hablar exactamente este idioma.

---

## A

### Actividad
Registro histórico del sistema. Todo genera actividad para alimentar dashboards, historial y auditoría.

### Administrador
Rol que supervisa el recaudo y administra todo el ecosistema. Puede crear proyectos, etapas, manzanas, casas, asignar residentes, administrar cobradores y modalidades. Resuelve solicitudes. Nunca realiza el recaudo directamente.

---

## C

### Casa
Unidad física, pieza central del dominio físico. Pertenece a una `Manzana`. Nunca "vivienda", nunca "unidad", siempre "Casa". (Ej: Casa 23).

### Cobrador
Rol responsable de administrar el recaudo en territorio. Trabaja por territorio (Etapa → Manzana → Casa), no buscando propietarios. Ve agenda, casas, estado del recaudo y solicitudes. Registra pagos y abonos.

### Cobro
Obligación pendiente. Existe antes del pago. Es gestionado y visualizado principalmente por el cobrador.

### Cuota
División del cobro mensual. Generada automáticamente por el sistema según la `Modalidad de Pago` a partir de un `Mes de Cobro`. Tiene fecha programada, estado y valor.

---

## E

### Estados de una Cuota
- **Programada**: Creada para el futuro, aún no es exigible.
- **Pendiente**: Cuota vigente que ha llegado a su fecha de cobro.
- **Solicitada**: El residente solicitó cobro o revisión.
- **En Cobro**: El cobrador está gestionando el pago.
- **Pago Parcial**: Cuota con abono que aún tiene saldo pendiente.
- **Pagada**: Cuota totalmente cancelada (cierra la cuota).
- **Vencida**: Cuota cuya fecha límite pasó sin pago completo.

### Etapa
División principal de un `Proyecto`. Agrupa `Manzana`s. (Ej: Etapa 1).

---

## M

### Manzana
Agrupación física de casas dentro de una `Etapa`. (Ej: Manzana A).

### Mes de Cobro
Unidad principal del recaudo. Todo comienza aquí (ej: Julio 2026). Cada Mes de Cobro genera automáticamente sus cuotas asociadas.

### Modalidad de Pago
Define cómo se divide el recaudo mensual. Puede ser:
- `SEMANAL` (4 cuotas)
- `QUINCENAL` (2 cuotas)
- `MENSUAL` (1 cuota)

---

## P

### Pago
Resultado de un cobro realizado. Lo visualiza principalmente el residente. Cancela total o parcialmente una `Cuota`. Si el pago es superior, el excedente abona automáticamente la siguiente cuota.

### Proyecto
Conjunto residencial administrado. Entidad raíz del sistema. (Ej: Urbanización San Sebastián).

---

## R

### Residente
Persona que actualmente ocupa una `Casa` (Propietario o Inquilino). En el momento de su asignación, comienza la obligación de recaudo para esa casa. El sistema cobra la obligación de la casa ocupada, no a la persona.

---

## S

### Solicitud
Evento generado por un usuario (ej: Solicitud de Cobro, Solicitud de Revisión). Atendido por cobradores o el administrador.

---

## T

### Tenencia
Relación temporal entre un `Residente` y una `Casa`.

---

## Jerarquía del Dominio Físico y Financiero

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
