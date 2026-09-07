# Changelog — Cívica Pago

## v0.1.0-beta.1 (2026-09-06)

Primera beta interna de Cívica Pago: motor de recaudo por cuotas con disciplina
de rutas semanales para cobradores, gestión de cartera, solicitudes de pago y
panel de administración, sobre arquitectura multi-tenant.

### Novedades destacadas

- **Rutas semanales con ciclos de cobro (4 sábados):** el explorador de
  viviendas expone los recorridos del mes derivados de
  `Periodo.fechasCobroParciales`, con selector rodante (los sábados pasados
  desaparecen), tarjeta de vivienda en 4 filas (manzana/casa, residente, cuota,
  fecha de vencimiento) y filtrado estricto por fecha de corte.
- **Disciplina de rutas:** los pendientes solo pueden recorrerse el sábado que
  les corresponde (botón bloqueado + aviso cualquier otro día); la mora se
  puede cobrar cualquier día sin selector de sábado y se ordena siempre de la
  deuda más antigua a la más reciente; el filtro "Todas las casas" se eliminó
  para no cruzar lógicas.
- **Filtro por etapa en Gestión de Cobro:** el cobrador puede acotar su lista
  de cobros por etapa directamente desde la pantalla.
- **Modo recorrido inmersivo** sincronizado con el ciclo activo y el mismo
  filtro de fecha de corte compartido con el explorador.

### Seguridad y robustez

- Aislamiento por tenant reforzado: las 6 queries `COUNT(*)` de los guards de
  eliminación (etapa/manzana/casa) ahora filtran por `tenant_id`; auditoría
  completa de las 44 queries SQL crudas del backend.
- El seed destructivo de desarrollo salió de `src/` (ya no compila en el build
  de producción) y vive en `database/scripts/` (ignorado por git).
- 73 errores de ESLint corregidos; 141 archivos de cobertura de tests
  des-trackeados del repositorio; pantalla huérfana eliminada; `print()` pelado
  sustituido por `debugPrint` bajo `kDebugMode`.
- 30 tests nuevos focalizados en la lógica de mayor riesgo: derivación de
  tarifas por modalidad, guard de roles, resolución de tenant, guard de
  mantenimiento, URL base de la app y mapeo del repositorio de residentes.

### Calidad

- Backend: 51 suites, 409 tests en verde · `nest build` limpio.
- Mobile: 201 tests en verde · `flutter analyze` 0 issues.
- Verificado en dispositivo físico: selector rodante, bloqueo de inicio fuera
  del sábado, mora sin selector y tarjetas de 4 filas.

### Notas de despliegue

- Versiones alineadas: backend `0.1.0`, mobile `0.1.0+1`.
- Redis sigue opcional: sin `REDIS_ENABLED=true` + `REDIS_URL` el backend usa
  fallback en memoria (añadir al checklist de producción).
- Notificaciones por correo fuera de alcance de esta beta (el job se retiró;
  diseño futuro en `apps/backend/docs/email-notifications-design.md`).
