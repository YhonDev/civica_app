const { Client } = require('pg');

async function main() {
  const connectionString = 'postgres://postgres.fpgukukujxfrlvynpyha:*REMOVED*@aws-1-us-east-2.pooler.supabase.com:5432/postgres';
  
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
