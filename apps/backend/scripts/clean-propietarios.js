const { Client } = require('pg');
require('dotenv').config();

async function main() {
  const connectionString =
    process.env.DATABASE_URL ||
    `postgres://${process.env.DATABASE_USER}:${process.env.DATABASE_PASSWORD}@${process.env.DATABASE_HOST}:${process.env.DATABASE_PORT || 5432}/${process.env.DATABASE_NAME}`;
  if (!connectionString || connectionString.includes('undefined')) {
    console.error('ERROR: configura DATABASE_URL o las variables DATABASE_* en el entorno/.env');
    process.exit(1);
  }
  
  const client = new Client({ 
    connectionString,
    ssl: { rejectUnauthorized: false }
  });
  
  try {
    await client.connect();
    console.log('Connected to database.');

    // Find owners that have no tenencias
    const queryFind = `
      SELECT p.id, p.nombre
      FROM propietarios p
      LEFT JOIN tenencias t ON t.propietario_id = p.id
      WHERE t.id IS NULL
    `;
    const { rows } = await client.query(queryFind);
    
    console.log(`Found ${rows.length} propietarios without tenencias (casa asignada):`);
    rows.forEach(r => console.log(`- ${r.nombre} (ID: ${r.id})`));

    if (rows.length > 0) {
      const idsToDelete = rows.map(r => r.id);
      
      // Delete them
      const queryDelete = `
        DELETE FROM propietarios
        WHERE id = ANY($1::uuid[])
      `;
      const deleteResult = await client.query(queryDelete, [idsToDelete]);
      console.log(`Deleted ${deleteResult.rowCount} propietarios exitosamente.`);
    } else {
      console.log('No hay propietarios huérfanos (sin casa) para eliminar.');
    }
    
  } catch (err) {
    console.error('Error:', err);
  } finally {
    await client.end();
    console.log('Disconnected.');
  }
}

main();
