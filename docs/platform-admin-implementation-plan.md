# Plan de implementación — Administrador de plataforma

## 1. Resultado del análisis de los seis ciclos

Los seis ciclos revisados están integrados en las ramas `dev` y `main`:

1. Observabilidad HTTP y métricas básicas.
2. Rebranding y metadatos de Cuentiva.
3. Crash reporting de la aplicación móvil.
4. Ciclo de vida de sesión y adaptación responsive.
5. Matriz de autorización y aislamiento multi-tenant.
6. Optimización de consultas, rendimiento móvil, migraciones resilientes y resolución explícita de roles.

La base actual está preparada para continuar: las pruebas unitarias del backend pasan (59 suites, 494 tests), el chequeo TypeScript pasa, Flutter Analyze no reporta issues y la suite móvil pasa (377 tests).

### Pendientes operativos que no deben confundirse con el nuevo módulo

- El checklist post-despliegue todavía registra login y smoke test de producción bloqueados por la falta de un ADMIN productivo.
- Deben completarse fuera del código la rotación de secretos, la revisión de credenciales seed y la confirmación de `JWT_SECRET`, `JWT_REFRESH_SECRET` y `CORS_ORIGIN`.
- Logs, métricas y backups están disponibles como capacidades de operación, pero todavía no forman un centro de operaciones dentro de la aplicación.

## 2. Decisión de producto y arquitectura

Se crearán dos superficies separadas:

### Administración operativa (`ADMIN`)

Administra una comunidad/tenant: residentes, cobradores, proyectos, etapas, tarifas, cobros, solicitudes, reportes y configuración del proyecto. Conserva sus pantallas y permisos actuales.

### Administración de plataforma (`SUPERADMIN` o `PLATFORM_ADMIN`)

Administra Cuentiva como producto: tenants, proyectos y su ciclo de vida, usuarios administradores, salud de servicios, despliegues, incidentes, logs y auditoría. No debe heredar automáticamente permisos financieros u operativos de cada tenant.

La opción recomendada es el nombre interno `PLATFORM_ADMIN`, manteniendo `SUPERADMIN` como alias de migración si ya existen tokens o datos con ese valor. La UI puede mostrar **Administrador de plataforma**.

La interfaz reutilizará los tokens de diseño, navegación, tarjetas, tablas, estados, filtros y componentes existentes. No se reutilizará la navegación operacional ni se añadirá el administrador de plataforma como una variante oculta del dashboard de comunidad.

## 3. Brechas que deben resolverse antes de construir pantallas

1. **Identidad:** agregar el rol de plataforma al enum y a la estrategia JWT del backend; definir permisos explícitos y evitar que un `PLATFORM_ADMIN` sea tratado como `ADMIN`.
2. **Modelo multi-tenant:** crear una entidad `tenants` con estado, plan, límites, contacto, fechas de alta/baja y metadatos. Actualmente `tenant_id` existe como referencia, pero no existe un agregado de plataforma para gestionarlo.
3. **Relación proyecto-tenant:** mantener la relación actual y agregar validaciones de estado para impedir operaciones sobre tenants suspendidos o archivados.
4. **Auditoría durable:** convertir las acciones administrativas críticas en eventos persistentes con actor, tenant afectado, acción, recurso, resultado, request ID, IP cuando corresponda y timestamp. El timeline actual de actividad no sustituye una auditoría de plataforma.
5. **Observabilidad durable:** conservar métricas de proceso para diagnóstico, pero añadir almacenamiento/consulta de logs y métricas agregadas con retención, paginación y filtros. No exponer el stream de logs crudos a usuarios finales.
6. **Despliegues:** definir una fuente de verdad para releases y despliegues (GitHub Actions/Render u otro proveedor), con estado, commit, ambiente, inicio, fin, actor, resultado y URL externa. El panel no debe fingir que puede desplegar si no existe un adaptador real.
7. **Frontend:** crear un shell/rutas protegidas exclusivas para `PLATFORM_ADMIN`; el cliente tenant-only debe mostrar acceso no autorizado o redirigir a la consola web de plataforma, nunca renderizar un dashboard de comunidad.

## 4. Módulos funcionales propuestos

### A. Centro de control

- Estado global de API, base de datos, Redis, colas y proveedores externos.
- Tenants activos, suspendidos, en mantenimiento y con errores recientes.
- Salud de los últimos despliegues.
- Tasa de errores, latencia p50/p95/p99 y endpoints lentos.
- Alertas accionables con severidad, responsable, estado y enlace al incidente.

### B. Tenants y proyectos

- Alta, edición, suspensión, reactivación y archivado reversible de tenants.
- Datos de contacto, plan, límites, zona horaria y configuración de facturación si aplica.
- Inventario de proyectos por tenant y estado operacional.
- Modo mantenimiento con motivo, ventana temporal y mensaje visible.
- Vista de consumo: usuarios, viviendas, cobros, almacenamiento y volumen de solicitudes.
- Acceso de soporte con alcance temporal y auditoría; no usar suplantación silenciosa.

### C. Administradores y acceso

- Crear, activar, desactivar y revocar sesiones de administradores de tenant.
- Asignar alcance de tenant sin modificar directamente el rol operativo.
- MFA, recuperación segura, expiración de sesiones y sesiones activas.
- Matriz de permisos separada para plataforma, soporte de solo lectura y operaciones.
- Registro de cada cambio de privilegios y exportación controlada de auditoría.

### D. Despliegues y releases

- Lista de ambientes y despliegues con commit, versión, actor y resultado.
- Detalle de checks CI, migraciones ejecutadas y smoke test.
- Acción de solicitar/reintentar despliegue mediante un adaptador autorizado.
- Promoción entre ambientes con confirmación y control de concurrencia.
- Rollback únicamente mediante una operación explícita, reversible y auditada.
- Enlace al proveedor externo para logs de build; no duplicar secretos ni credenciales.

### E. Logs, auditoría e incidentes

- Búsqueda por request ID, tenant, usuario, ruta, status, severidad y rango de tiempo.
- Vista de auditoría inmutable para acciones administrativas.
- Correlación entre error, despliegue, tenant y request.
- Creación y seguimiento de incidentes: detectado, investigando, mitigado, resuelto.
- Exportación con límites, redacción de secretos y permisos de soporte.
- Retención y purga configurables; prohibido almacenar contraseñas, tokens o cuerpos sensibles.

### F. Configuración y políticas de plataforma

- Flags de funcionalidades por tenant o ambiente.
- Límites de rate, cuotas y ventanas de mantenimiento.
- Configuración de notificaciones operativas.
- Políticas de retención, backup, restauración y rollback.
- Catálogo de integraciones y estado de credenciales sin mostrar valores secretos.

## 5. Plan de implementación por fases

### Fase 0 — Contrato y diseño

- Aprobar nombre del rol, alcance de soporte y ambientes administrables.
- Definir contratos OpenAPI, estados, permisos y modelo de amenazas.
- Identificar qué acciones son solo lectura y cuáles requieren doble confirmación.
- Diseñar wireframes usando el sistema visual actual, con consola desktop-first y adaptación tablet.

**Salida:** ADR, matriz de permisos, esquema de datos y contratos API aprobados.

### Fase 1 — Fundaciones de identidad y tenancy

- Migración `tenants` y estados de ciclo de vida.
- Rol `PLATFORM_ADMIN` y permisos explícitos en backend.
- Guards de alcance: plataforma, tenant seleccionado y soporte temporal.
- Auditoría de cambios de rol, tenant y estado.
- Pruebas de aislamiento: un administrador de plataforma puede consultar el inventario permitido, pero un admin operativo no puede cruzar tenants.

**Salida:** autenticación y autorización de plataforma sin UI compleja.

### Fase 2 — API de plataforma

- `GET /platform/overview`.
- CRUD de `/platform/tenants` y acciones de suspensión/reactivación/mantenimiento.
- `/platform/administrators`, sesiones y revocación.
- `/platform/audit` con filtros y cursor.
- `/platform/health`, `/platform/metrics` y `/platform/logs` con paginación.
- `/platform/deployments` conectado al proveedor mediante una interfaz de adaptador.

Todos los endpoints deben declarar roles, validar UUID/DTOs, aplicar límites, filtrar secretos y escribir auditoría para mutaciones.

### Fase 3 — Consola de administración

- Nuevo shell de plataforma y navegación propia.
- Centro de control, tenants, administradores, despliegues, logs/auditoría e incidentes.
- Componentes reutilizables: `StatusBadge`, `KpiCard`, filtros, tablas, timeline, banners de mantenimiento y estados vacíos.
- Guardas de ruta y pruebas de que ningún usuario operativo puede entrar por URL directa.

### Fase 4 — Operación real y despliegues

- Integrar proveedor de despliegue y enlaces de CI.
- Alertas y notificaciones operativas.
- Acciones de rollback con confirmación, permisos elevados y post-check automático.
- Backups, restauración y pruebas de recuperación documentadas.
- Retención, redacción y acceso controlado a logs.

### Fase 5 — Endurecimiento y salida

- Pruebas E2E multi-tenant y pruebas negativas de autorización.
- Pruebas de carga de listados, logs y métricas.
- Revisión de accesibilidad y responsive.
- Smoke test de plataforma en CI y post-deploy.
- Runbook de incidentes actualizado con responsables y tiempos objetivo.
- Activación progresiva por feature flag; no habilitar despliegues/rollback hasta validar el adaptador real.

## 6. Criterios de aceptación

- Ningún `ADMIN`, `COBRADOR` o `RESIDENTE` puede acceder a rutas o datos de plataforma.
- Ningún `PLATFORM_ADMIN` obtiene por accidente permisos financieros de un tenant.
- Toda mutación de plataforma genera un registro de auditoría consultable.
- Un tenant suspendido bloquea las operaciones definidas por política y conserva trazabilidad.
- El panel diferencia estado observado, acción solicitada y resultado confirmado.
- Los logs no exponen tokens, contraseñas, hashes, cookies ni secretos de proveedores.
- Despliegue y rollback muestran la fuente externa, el commit y el resultado real.
- La consola funciona en desktop/tablet y mantiene los tokens del sistema de diseño.
- CI cubre autorización, aislamiento, auditoría, contratos API y pruebas de widgets/rutas.

## 7. Fuera de alcance inicial

- Facturación comercial de Cuentiva.
- Edición directa de datos financieros de una comunidad desde la consola de plataforma.
- Suplantación permanente de usuarios.
- Reemplazar Render, GitHub Actions, PostgreSQL o el proveedor de logs por una implementación propia.
- Mostrar logs crudos sin redacción ni retención.

## 8. Orden recomendado de ejecución

No se debe empezar por las pantallas. El orden seguro es:

1. Contrato de permisos y modelo `tenants`.
2. Rol, guards, auditoría y pruebas negativas.
3. API de inventario/estado.
4. Consola de solo lectura.
5. Mutaciones de tenant y administradores.
6. Integración de logs, incidentes y despliegues.
7. Acciones de rollback y automatización operativa.

Así se reutiliza la UI existente sin convertir el dashboard de comunidad en un panel ambiguo ni introducir un `SUPERADMIN` únicamente visual.
