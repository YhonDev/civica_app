#!/usr/bin/env node
/**
 * Genera usuarios con credenciales automáticas basadas en la ubicación.
 *
 * Patrón email: mz{manzana_letra}_casa{numero}_{etapa}et@civica.com
 * Patrón password: Civica2026!{4 random digits}
 *
 * Ejecutar: node apps/backend/scripts/generate-users.js
 */

const bcrypt = require('bcrypt');
const { Client } = require('pg');
require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });

const SALT_ROUNDS = 10;

async function main() {
  const client = new Client({
    host: process.env.DATABASE_HOST,
    port: parseInt(process.env.DATABASE_PORT || '5432'),
    user: process.env.DATABASE_USER,
    password: process.env.DATABASE_PASSWORD,
    database: process.env.DATABASE_NAME,
    ssl: process.env.DATABASE_SSL ? { rejectUnauthorized: false } : false,
  });

  await client.connect();
  console.log('✅ Conectado a la base de datos\n');

  try {
    // 1. Obtener propietarios con su ubicación (casa → manzana → etapa)
    const { rows: propietarios } = await client.query(`
      SELECT
        p.id AS propietario_id,
        p.nombre,
        p.email AS email_actual,
        p.tenant_id,
        c.direccion_interna AS casa_direccion,
        m.nombre AS manzana_nombre,
        e.nombre AS etapa_nombre
      FROM propietarios p
      JOIN tenencias t ON t.propietario_id = p.id AND t.fecha_fin IS NULL
      JOIN casas c ON c.id = t.casa_id
      JOIN manzanas m ON m.id = c.manzana_id
      JOIN etapas e ON e.id = m.etapa_id
      ORDER BY e.nombre, m.nombre, c.direccion_interna
    `);

    console.log(`📋 Propietarios encontrados: ${propietarios.length}\n`);

    const usersToCreate = [];

    for (const p of propietarios) {
      // 2. Generar email basado en ubicación
      // "Manzana A" → "a", "Manzana 1" → "1", "Mz B" → "b"
      const manzanaClean = p.manzana_nombre
        .replace(/^manzana\s*/i, '')
        .replace(/^mz\s*/i, '')
        .trim();
      const manzanaLetter = manzanaClean || p.manzana_nombre.slice(-1).toLowerCase();

      const casaMatch = p.casa_direccion.match(/(\d+)/);
      const casaNumber = casaMatch ? casaMatch[1] : '001';

      const etapaMatch = p.etapa_nombre.match(/(\d+)/);
      const etapaNumber = etapaMatch ? etapaMatch[1] : '1';

      const generatedEmail = `mz${manzanaLetter}_casa${casaNumber}_${etapaNumber}et@civica.com`;

      // 3. Generar contraseña con patrón
      const randomDigits = String(Math.floor(1000 + Math.random() * 9000));
      const generatedPassword = `Civica2026!${randomDigits}`;

      // 4. Hashear con bcrypt
      const passwordHash = await bcrypt.hash(generatedPassword, SALT_ROUNDS);

      usersToCreate.push({
        propietario_id: p.propietario_id,
        nombre: p.nombre,
        email: generatedEmail,
        email_actual: p.email_actual,
        password: generatedPassword,
        passwordHash: passwordHash,
        tenant_id: p.tenant_id,
        rol: 'PROPIETARIO',
      });

      console.log(`👤 ${p.nombre}`);
      console.log(`   📧 Email: ${generatedEmail}`);
      console.log(`   🔑 Password: ${generatedPassword}`);
      console.log(`   🏠 Casa: ${p.casa_direccion}`);
      console.log('');
    }

    // 5. Insertar/actualizar usuarios en la BD
    console.log('📝 Creando usuarios en la BD...\n');

    for (const user of usersToCreate) {
      // Verificar si ya existe un usuario con este email
      const existing = await client.query(
        'SELECT id FROM usuarios WHERE email = $1',
        [user.email]
      );

      if (existing.rows.length > 0) {
        // Actualizar email y password
        await client.query(
          `UPDATE usuarios
           SET email = $1, password_hash = $2, nombre = $3, propietario_id = $4, updated_at = NOW()
           WHERE email = $5`,
          [user.email, user.passwordHash, user.nombre, user.propietario_id, user.email_actual]
        );
        console.log(`   ✅ ${user.nombre} — email actualizado: ${user.email}`);
      } else {
        // Verificar si existe con el email actual y actualizar
        const existingOld = await client.query(
          'SELECT id FROM usuarios WHERE email = $1',
          [user.email_actual]
        );

        if (existingOld.rows.length > 0) {
          await client.query(
            `UPDATE usuarios
             SET email = $1, password_hash = $2, nombre = $3, propietario_id = $4, updated_at = NOW()
             WHERE email = $5`,
            [user.email, user.passwordHash, user.nombre, user.propietario_id, user.email_actual]
          );
          console.log(`   ✅ ${user.nombre} — migrado: ${user.email_actual} → ${user.email}`);
        } else {
          // Insertar nuevo usuario
          await client.query(
            `INSERT INTO usuarios (id, email, password_hash, nombre, rol, propietario_id, tenant_id, activo, created_at, updated_at)
             VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, true, NOW(), NOW())`,
            [user.email, user.passwordHash, user.nombre, user.rol, user.propietario_id, user.tenant_id]
          );
          console.log(`   ✅ ${user.nombre} — creado: ${user.email}`);
        }
      }
    }

    // 6. Eliminar usuarios auth viejos que no sean admin/cobrador/nuestros propietarios
    const emailsToKeep = usersToCreate.map(u => u.email);
    emailsToKeep.push('admin@civica.com', 'cobrador@civica.com');

    const placeholders = emailsToKeep.map((_, i) => `$${i + 1}`).join(', ');
    const deleteResult = await client.query(
      `DELETE FROM usuarios WHERE email NOT IN (${placeholders})`,
      emailsToKeep
    );
    if (deleteResult.rowCount > 0) {
      console.log(`\n🗑️  Usuarios viejos eliminados: ${deleteResult.rowCount}`);
    }

    console.log('\n═══════════════════════════════════════════════════════════');
    console.log('✅ USUARIOS GENERADOS EXITOSAMENTE');
    console.log('═══════════════════════════════════════════════════════════');
    console.log('\n📋 CREDENCIALES PARA LOGIN:\n');
    console.log('─'.repeat(60));

    for (const user of usersToCreate) {
      console.log(`👤 ${user.nombre}`);
      console.log(`   📧 ${user.email}`);
      console.log(`   🔑 ${user.password}`);
      console.log('─'.repeat(60));
    }

    console.log('\n🔐 Admin: admin@civica.com (misma contraseña de siempre)');
    console.log('🧑‍💼 Cobrador: cobrador@civica.com (misma contraseña de siempre)');

    // 7. Listar todos los usuarios finales
    console.log('\n\n📊 TODOS LOS USUARIOS EN LA BD:\n');
    const { rows: allUsers } = await client.query(
      'SELECT email, nombre, rol, activo FROM usuarios ORDER BY rol, nombre'
    );
    console.log('Email'.padEnd(40) + 'Nombre'.padEnd(20) + 'Rol'.padEnd(15) + 'Activo');
    console.log('─'.repeat(80));
    for (const u of allUsers) {
      console.log(
        u.email.padEnd(40) +
        u.nombre.padEnd(20) +
        u.rol.padEnd(15) +
        (u.activo ? '✅' : '❌')
      );
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  } finally {
    await client.end();
  }
}

main();
