#!/usr/bin/env node
/**
 * Script de Backup Automatizado de PostgreSQL — Cuentiva
 * Ciclo 5: Calidad Operativa y Resiliencia
 *
 * Realiza un dump binario comprimido con pg_dump (-Fc), verifica su
 * integridad mediante pg_restore -l y gestiona la retención de backups locales.
 *
 * Uso:
 *   node scripts/db-backup.mjs
 *   BACKUP_RETENTION=14 node scripts/db-backup.mjs
 */

import { execFileSync } from 'child_process';
import { mkdirSync, readdirSync, statSync, unlinkSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const BACKUPS_DIR = join(__dirname, '..', 'database', 'backups');

const HOST = process.env.DATABASE_HOST || '127.0.0.1';
const PORT = String(process.env.DATABASE_PORT || '54322');
const USER = process.env.DATABASE_USER || 'postgres';
const PASSWORD = process.env.DATABASE_PASSWORD || 'postgres';
const DBNAME = process.env.DATABASE_NAME || 'postgres';
const SSL_MODE = process.env.DATABASE_SSL || (HOST === '127.0.0.1' || HOST === 'localhost' ? 'prefer' : 'require');
const RETENTION_COUNT = parseInt(process.env.BACKUP_RETENTION || '7', 10);

function getTimestamp() {
  const now = new Date();
  const pad = (n) => String(n).padStart(2, '0');
  const yyyy = now.getFullYear();
  const mm = pad(now.getMonth() + 1);
  const dd = pad(now.getDate());
  const hh = pad(now.getHours());
  const mi = pad(now.getMinutes());
  const ss = pad(now.getSeconds());
  return `${yyyy}${mm}${dd}_${hh}${mi}${ss}`;
}

function cleanOldBackups(dir, retention) {
  try {
    const files = readdirSync(dir)
      .filter((f) => f.endsWith('.dump'))
      .map((f) => ({
        name: f,
        path: join(dir, f),
        time: statSync(join(dir, f)).mtimeMs,
      }))
      .sort((a, b) => b.time - a.time); // más nuevos primero

    if (files.length > retention) {
      const toDelete = files.slice(retention);
      for (const item of toDelete) {
        unlinkSync(item.path);
        console.log(`🧹 Eliminado backup antiguo por retención: ${item.name}`);
      }
    }
  } catch (err) {
    console.warn('⚠️ No se pudo aplicar retención:', err.message);
  }
}

async function runBackup() {
  console.log('\n📦 Iniciando backup automatizado de PostgreSQL...');
  console.log(`   Host: ${HOST}:${PORT} | Base: ${DBNAME} | Usuario: ${USER}`);

  mkdirSync(BACKUPS_DIR, { recursive: true });

  const filename = `backup_cuentiva_${getTimestamp()}.dump`;
  const outputPath = join(BACKUPS_DIR, filename);

  const env = {
    ...process.env,
    PGPASSWORD: PASSWORD,
    PGSSLMODE: SSL_MODE,
  };

  const args = [
    '-h', HOST,
    '-p', PORT,
    '-U', USER,
    '-d', DBNAME,
    '-F', 'c',        // Custom compressed format
    '-b',             // Include blobs
    '-f', outputPath,
  ];

  const startTime = Date.now();
  try {
    execFileSync('pg_dump', args, { env, stdio: ['ignore', 'ignore', 'pipe'] });
    const duration = ((Date.now() - startTime) / 1000).toFixed(2);

    const stats = statSync(outputPath);
    const sizeKb = (stats.size / 1024).toFixed(1);
    const sizeMb = (stats.size / (1024 * 1024)).toFixed(2);

    console.log(`✅ Dump generado en ${duration}s (${sizeKb} KB / ${sizeMb} MB)`);
    console.log(`   Ruta: ${outputPath}`);

    // Verificación de integridad con pg_restore -l
    console.log('🔍 Verificando integridad del archivo...');
    execFileSync('pg_restore', ['-l', outputPath], { stdio: ['ignore', 'ignore', 'pipe'] });
    console.log('✅ Integridad confirmada: el archivo es un archivo de backup válido y legible.');

    // Aplicar política de retención
    cleanOldBackups(BACKUPS_DIR, RETENTION_COUNT);

    console.log('🎉 Backup completado exitosamente.\n');
    process.exit(0);
  } catch (err) {
    console.error('❌ Error durante el backup:', err.message);
    if (err.stderr) {
      console.error('   Detalles:', err.stderr.toString());
    }
    process.exit(1);
  }
}

runBackup();
