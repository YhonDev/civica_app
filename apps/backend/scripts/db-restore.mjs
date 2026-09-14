#!/usr/bin/env node
/**
 * Script de Restauración de PostgreSQL — Cuentiva
 * Ciclo 5: Calidad Operativa y Resiliencia
 *
 * Restaura un dump generado por db-backup.mjs usando pg_restore.
 *
 * Seguridad:
 *   Requiere el flag --confirm o variable RESTORE_CONFIRM=true para
 *   evitar restauraciones accidentales que sobrescriban datos en vivo.
 *
 * Uso:
 *   node scripts/db-restore.mjs --confirm                    → Restaura el backup más reciente
 *   node scripts/db-restore.mjs /path/al/archivo.dump --confirm  → Restaura un archivo específico
 *   node scripts/db-restore.mjs --dry-run                   → Valida integridad sin restaurar
 */

import { execFileSync } from 'child_process';
import { existsSync, readdirSync, statSync } from 'fs';
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

function findLatestBackup() {
  if (!existsSync(BACKUPS_DIR)) return null;

  const files = readdirSync(BACKUPS_DIR)
    .filter((f) => f.endsWith('.dump'))
    .map((f) => ({
      name: f,
      path: join(BACKUPS_DIR, f),
      time: statSync(join(BACKUPS_DIR, f)).mtimeMs,
    }))
    .sort((a, b) => b.time - a.time);

  return files.length > 0 ? files[0].path : null;
}

async function runRestore() {
  const args = process.argv.slice(2);
  const isDryRun = args.includes('--dry-run');
  const isConfirmed = args.includes('--confirm') || process.env.RESTORE_CONFIRM === 'true';

  let targetFile = args.find((a) => !a.startsWith('--'));

  if (!targetFile) {
    targetFile = findLatestBackup();
  }

  if (!targetFile || !existsSync(targetFile)) {
    console.error(`❌ Archivo de backup no encontrado: ${targetFile ?? '(no hay backups en el directorio)'}`);
    process.exit(1);
  }

  console.log('\n🔄 Procedimiento de Restauración de Base de Datos PostgreSQL...');
  console.log(`   Archivo seleccionado: ${targetFile}`);
  console.log(`   Destino: ${HOST}:${PORT}/${DBNAME} (Usuario: ${USER})`);

  // Paso 1: Validar integridad con pg_restore -l
  console.log('\n🔍 Paso 1/2: Verificando integridad del archivo...');
  try {
    execFileSync('pg_restore', ['-l', targetFile], { stdio: ['ignore', 'ignore', 'pipe'] });
    console.log('✅ El archivo de backup es íntegro y válido.');
  } catch (err) {
    console.error('❌ El archivo de backup está corrupto o es incompatible:', err.message);
    process.exit(1);
  }

  if (isDryRun) {
    console.log('\n✨ Modo --dry-run finalizado: archivo validado correctamente. No se aplicaron cambios.');
    process.exit(0);
  }

  // Paso 2: Validación de confirmación
  if (!isConfirmed) {
    console.warn('\n⚠️ SEGURIDAD: La restauración puede sobrescribir o modificar datos existentes.');
    console.warn('   Para ejecutar la restauración real, incluye el flag --confirm o define RESTORE_CONFIRM=true:');
    console.warn(`   node scripts/db-restore.mjs "${targetFile}" --confirm\n`);
    process.exit(1);
  }

  // Paso 3: Ejecutar pg_restore
  console.log('\n🚀 Paso 2/2: Restaurando objetos en la base de datos...');
  const env = {
    ...process.env,
    PGPASSWORD: PASSWORD,
    PGSSLMODE: SSL_MODE,
  };

  const restoreArgs = [
    '-h', HOST,
    '-p', PORT,
    '-U', USER,
    '-d', DBNAME,
    '--no-owner',
    '--no-privileges',
    targetFile,
  ];

  const startTime = Date.now();
  try {
    // pg_restore suele retornar warnings con código no-cero si ya existen tablas,
    // por lo que capturamos la salida para evaluar
    execFileSync('pg_restore', restoreArgs, { env, stdio: ['ignore', 'pipe', 'pipe'] });
    const duration = ((Date.now() - startTime) / 1000).toFixed(2);
    console.log(`✅ Restauración completada en ${duration}s.`);
    console.log('🎉 Base de datos restablecida correctamente.\n');
    process.exit(0);
  } catch (err) {
    const duration = ((Date.now() - startTime) / 1000).toFixed(2);
    // pg_restore puede arrojar advertencias tolerables (ej. tablas existentes si no se usa --clean)
    if (err.status && err.status === 1) {
      console.log(`⚠️ pg_restore completó con advertencias (código 1) en ${duration}s.`);
      console.log('   (Es común si los esquemas u objetos ya existían previamente).');
      process.exit(0);
    }
    console.error('❌ Error crítico en pg_restore:', err.message);
    if (err.stderr) console.error(err.stderr.toString());
    process.exit(1);
  }
}

runRestore();
