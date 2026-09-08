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

    const query = `
      SELECT p.id, p.nombre, p.tenant_id, t.casa_id, c.direccion_interna
      FROM propietarios p
      LEFT JOIN tenencias t ON t.propietario_id = p.id
      LEFT JOIN casas c ON c.id = t.casa_id
    `;
    const { rows } = await client.query(query);
    
    console.log(`Found ${rows.length} rows:`);
    console.table(rows);
    
  } catch (err) {
    console.error('Error:', err);
  } finally {
    await client.end();
  }
}

main();
