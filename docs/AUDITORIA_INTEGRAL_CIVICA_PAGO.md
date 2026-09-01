# Auditoría Técnica Integral y Diagnóstico Arquitectónico
## Cívica Pago — Motor de Recaudo Comunitario

**Fecha:** 1 de Septiembre de 2026  
**Perfil Auditor:** Senior Software Architect  
**Alcance:** Frontend (Flutter), Backend (NestJS / TypeORM), Base de Datos (PostgreSQL), Dominio y Documentación.

---

## 1. Resumen Ejecutivo & Scorecard General

| Dimensión | Calificación | Diagnóstico Sintético |
| :--- | :---: | :--- |
| **Arquitectura de Dominio** | **8.5 / 10** | Excelente alineación conceptual con el *Motor de Recaudo* (FIFO, cuotas, tenencia). Inconsistencias menores en nomenclaturas residuales (`propietarios` vs `residentes`). |
| **Diseño Frontend (Flutter)** | **7.0 / 10** | UI pulida y componentes modulares, pero presencia de carpetas duplicadas/muertas (`features/dashboard_propietario`, `screens/cobro`) y 211 errores de compilación en la suite de tests. |
| **Diseño Backend (NestJS)** | **9.0 / 10** | Arquitectura limpia/hexagonal bien delimitada, control de transacciones con `PESSIMISTIC_WRITE`, mappers, CQRS y rate limiting. 1 test unitario desactualizado. |
| **Base de Datos & Modelo** | **8.5 / 10** | Modelo relacional robusto con índices apropiados y constraint de idempotencia (`tenant_id, client_payment_id`). Desacoplamiento deliberado de FKs en TypeORM vs PostgreSQL. |
| **Higiene del Repositorio** | **6.5 / 10** | Carpetas duplicadas a nivel raíz (`doc/` vs `docs/`), carpetas vacías (`supabase/snippets`, `ui_actual/cobrador`), y scripts SQL dispersos en la raíz del backend. |

---

## 2. Adherencia al Dominio & Lenguaje Ubicuo

### 2.1. Filosofía del Motor de Recaudo vs CRUD
El sistema respeta el axioma fundamental: **Cívica Pago no es un CRUD de personas, es un Motor de Recaudo donde la unidad física central es la Casa.**

* **Jerarquía Real del Dominio:**  
  `Proyecto` → `Etapa` → `Manzana` → `Casa` → `Residente` → `Modalidad de Pago` → `Mes de Cobro` → `Cuotas` → `Cobros` → `Pagos` → `Historial`.
* **Mecanismo de Pago FIFO:** El backend implementa correctamente la distribución secuencial de fondos sobre cuotas pendientes (`RegistrarPagoUseCase` y `revertirAbonos`).
* **Offline-First:** Sincronización bidireccional local (Drift SQLite en móvil) hacia PostgreSQL con claves de idempotencia (`clientPaymentId`).

### 2.2. Brechas de Lenguaje Ubicuo Detectadas
1. **Directorio `doc/` vs `docs/`:**  
   - `doc/` contiene especificaciones desactualizadas que aún hablan de `Conjunto`, `Propietario` y `CuentaDeCartera`.
   - `docs/` contiene el glosario y esquema actualizados (`Proyecto`, `Residente`, `Casa`, `Mes de Cobro`).
2. **Rol en `usuarios` vs Modelo:**  
   - En el backend (`schema.sql` y `usuario.entity.ts`), el CHECK de roles incluye `'PROPIETARIO'` y `'RESIDENTE'` simultáneamente. Se debe unificar a `'RESIDENTE'`.

---

## 3. Inventario de Archivos Basura, Huérfanos y Código Muerto

### 3.1. Nivel Raíz y Documentación
* ❌ **`doc/` (Carpeta completa - 29 archivos):** Es un clon desactualizado de `docs/`. Debe consolidarse o eliminarse a favor de `docs/`.
* ❌ **`supabase/snippets/`:** Directorio vacío sin uso activo.
* ❌ **`ui_actual/cobrador/` y `ui_actual/residente/`:** Carpetas vacías en el árbol de capturas.

### 3.2. Frontend (`apps/mobile/lib`)
* ❌ **`lib/features/dashboard_propietario/` (Carpeta completa):**  
  Contiene `mi_estado_screen.dart`, `residente_dashboard_screen.dart` y `timeline_paged_list.dart`. Es código huérfano y duplicado de `lib/features/dashboard_residente/`.
* ❌ **`lib/features/mas/`:**  
  Contiene `configuracion_screen.dart` y `mas_screen.dart`. La ruta `/mas` en `app_router.dart` ya redirige a `/configuracion`, dejando esta carpeta redundante con `lib/features/configuracion/`.
* ❌ **`lib/screens/cobro/` (`payment_screen.dart` y `bloc.dart`):**  
  Módulo legacy previo al refactor a `features/cartera/`. No es importado por `app_router.dart`.
* ❌ **`lib/screens/` (Estructura de carpetas):**  
  Actualmente solo contiene `auth/` y el legacy `cobro/`. Para cumplir con la arquitectura *Feature-First / Screaming Architecture*, `screens/auth` debe ser movido a `features/auth/`.
* ❌ **`lib/shared/widgets/cartera_calendar.dart`:**  
  Widget huérfano. La vista de calendario activa reside en `features/cartera/widgets/calendar_view.dart`.
* ❌ **Duplicación de `CobroCard`:**  
  Existen dos componentes con el mismo nombre y propósitos solapados:
  - `lib/features/cartera/widgets/cobro_card.dart` (Usa `CobroItem`)
  - `lib/shared/widgets/cobro_card.dart` (Usa tipos primitivos y solo lo usa `historial_screen.dart`).

### 3.3. Backend (`apps/backend`)
* ⚠️ **Scripts SQL dispersos en raíz de backend:**  
  `cleanup-old-data.sql`, `fix-seed-data.sql` y `seed-cloud.sql` están en la raíz de `apps/backend/` en lugar de estar organizados dentro de `apps/backend/database/`.
* ⚠️ **`apps/docs/MIGRATION-ANALYSIS.md`:** Documento histórico de migración que pertenece al histórico de documentación central `docs/archive/`.

---

## 4. Análisis de Errores y Smells Arquitectónicos

### 4.1. Frontend (Flutter)
1. **Tests Rotos por Refactor Incompleto (211 errores en `flutter analyze`):**  
   Los archivos de prueba en `test/unit/` (`propietarios_models_test.dart`, `propietarios_repository_test.dart`, `cobradores_repository_test.dart`, `propetario_dashboard_screen_test.dart`) intentan importar rutas y clases inexistentes (`features/propietarios/...`). La suite de tests quedó rota tras renombrar a `residentes`.
2. **Inconsistencia en el Paso de Parámetros en Router:**  
   En `app_router.dart`, varias rutas leen `state.extra` esperando un tipo concreto (ej. `state.extra as ResidenteItem`), lo que produce un crash en runtime si el usuario recarga la app en web o deep link sin estado en memoria. Debe utilizarse paso de ID por path/query params con carga reactiva o fallback seguro.
3. **Manejo de Estado del Dashboard Hub:**  
   La filosofía establece que las tarjetas del dashboard son *ventanas inteligentes* que transfieren al usuario al módulo con el filtro preaplicado. Ciertas tarjetas navegan a rutas genéricas perdiendo el contexto del filtro (ej. Mora vs Pendientes).

### 4.2. Backend (NestJS & TypeORM)
1. **Fallo en Suite de Tests Unitarios (`dashboard.query.spec.ts`):**  
   El test `should map actividad items with usuario and timestamp` falla porque la consulta devolvió la propiedad `metadata: {}` y el matcher `toEqual` esperaba el objeto sin `metadata`.
2. **Manejo de Excedentes en Pagos (`RegistrarPagoUseCase`):**  
   Si un residente paga un valor mayor a su deuda total o anticipa pagos cuando no se han generado cuotas futuras, el sistema lanza `BadRequestException` ("No hay cobros pendientes"). Según el modelo de dominio, un pago superior debe abonar cuotas futuras o generar un saldo a favor en la casa/residente.
3. **Desacoplamiento de Claves Foráneas (FK Constraints):**  
   Las entidades de TypeORM tienen `createForeignKeyConstraints: false` en relaciones como `Tenencia.casa_id` y `Cobro.residente_id`, mientras que `schema.sql` sí define restricciones relacionales. Si la base de datos se recrea vía TypeORM en testing o desarrollo, se pierden las protecciones de integridad referencial.
4. **Cron Jobs sin Bloqueo Distribuido:**  
   `GenerarCobrosJob`, `MarcarVencidasJob` y `PurgaSolicitudesJob` corren con `@Cron` de NestJS en memoria. Si el backend se despliega en múltiples instancias (horizontal scaling), los jobs se ejecutarán concurrentemente N veces generando duplicidad o contención de bloqueos.

---

## 5. Rendimiento & Oportunidades de Optimización

### 5.1. Backend & Base de Datos
1. **Optimización N+1 en Consultas de Cartera:**  
   En `cartera-vivienda-resumen.query.ts` y `dashboard.query.ts`, la agregación de saldos por casa y manzana puede optimizarse aprovechando la vista SQL `vista_cartera_por_casa` ya existente en `schema.sql`, reduciendo el número de joins en memoria.
2. **Índices y Particionado:**  
   La tabla `actividad` y `pagos` crecerán rápidamente en un conjunto grande. `idx_actividad_tenant_created` es adecuado, pero se recomienda particionado por rango de fechas (`created_at`) si el volumen supera 1M de registros.
3. **Pessimistic Locking Seguro:**  
   El uso de `findMasAntiguoConSaldoLocked` en `RegistrarPagoUseCase` es una excelente decisión para evitar race conditions en pagos simultáneos offline/online.

### 5.2. Frontend (Flutter)
1. **Batching en Sincronización Offline (`SyncService`):**  
   Actualmente la sincronización envía registros de forma secuencial. Debe implementarse un endpoint de subida en lote (`POST /pagos/batch-sync`) para sincronizar 50+ pagos en una sola petición HTTP cuando el cobrador recupera señal.
2. **Rebuilds Innecesarios en Listas Largas:**  
   En pantallas con listados de casas/residentes (`casas_explorer_screen.dart`), asegurar que los items usen `const Key` e instanciación dentro de `ListView.builder` para evitar retención de memoria.

---

## 6. Plan de Acción y Hoja de Ruta Priorizada

### Fase 1: Limpieza No Destructiva & Higiene (Completado ✅)
- [x] Eliminar la carpeta obsoleta `doc/` y conservar `docs/` como única fuente de verdad.
- [x] Eliminar código muerto en frontend: `features/dashboard_propietario/`, `features/mas/`, `screens/cobro/`, `shared/widgets/cartera_calendar.dart`.
- [x] Reubicar `screens/auth/` a `features/auth/` para completar la arquitectura *Feature-First* (con imports actualizados).
- [x] Mover scripts SQL sueltos de `apps/backend/` hacia `apps/backend/database/scripts/`.
- [x] Archivar `apps/docs/MIGRATION-ANALYSIS.md` en `docs/archive/` y remover carpetas vacías (`ui_actual/cobrador`, `ui_actual/residente`).

### Fase 2: Corrección de Tests & Estabilidad (Prioridad Alta)
- [ ] Actualizar el test `dashboard.query.spec.ts` en el backend para incluir `metadata: {}` (logrando 100% test pass rate en NestJS).
- [ ] Actualizar / migrar la suite de tests de Flutter en `test/unit/` y `test/widgets/` hacia los nuevos modelos de `residentes`, eliminando referencias rotas a `propietarios`.
- [ ] Unificar el componente `CobroCard` en un único widget reutilizable bajo `shared/widgets/` o `features/cartera/widgets/`.

### Fase 3: Robustez de Dominio & Rendimiento (Prioridad Media)
- [ ] Implementar soporte de anticipos o generación de cuotas futuras ante pagos con saldo excedente en `RegistrarPagoUseCase`.
- [ ] Implementar endpoint y lógica de sincronización por lotes (`batch-sync`) en cobros offline.
- [ ] Incorporar `pg_advisory_lock` en los cron jobs de NestJS para despliegues multi-instancia.
