# ✅ Checklist post-despliegue — Cívica Pago en Render

URL base del despliegue: **`https://cuentiva.onrender.com`**
Ejecutar los pasos **en orden**; si uno falla, detenerse y resolver antes de continuar.

---

## 0. Preconditions (antes de empezar)

- [ ] El deploy en Render figura **"Live"** en la pestaña Events.
- [ ] Variables en Render → Environment:
  - `NODE_ENV=production`
  - `DATABASE_HOST` (pooler de Supabase, ej. `aws-1-us-east-2.pooler.supabase.com`)
  - `DATABASE_PORT=5432`
  - `DATABASE_USER`, `DATABASE_PASSWORD`
  - `DATABASE_NAME=postgres`
  - `DATABASE_SSL=require`
  - `JWT_SECRET`, `JWT_REFRESH_SECRET` (aleatorios, ver paso 6)
  - `CORS_ORIGIN` (orígenes permitidos, separados por coma, o `*` en pruebas)
- [ ] El schema está aplicado en Supabase:
  `database/schema.sql` + migraciones en `database/migrations/`.
  Si la BD es fresca, sin esto el login fallará con 500.
- [ ] Existe al menos un usuario ADMIN en la BD de producción
  (sin seed el login responde 401 "Credenciales inválidas").

> ⚠️ **Free tier:** la instancia duerme tras ~15 min de inactividad. La primera
> petición puede tardar 60–120s en responder (cold start). Reintentar antes de
> dar algo por roto.

---

## 1. Health check (conectividad + BD)

```bash
curl -s -m 90 https://cuentiva.onrender.com/api/health
```

**Esperado:**
```json
{"status":"ok","database":"connected","redis":"disabled","timestamp":"..."}
```

- [ ] `status: "ok"` y `database: "connected"`
- `unhealthy` / `database: "disconnected"` → problema de conexión con Supabase
  (revisar `DATABASE_*`).
- Timeout sin respuesta → el servicio no arrancó; revisar Logs en Render
  (debe aparecer `Servidor iniciado en puerto ...`).

---

## 2. Login (autenticación + bcrypt + JWT)

```bash
curl -s -m 30 -X POST https://cuentiva.onrender.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"TU_USUARIO","password":"TU_PASSWORD"}' | head -c 200
```

**Esperado:** JSON con `accessToken`, `refreshToken` y `usuario.rol`.

- [ ] Devuelve `accessToken` y `usuario.rol`
- [ ] `passwordHash` **NO** aparece en la respuesta
- 401 "Credenciales inválidas" → el usuario no existe en la BD de producción
  (crear admin, ver preconditions).
- 500 → falta `JWT_SECRET` o similar; revisar Logs.

---

## 3. Smoke test completo (desde `apps/backend`)

```bash
cd apps/backend
SMOKE_BASE_URL=https://cuentiva.onrender.com/api \
SMOKE_USER=TU_USUARIO \
SMOKE_PASS=TU_PASSWORD \
SMOKE_TIMEOUT_MS=30000 \
npm run test:smoke
```

**Esperado: `10/10 checks OK`, exit 0:**

- [ ] 1. `GET /health` → 200
- [ ] 2. `POST /auth/login` → accessToken + rol
- [ ] 3. `GET /dashboard/administrador` → shape válido (`resumen`, `evolucion`, `modalidades`)
- [ ] 4. `GET /cobros` → shape paginado `{data,total}` + relaciones residente/casa
- [ ] 5. Write-path: `POST /solicitudes` → listar → `PATCH resolver` → `DELETE` (autolimpieza)
- [ ] 6. `POST /auth/refresh` → rota tokens

> Si la BD no tiene cobros, el write-path se marca "omitido" con check OK.

---

## 4. CORS (Flutter web / orígenes)

```bash
# Preflight desde el origen real de tu web (ajustar Origin)
curl -s -m 30 -o /dev/null -w "%{http_code} ACAO=%header{access-control-allow-origin}\n" \
  -X OPTIONS https://cuentiva.onrender.com/api/dashboard/administrador \
  -H "Origin: http://localhost:40745" \
  -H "Access-Control-Request-Method: GET" \
  -H "Access-Control-Request-Headers: authorization,content-type"
```

- [ ] Status `204` y header `ACAO` presente con el origen (o `*`)
- Sin `ACAO` → agregar el origen a `CORS_ORIGIN` en Render y redeploy.

---

## 5. Conexión de las apps

Gracias al sistema de flavors (`lib/core/network/base_url.dart`):

```bash
# Release/producción → apunta a Render automáticamente (sin flags):
flutter run --release

# Debug/desarrollo → apunta al backend local (127.0.0.1:3000):
flutter run
# En Android físico: adb reverse tcp:3000 tcp:3000

# Override explícito de la API en cualquier modo:
flutter run --dart-define=API_BASE_URL=https://otra-api.onrender.com/api
```

Checklist en la app:

- [ ] Login entra y llega al dashboard según rol (ADMIN/COBRADOR/RESIDENTE)
- [ ] Dashboard carga stats sin "Error al cargar dashboard"
- [ ] Cartera/Cobros lista cuotas (o muestra vacío válido, no error)
- [ ] El gate de debug "API no disponible" **no** aparece (solo sale si la API local cae en debug)
- [ ] Sin errores `DioException`/`OperationError` en la consola de logs

> 📌 La URL base es **compile-time**: si antes se compiló con otro valor, un hot
> reload no basta — relanzar `flutter run`.

---

## 6. Seguridad post-deploy (una sola vez)

- [ ] `JWT_SECRET` y `JWT_REFRESH_SECRET` son cadenas **aleatorias**
  (`openssl rand -hex 32`), no las de los ejemplos documentados.
- [ ] `CORS_ORIGIN` restringido a orígenes reales al terminar la fase de pruebas
  (con `*` cualquier web puede llamar a la API con credenciales).
- [ ] Usuarios seed con contraseñas conocidas (`Admin2026!`, `Residente2026!`…)
  **cambiadas o desactivadas** en la BD de producción.
- [ ] Swagger oculto: con `NODE_ENV=production` `/docs` está deshabilitado por
  defecto — verificar que `https://cuentiva.onrender.com/docs` dé 404.
- [ ] Sin secretos en el repo (ver auditoría: `.env` ignorados, scripts
  sanitizados leen del entorno).

---

## Estado de la última verificación

| # | Verificación | Resultado | Fecha |
|---|---|---|---|
| 1 | Health check | ✅ `{"status":"ok","database":"connected"}` | 2026-09-08 |
| 2 | Login | ⚠️ 401 — falta crear usuario ADMIN en BD de producción | 2026-09-08 |
| 3 | Smoke test | ⚠️ 2/6 — bloqueado por credenciales (pendiente seed) | 2026-09-08 |
| 4 | CORS preflight | ✅ `204` + ACAO correcto | 2026-09-08 |
| 5 | App conecta | ✅ Flavors implementados (debug→local, release→Render) | 2026-09-08 |
| 6 | Seguridad | ⚠️ Pendiente: rotar token GitHub + password Supabase, JWT aleatorios | 2026-09-08 |
