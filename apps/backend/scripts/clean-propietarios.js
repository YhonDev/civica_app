const { Client } = require('pg');

async function main() {
  const connectionString = 'postgres://postgres.fpgukukujxfrlvynpyha:*REMOVED*@aws-1-us-east-2.pooler.supabase.com:5432/postgres';
  
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
