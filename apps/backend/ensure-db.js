const net = require('net');
const { execSync } = require('child_process');

const port = parseInt(process.env.DATABASE_PORT || '54322', 10);
const host = process.env.DATABASE_HOST || '127.0.0.1';

// Si está configurado para la nube (no localhost), omitimos el check local
if (host !== '127.0.0.1' && host !== 'localhost') {
  process.exit(0);
}

function checkPort(p, h) {
  return new Promise((resolve) => {
    const socket = net.connect(p, h, () => {
      socket.end();
      resolve(true);
    });
    socket.on('error', () => {
      resolve(false);
    });
  });
}

async function main() {
  const isOpen = await checkPort(port, host);
  if (isOpen) {
    console.log(`[DB Guard] ✅ Base de datos en ${host}:${port} lista.`);
    process.exit(0);
  }

  console.log(`[DB Guard] ⚠️ Puerto ${port} cerrado. Levantando contenedor Docker...`);
  try {
    try {
      execSync('docker start civica-postgres', { stdio: 'ignore' });
    } catch (_) {
      execSync('docker start supabase_db_Civica_pago_app', { stdio: 'ignore' });
    }
    console.log(`[DB Guard] 🚀 Contenedor PostgreSQL iniciado. Esperando disponibilidad...`);
    for (let i = 0; i < 15; i++) {
      await new Promise((r) => setTimeout(r, 1000));
      if (await checkPort(port, host)) {
        console.log(`[DB Guard] ✅ Conexión establecida a PostgreSQL en puerto ${port}.`);
        process.exit(0);
      }
    }
    console.warn(`[DB Guard] ⚠️ El puerto ${port} no respondió a tiempo.`);
  } catch (_) {
    console.warn(`[DB Guard] ⚠️ No se pudo iniciar automáticamente el contenedor. Verifica Docker.`);
  }
}

main();

