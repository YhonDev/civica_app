#!/usr/bin/env node
/**
 * Runner de Migraciones Reversibles para PostgreSQL — Cuentiva
 * Ciclo 5: Calidad Operativa y Migraciones Reversibles
 *
 * Uso:
 *   node scripts/migrate-runner.mjs up      → Aplica migraciones pendientes
 *   node scripts/migrate-runner.mjs down    → Revierte la última migración aplicada
 *   node scripts/migrate-runner.mjs status  → Muestra el estado de cada migración
 */

import { readdir, readFile } from 'fs/promises';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const MIGRATIONS_DIR = join(__dirname, '..', 'database', 'migrations');

function getDbClient() {
  const sslMode = process.env.DATABASE_SSL;
  const sslRejectUnauthorized = process.env.DATABASE_SSL_REJECT_UNAUTHORIZED !== 'false';

  return new pg.Client({
    host: process.env.DATABASE_HOST || '127.0.0.1',
    port: parseInt(process.env.DATABASE_PORT || '54322', 10),
    user: process.env.DATABASE_USER || 'postgres',
    password: process.env.DATABASE_PASSWORD || 'postgres',
    database: process.env.DATABASE_NAME || 'postgres',
    ssl: sslMode ? { rejectUnauthorized: sslRejectUnauthorized } : false,
  });
}

async function ensureHistoryTable(client) {
  await client.query(`
    CREATE TABLE IF NOT EXISTS _migrations_history (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255) NOT NULL UNIQUE,
      applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);
}

async function getAppliedMigrations(client) {
  const res = await client.query(`
    SELECT name, applied_at FROM _migrations_history ORDER BY id ASC;
  `);
  return res.rows;
}

async function getMigrationFiles() {
  const files = await readdir(MIGRATIONS_DIR);
  // Filtramos solo archivos .sql que NO sean .down.sql
  return files
    .filter((f) => f.endsWith('.sql') && !f.endsWith('.down.sql'))
    .sort();
}

async function up(client) {
  console.log('\n🚀 Verificando migraciones pendientes (UP)...');
  await ensureHistoryTable(client);

  const appliedRows = await getAppliedMigrations(client);
  const appliedSet = new Set(appliedRows.map((r) => r.name));
  const files = await getMigrationFiles();

  const pending = files.filter((f) => !appliedSet.has(f));

  if (pending.length === 0) {
    console.log('✨ Todas las migraciones están al día. Ninguna pendiente.\n');
    return;
  }

  for (const file of pending) {
    console.log(`⏳ Aplicando: ${file}...`);
    const filePath = join(MIGRATIONS_DIR, file);
    const sql = await readFile(filePath, 'utf-8');

    await client.query('BEGIN');
    try {
      await client.query(sql);
      await client.query(
        'INSERT INTO _migrations_history (name) VALUES ($1);',
        [file],
      );
      await client.query('COMMIT');
      console.log(`✅ Aplicada con éxito: ${file}`);
    } catch (err) {
      await client.query('ROLLBACK');
      console.error(`❌ Error al aplicar ${file}:`, err.message);
      throw err;
    }
  }

  console.log(`\n🎉 Se aplicaron ${pending.length} migración(es) con éxito.\n`);
}

async function down(client) {
  console.log('\n⏪ Verificando última migración aplicada (DOWN)...');
  await ensureHistoryTable(client);

  const res = await client.query(`
    SELECT id, name FROM _migrations_history ORDER BY id DESC LIMIT 1;
  `);

  if (res.rows.length === 0) {
    console.log('⚠️ No hay migraciones registradas para revertir.\n');
    return;
  }

  const lastMigration = res.rows[0];
  const baseName = lastMigration.name.replace(/\.sql$/, '');
  const downFileName = `${baseName}.down.sql`;
  const downFilePath = join(MIGRATIONS_DIR, downFileName);

  let downSql = '';
  try {
    downSql = await readFile(downFilePath, 'utf-8');
  } catch {
    throw new Error(
      `❌ No se encontró el archivo de reversión requerido: ${downFileName}`,
    );
  }

  console.log(`⏳ Revirtiendo migración: ${lastMigration.name} usando ${downFileName}...`);
  await client.query('BEGIN');
  try {
    await client.query(downSql);
    await client.query('DELETE FROM _migrations_history WHERE id = $1;', [
      lastMigration.id,
    ]);
    await client.query('COMMIT');
    console.log(`✅ Reversión completada: ${lastMigration.name}\n`);
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(`❌ Error al revertir ${lastMigration.name}:`, err.message);
    throw err;
  }
}

async function status(client) {
  console.log('\n📋 Estado de Migraciones de Base de Datos:\n');
  await ensureHistoryTable(client);

  const appliedRows = await getAppliedMigrations(client);
  const appliedMap = new Map(appliedRows.map((r) => [r.name, r.applied_at]));
  const files = await getMigrationFiles();

  for (const file of files) {
    const isApplied = appliedMap.has(file);
    const date = isApplied
      ? appliedMap.get(file).toISOString()
      : '-------------------';
    const tag = isApplied ? '✅ [APLICADA] ' : '⏳ [PENDIENTE]';
    console.log(`${tag} ${file.padEnd(50)} | ${date}`);
  }

  console.log('');
}

async function main() {
  const action = process.argv[2] || 'status';

  if (!['up', 'down', 'status'].includes(action)) {
    console.error(`Acción desconocida: "${action}". Usa: up | down | status`);
    process.exit(1);
  }

  const client = getDbClient();
  try {
    await client.connect();
    if (action === 'up') await up(client);
    else if (action === 'down') await down(client);
    else if (action === 'status') await status(client);
  } catch (err) {
    console.error(`\n💥 Error en migrate-runner (${action}):`, err.message);
    process.exit(1);
  } finally {
    await client.end().catch(() => {});
  }
}

main();
