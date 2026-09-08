#!/usr/bin/env node
/**
 * Smoke test de la API — verifica los flujos críticos contra un servidor
 * EN EJECUCIÓN (no levanta la app: así detecta regresiones de red, CORS,
 * build, DB o auth exactamente como las sufre el cliente móvil).
 *
 * Uso:
 *   npm run test:smoke
 *   SMOKE_BASE_URL=http://mi-host:3000/api SMOKE_USER=admin SMOKE_PASS=... npm run test:smoke
 *
 * Exit code 0 = todo OK; 1 = alguna verificación falló.
 *
 * Verifica:
 *   1. GET  /health                  → 200 (conectividad básica)
 *   2. POST /auth/login              → 200 + accessToken + usuario.rol
 *   3. GET  /dashboard/administrador → 200 + shape esperado
 *   4. GET  /cobros                  → 200 + { data, total } shape esperado
 *   5. POST /auth/refresh            → 200 + nuevo accessToken
 *   6. Write-path: POST /solicitudes → PATCH resolver → DELETE (limpieza)
 *
 *   El flujo de escritura usa un cobro real del tenant y se autolimpia;
 *   si no hay cobros (DB fresca), se omite con check OK.
 */

const BASE_URL = process.env.SMOKE_BASE_URL ?? 'http://127.0.0.1:3000/api';
const USERNAME = process.env.SMOKE_USER ?? 'admin';
const PASSWORD = process.env.SMOKE_PASS ?? 'Admin2026!';
const TIMEOUT_MS = Number(process.env.SMOKE_TIMEOUT_MS ?? 8000);

let accessToken = '';
let refreshToken = '';

const results = [];

function check(name, ok, detail = '') {
  results.push({ name, ok });
  const icon = ok ? '✅' : '❌';
  console.log(`${icon} ${name}${detail ? ` — ${detail}` : ''}`);
}

async function req(method, path, { body, auth = false } = {}) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    const res = await fetch(`${BASE_URL}${path}`, {
      method,
      signal: controller.signal,
      headers: {
        'Content-Type': 'application/json',
        ...(auth && accessToken
          ? { Authorization: `Bearer ${accessToken}` }
          : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });
    const text = await res.text();
    let data = null;
    try {
      data = text ? JSON.parse(text) : null;
    } catch {
      data = text;
    }
    return { status: res.status, data };
  } finally {
    clearTimeout(timer);
  }
}

// ── 1. Health ────────────────────────────────────────────────────
async function testHealth() {
  try {
    const { status } = await req('GET', '/health');
    check('GET /health responde 200', status === 200, `status=${status}`);
  } catch (e) {
    check('GET /health responde 200', false, `sin conexión: ${e.cause?.code ?? e.message}`);
  }
}

// ── 2. Login ─────────────────────────────────────────────────────
async function testLogin() {
  try {
    const { status, data } = await req('POST', '/auth/login', {
      body: { username: USERNAME, password: PASSWORD },
    });
    const ok =
      status === 200 || status === 201
        ? Boolean(data?.accessToken) && Boolean(data?.usuario?.rol)
        : false;
    check(
      'POST /auth/login devuelve accessToken + usuario',
      ok,
      ok ? `rol=${data.usuario.rol}` : `status=${status}`,
    );
    if (ok) {
      accessToken = data.accessToken;
      refreshToken = data.refreshToken ?? '';
    }
  } catch (e) {
    check('POST /auth/login devuelve accessToken + usuario', false, e.message);
  }
}

// ── 3. Dashboard administrador ───────────────────────────────────
async function testDashboard() {
  try {
    const { status, data } = await req('GET', '/dashboard/administrador', {
      auth: true,
    });
    const ok =
      status === 200 &&
      data?.resumen !== undefined &&
      Array.isArray(data?.evolucion) &&
      Array.isArray(data?.modalidades);
    check(
      'GET /dashboard/administrador shape válido',
      ok,
      ok
        ? `recaudoTotal=${data.resumen.recaudoTotal}`
        : `status=${status} body=${JSON.stringify(data)?.slice(0, 120)}`,
    );
  } catch (e) {
    check('GET /dashboard/administrador shape válido', false, e.message);
  }
}

// ── 4. Cobros ────────────────────────────────────────────────────
async function testCobros() {
  try {
    const { status, data } = await req('GET', '/cobros?limit=50', { auth: true });
    const ok =
      status === 200 && Array.isArray(data?.data) && typeof data?.total === 'number';
    check(
      'GET /cobros shape paginado { data, total }',
      ok,
      ok ? `total=${data.total}, items=${data.data.length}` : `status=${status}`,
    );

    // Si hay items, validar que traen las relaciones que la UI necesita
    if (ok && data.data.length > 0) {
      const first = data.data[0];
      const hasJoin =
        'residenteNombre' in first || first.residente !== null || 'casaDireccion' in first;
      check('GET /cobros items traen relaciones de residente/casa', hasJoin);
    }
  } catch (e) {
    check('GET /cobros shape paginado { data, total }', false, e.message);
  }
}

// ── 5. Refresh ───────────────────────────────────────────────────
async function testRefresh() {
  if (!refreshToken) {
    check('POST /auth/refresh rota tokens', false, 'sin refreshToken del login');
    return;
  }
  try {
    const { status, data } = await req('POST', '/auth/refresh', {
      body: { refreshToken },
    });
    const ok = status === 200 || status === 201 ? Boolean(data?.accessToken) : false;
    check('POST /auth/refresh rota tokens', ok, `status=${status}`);
    if (ok) accessToken = data.accessToken;
  } catch (e) {
    check('POST /auth/refresh rota tokens', false, e.message);
  }
}

// ── 6. Write-path: crear → resolver → eliminar solicitud ────────
async function testSolicitudWritePath() {
  let solicitudId = null;

  // Helper de limpieza final (siempre que se haya creado la solicitud)
  const limpiar = async () => {
    if (!solicitudId) return;
    try {
      await req('DELETE', `/solicitudes/${solicitudId}`, { auth: true });
    } catch {
      console.warn(`⚠️  No se pudo eliminar la solicitud ${solicitudId} (dato residual)`);
    }
  };

  try {
    // 6a. Elegir un cobro real del tenant (evita FK/tenant mismatch)
    const list = await req('GET', '/cobros?limit=1', { auth: true });
    const cobro = list.data?.data?.[0];
    if (!cobro) {
      check(
        'Flujo solicitud: crear → resolver → eliminar',
        true,
        'omitido: no hay cobros en el tenant (DB fresca)',
      );
      return;
    }

    // 6b. Crear la solicitud
    const creacion = await req('POST', '/solicitudes', {
      auth: true,
      body: {
        cobroId: cobro.id,
        tipo: 'SMOKE_TEST',
        descripcion: 'Solicitud de smoke test — autolimpia',
      },
    });
    solicitudId = creacion.data?.id ?? null;
    const creadaOk =
      (creacion.status === 200 || creacion.status === 201) && Boolean(solicitudId);
    check(
      'POST /solicitudes crea solicitud sobre cobro del tenant',
      creadaOk,
      creadaOk
        ? `id=${solicitudId.slice(0, 8)}…`
        : `status=${creacion.status} body=${JSON.stringify(creacion.data)?.slice(0, 120)}`,
    );
    if (!creadaOk) return;

    // 6c. Verificar que aparece en el listado del usuario autenticado
    const listado = await req('GET', '/solicitudes?limit=100', { auth: true });
    const visible = Array.isArray(listado.data)
      ? listado.data.some((s) => s.id === solicitudId)
      : false;
    check('GET /solicitudes devuelve la solicitud creada (tenant-scoped)', visible);

    // 6d. Resolverla
    const resolucion = await req('PATCH', `/solicitudes/${solicitudId}/resolver`, {
      auth: true,
      body: { estado: 'RESUELTA', respuesta: 'Resuelta por smoke test' },
    });
    const resueltaOk =
      (resolucion.status === 200 || resolucion.status === 201) &&
      resolucion.data?.estado === 'RESUELTA';
    check(
      'PATCH /solicitudes/:id/resolver marca RESUELTA',
      resueltaOk,
      resueltaOk ? '' : `status=${resolucion.status} body=${JSON.stringify(resolucion.data)?.slice(0, 120)}`,
    );

    // 6e. Limpieza: eliminar la solicitud
    const borrado = await req('DELETE', `/solicitudes/${solicitudId}`, { auth: true });
    const borradaOk =
      (borrado.status === 200 || borrado.status === 201) && borrado.data?.ok === true;
    check('DELETE /solicitudes/:id limpia el dato de prueba', borradaOk, `status=${borrado.status}`);
    if (borradaOk) solicitudId = null;
  } catch (e) {
    check('Flujo solicitud: crear → resolver → eliminar', false, e.message);
  } finally {
    await limpiar();
  }
}

// ── Runner ───────────────────────────────────────────────────────
async function main() {
  console.log(`\n🔥 Smoke test — ${BASE_URL}\n`);

  await testHealth();
  await testLogin();
  await testDashboard();
  await testCobros();
  await testSolicitudWritePath();
  await testRefresh();

  const failed = results.filter((r) => !r.ok);
  const passed = results.length - failed.length;
  console.log(`\n${passed}/${results.length} checks OK`);

  if (failed.length > 0) {
    console.error(`\nFALLANDO: ${failed.map((f) => f.name).join(' | ')}`);
    process.exit(1);
  }
  console.log('API sana ✓\n');
  process.exit(0);
}

main();
