# App de Control de Pagos y Cartera para Conjuntos Residenciales

> **Estado:** En planificación (pre-MVP)
> **Versión:** 3.0 — 10 de julio de 2026

---

## ¿Qué es esto?

Una app **mobile-first** (Flutter) con backend en **NestJS** para que conjuntos residenciales puedan:

- **Gestionar** sus propietarios, etapas constructivas, y casas/unidades.
- **Controlar** el cobro de cuotas periódicas (semanal, quincenal, mensual) **offline-first**.
- **Visualizar** la cartera en tiempo real: pagado (🟢), pendiente (🟡), vencido (🔴).
- **Notificar** vencimientos automáticamente por correo.

Pensada para cobradores que recorren el conjunto casa por casa, muchas veces sin conexión a Internet.

---

## Stack Tecnológico

| Capa | Tecnología | Justificación |
|---|---|---|
| **Backend** | NestJS (Node 20 LTS) | TypeScript, arquitectura modular, compatible con hexagonal |
| **Base de datos** | PostgreSQL (Supabase) | RLS para multi-tenant, gratis en MVP |
| **App móvil** | Flutter + BLoC | Una sola base de código Android/iOS, offline-first con SQLite |
| **Cache / Colas** | Redis (Upstash) | Cola de notificaciones con reintentos |
| **Correo** | Resend / SendGrid | Hasta 3000 correos/mes gratis |

---

## Cómo navegar la documentación

```
doc/
├── README.md              ← ESTE ARCHIVO — punto de entrada
├── 01-vision.md           ← Problema, solución, alcance, actores
├── 02-supuestos.md        ← Decisiones de diseño (preguntas abiertas resueltas)
├── 03-historias-usuario.md ← 22 HU organizadas por épica
├── 04-casos-de-uso.md     ← 6 CU con flujos principales y alternativos
├── 05-arquitectura.md     ← Hexagonal + DDD, C4, mapa de módulos
├── 06-modelo-dominio.md   ← Bounded Contexts, agregados, VOs, invariantes
├── 07-interfaces.md       ← Puertos entrantes y salientes (TypeScript)
├── 08-eventos.md          ← Eventos de dominio y handlers
├── 09-estrategias.md      ← Offline sync, idempotencia, multi-tenant
├── 10-despliegue.md       ← Diagrama de despliegue, infraestructura
├── 11-adrs.md             ← Architecture Decision Records
├── 12-trazabilidad.md     ← Matriz HU ↔ CU ↔ Requisitos
├── glosario.md            ← Lenguaje ubicuo del dominio
└── diagramas/             ← Diagramas Mermaid autocontenidos
    ├── casos-de-uso.mmd
    ├── clases-dominio.mmd
    ├── bounded-contexts.mmd
    ├── secuencia-pago.mmd
    ├── estados-cuota.mmd
    ├── c4-contexto.mmd
    ├── modulos-nest.mmd
    ├── eventos.mmd
    └── despliegue.mmd
```

---

## Enlaces rápidos

| Si eres... | Empieza por... |
|---|---|
| **Nuevo developer** | `01-vision.md` → `glosario.md` → `05-arquitectura.md` |
| **Frontend/Flutter** | `04-casos-de-uso.md` → `09-estrategias.md` (offline sync) |
| **Backend** | `05-arquitectura.md` → `06-modelo-dominio.md` → `07-interfaces.md` |
| **Product Owner / QA** | `03-historias-usuario.md` → `04-casos-de-uso.md` → `12-trazabilidad.md` |
| **DevOps** | `10-despliegue.md` |
| **Todos** | `11-adrs.md` (decisiones de arquitectura) |

---

## Estados del proyecto

- [x] **Fase 1:** Requerimientos y visión
- [x] **Fase 2:** Casos de uso, historias de usuario, diagramas
- [x] **Fase 3:** Arquitectura hexagonal + DDD (puertos, agregados, eventos)
- [ ] **Fase 4:** Plan de sprints y roadmap
- [ ] **Fase 5:** Implementación MVP
- [ ] **Fase 6:** Tests y despliegue

---

## Licencia

Uso interno — propiedad del conjunto residencial.
