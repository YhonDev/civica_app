#!/usr/bin/env node
/**
 * Smoke test de la ruta de build Docker — prueba el mismo camino que un
 * despliegue por contenedor: docker build → contenedor en modo producción →
 * Postgres real (contenedor scratch) → GET /api/health.
 *
 * Detecta exactamente las regresiones que CI no ve:
 *   - CMD del Dockerfile apuntando a una ruta inexistente (dist/src/main.js)
 *   - bundle dist incompleto o dependencias de producción faltantes
 *   - app que arranca pero no logra conectar a la base de datos
 *
 * Uso:
 *   npm run test:docker              # headless: build, health check, cleanup
 *   npm run test:docker -- --interactive   # deja el contenedor vivo hasta presionar Enter
 *
 * Exit code 0 = smoke OK; 1 = alguna verificación falló.
 * No toca tu base de datos local: usa un Postgres scratch en :54399 (se elimina al salir).
 */

import { spawn, execFile } from 'node:child_process';
import { createReadStream, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import readline from 'node:readline';

// ── Constantes ──────────────────────────────────────────────
const BACKEND_DIR = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const SCHEMA_SQL = path.join(BACKEND_DIR, 'database', 'schema.sql');
const MIGRATIONS_DIR = path.join(BACKEND_DIR, 'database', 'migrations');
const IMAGE = 'civica-backend-smoke:local';
const PG_CONTAINER = 'civica-smoke-pg';
const API_CONTAINER = 'civica-smoke-api';
const PG_IMAGE = 'postgres:16';
const PG_PORT = 54399; // scratch: nunca la 54322 de tu Supabase local
const API_PORT = Number(process.env.SMOKE_API_PORT ?? 33000);
const JWT_SECRET = 'docker-smoke-jwt-secret';
const JWT_REFRESH_SECRET = 'docker-smoke-jwt-refresh-secret';

const KEEP = process.argv.includes('--interactive') || process.argv.includes('--keep');
const cleanupTasks = [];
let failing = false;

const dim = (s) => `\x1b[2m${s}\x1b[0m`;
const ok = (s) => console.log(`✅ ${s}`);
const fail = (s) => { failing = true; console.error(`❌ ${s}`); };
const step = (s) => console.log(`\n\x1b[1m▶ ${s}\x1b[0m`);

function cleanup() {
  for (const task of cleanupTasks.splice(0).reverse()) {
    try { task(); } catch { /* best effort */ }
  }
}
function onSignal(signal) {
  console.log(`\n${signal} recibido — limpiando contenedores scratch…`);
  cleanup();
  process.exit(130);
}
process.on('SIGINT', () => onSignal('SIGINT'));
process.on('SIGTERM', () => onSignal('SIGTERM'));

// ── Helpers de proceso ──────────────────────────────────────
function run(cmd, args, opts = {}) {
  return new Promise((resolvePromise) => {
    execFile(cmd, args, { encoding: 'utf8', ...opts }, (err, stdout, stderr) => {
      resolvePromise({ code: err?.code ?? (err ? 1 : 0), stdout: stdout ?? '', stderr: stderr ?? '' });
    });
  });
}

function runStream(cmd, args, { input } = {}) {
  return new Promise((resolvePromise) => {
    const child = spawn(cmd, args, { stdio: ['pipe', 'ignore', 'pipe'] });
    let stderr = '';
    child.stderr.on('data', (d) => { stderr += d; });
    if (input) {
      input.pipe(child.stdin);
      child.stdin.on('error', () => resolvePromise({ code: 1, stderr }));
    }
    child.on('error', () => resolvePromise({ code: 1, stderr }));
    child.on('exit', (c) => resolvePromise({ code: c ?? 1, stderr }));
  });
}

async function waitUntil(fn, { tries = 25, delayMs = 1000, label = 'condición' } = {}) {
  for (let i = 1; i <= tries; i++) {
    if (await fn()) return true;
    process.stdout.write(dim(`  esperando ${label} (${i}/${tries})\r`));
    await new Promise((r) => setTimeout(r, delayMs));
  }
  process.stdout.write('\n');
  return false;
}

const portFree = (port) =>
  run('bash', ['-c', `! (exec 3<>/dev/tcp/127.0.0.1/${port}) 2>/dev/null` ]).then((r) => r.code === 0);

async function findFreePort(start) {
  for (let p = start; p < start + 10; p++) if (await portFree(p)) return p;
  return null;
}

// ── Pasos ───────────────────────────────────────────────────
async function prerequisites() {
  step('Prerrequisitos');
  const docker = await run('docker', ['info', '--format', '{{.ServerVersion}}']);
  if (docker.code !== 0) { fail('Docker no está disponible'); return false; }
  ok(`Docker ${docker.stdout.trim()}`);

  if (!existsSync(SCHEMA_SQL)) { fail(`No existe ${SCHEMA_SQL}`); return false; }

  const pgPort = await findFreePort(PG_PORT);
  if (!pgPort) { fail(`Puertos ${PG_PORT}..${PG_PORT + 9} ocupados`); return false; }
  const apiPort = await findFreePort(API_PORT);
  if (!apiPort) { fail(`Puertos ${API_PORT}..${API_PORT + 9} ocupados`); return false; }
  Object.assign(globalThis, { __pgPort: pgPort, __apiPort: apiPort });
  ok(`Puertos libres — Postgres scratch: ${pgPort}, API: ${apiPort}`);
  return true;
}

async function startScratchPostgres() {
  const pgPort = globalThis.__pgPort;
  step(`Postgres scratch (${PG_IMAGE} en :${pgPort})`);
  const up = await run('docker', ['run', '-d', '--rm', '--name', PG_CONTAINER,
    '-e', 'POSTGRES_PASSWORD=postgres', '-e', 'POSTGRES_USER=postgres',
    '-p', `127.0.0.1:${pgPort}:5432`, PG_IMAGE]);
  if (up.code !== 0) { fail(`No se pudo levantar ${PG_CONTAINER}: ${up.stderr.trim()}`); return false; }
  cleanupTasks.push(() => run('docker', ['rm', '-f', PG_CONTAINER]));

  const ready = await waitUntil(
    async () => (await run('docker', ['exec', PG_CONTAINER, 'pg_isready', '-U', 'postgres'])).code === 0,
    { label: 'pg_isready' },
  );
  if (!ready) { fail('Postgres scratch no respondió a tiempo'); return false; }
  ok('Postgres listo');
  return true;
}

async function applySchema() {
  step('Cargar schema.sql (+ migraciones si existen) en la BD scratch');
  const schema = await runStream('docker',
    ['exec', '-i', PG_CONTAINER, 'psql', '-U', 'postgres', '-d', 'postgres', '-v', 'ON_ERROR_STOP=1', '-q'],
    { input: createReadStream(SCHEMA_SQL) });
  if (schema.code !== 0) { fail(`schema.sql falló al cargar:\n${dim(schema.stderr.split('\n').slice(-8).join('\n'))}`); return false; }
  ok('schema.sql aplicado');

  if (existsSync(MIGRATIONS_DIR)) {
    const { readdirSync } = await import('node:fs');
    for (const f of readdirSync(MIGRATIONS_DIR).filter((x) => x.endsWith('.sql')).sort()) {
      const mig = await runStream('docker',
        ['exec', '-i', PG_CONTAINER, 'psql', '-U', 'postgres', '-d', 'postgres', '-v', 'ON_ERROR_STOP=1', '-q'],
        { input: createReadStream(path.join(MIGRATIONS_DIR, f)) });
      if (mig.code !== 0) { fail(`migración ${f} falló:\n${dim(mig.stderr.split('\n').slice(-8).join('\n'))}`); return false; }
      ok(`migración ${f}`);
    }
  }
  return true;
}

async function buildImage() {
  step(`docker build → ${IMAGE}`);
  const build = await run('docker', ['build', '-t', IMAGE, BACKEND_DIR]);
  if (build.code !== 0) {
    fail('docker build falló');
    console.error(dim(build.stderr.split('\n').slice(-15).join('\n')));
    return false;
  }
  ok('imagen construida');
  return true;
}

async function runContainer() {
  const pgPort = globalThis.__pgPort;
  const apiPort = globalThis.__apiPort;
  step(`Levantar contenedor de la API (modo producción, puerto ${apiPort})`);
  const up = await run('docker', ['run', '-d', '--rm', '--name', API_CONTAINER,
    '--network', 'host',
    '-e', 'NODE_ENV=production',
    '-e', `PORT=${apiPort}`,
    '-e', 'DATABASE_HOST=127.0.0.1',
    '-e', `DATABASE_PORT=${pgPort}`,
    '-e', 'DATABASE_USER=postgres',
    '-e', 'DATABASE_PASSWORD=postgres',
    '-e', 'DATABASE_NAME=postgres',
    '-e', `JWT_SECRET=${JWT_SECRET}`,
    '-e', `JWT_REFRESH_SECRET=${JWT_REFRESH_SECRET}`,
    '-e', 'REDIS_ENABLED=false',
    IMAGE]);
  if (up.code !== 0) { fail(`No se pudo levantar ${API_CONTAINER}: ${up.stderr.trim()}`); return false; }
  cleanupTasks.push(() => run('docker', ['rm', '-f', API_CONTAINER]));

  // La corrección central de este smoke: el CMD debe servir el bundle plano dist/main.js
  const cmd = await run('docker', ['inspect', '--format', '{{.Config.Cmd}}', API_CONTAINER]);
  const cmdOk = cmd.stdout.includes('dist/main.js') && !cmd.stdout.includes('dist/src/main.js');
  cmdOk ? ok(`CMD del contenedor: ${cmd.stdout.trim()}`)
        : fail(`CMD incorrecto: ${cmd.stdout.trim()} (esperado ["node","dist/main.js"])`);
  return cmdOk;
}

async function healthCheck() {
  const apiPort = globalThis.__apiPort;
  step(`Health check → http://127.0.0.1:${apiPort}/api/health`);
  const url = `http://127.0.0.1:${apiPort}/api/health`;

  const res = await waitUntil(async () => {
    try {
      const r = await fetch(url, { signal: AbortSignal.timeout(2000) });
      if (r.status !== 200) return false;
      const body = await r.json();
      return body?.status === 'ok' && body?.database === 'connected';
    } catch { return false; }
  }, { tries: 30, delayMs: 2000, label: 'health 200' });
  process.stdout.write('\n');

  if (!res) {
    fail(`La API no respondió health OK en ${url}`);
    const logs = await run('docker', ['logs', '--tail', '60', API_CONTAINER]);
    console.error(dim(logs.stdout + logs.stderr));
    return false;
  }
  const body = await (await fetch(url)).json();
  ok(`health: status=${body.status} database=${body.database}`);

  // En producción Swagger debe estar deshabilitado (guard de seguridad)
  try {
    const docs = await fetch(`http://127.0.0.1:${apiPort}/docs`, { signal: AbortSignal.timeout(2000) });
    docs.status === 404 ? ok('/docs deshabilitado en producción (404)')
                        : fail(`/docs respondió ${docs.status} en producción (esperado 404)`);
  } catch { ok('/docs deshabilitado en producción'); }
  return !failing;
}

async function main() {
  console.log(`\n🐳 Docker smoke — ${IMAGE}\n`);

  if (!(await prerequisites())) return finish();
  if (!(await startScratchPostgres())) return finish();
  if (!(await applySchema())) return finish();
  if (!(await buildImage())) return finish();
  if (!(await runContainer())) return finish();
  if (!(await healthCheck())) return finish();

  if (KEEP) {
    step('Modo interactivo');
    console.log(`API viva en http://127.0.0.1:${globalThis.__apiPort}/api — presiona Enter para limpiar y salir…`);
    await new Promise((resolvePromise) => {
      const rl = readline.createInterface({ input: process.stdin });
      rl.once('line', () => { rl.close(); resolvePromise(); });
    });
  }
  return finish(true);
}

function finish(success) {
  step('Limpieza');
  cleanup();
  // Esperar a que los rm terminen y comprobar existencia con inspect
  // (exit 1 = "No such object" = eliminado; ps --filter da falsos positivos)
  Promise.all([
    run('docker', ['rm', '-f', PG_CONTAINER]),
    run('docker', ['rm', '-f', API_CONTAINER]),
  ])
    .then(async () => {
      // rm -f regresa antes de que el teardown termine (estado "removing"):
      // sondear hasta que inspect deje de encontrar el contenedor.
      const leftovers = [];
      for (const name of [PG_CONTAINER, API_CONTAINER]) {
        let gone = false;
        for (let i = 0; i < 20; i++) {
          const probe = await run('docker', ['inspect', '--format', '{{.State.Status}}', name]);
          if (probe.code !== 0) { gone = true; break; }
          await new Promise((r) => setTimeout(r, 500));
        }
        if (!gone) {
          const probe = await run('docker', ['inspect', '--format', '{{.State.Status}}', name]);
          leftovers.push(`${name}(${probe.stdout.trim()})`);
        }
      }
      if (leftovers.length === 0) ok('contenedores scratch eliminados');
      else fail(`residuos: ${leftovers.join(' ')}`);

      console.log('');
      if (failing) {
        console.error('💥 Docker smoke FALLÓ — revisa los pasos anteriores\n');
        process.exit(1);
      }
      console.log('✅ Docker smoke OK — la imagen construye, el CMD sirve dist/main.js y la app levanta contra Postgres real\n');
      process.exit(0);
    });
}

main();
