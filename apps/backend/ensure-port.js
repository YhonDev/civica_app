const net = require('net');
const { execSync } = require('child_process');

let killPort;
try {
  killPort = require('kill-port');
} catch (_) {}

const port = parseInt(process.env.PORT || process.env.APP_PORT || '3000', 10);

function killWithCommands(targetPort) {
  if (process.platform === 'linux' || process.platform === 'darwin') {
    // 1. Try fuser
    try {
      execSync(`fuser -k -9 ${targetPort}/tcp 2>/dev/null || true`, { stdio: 'ignore' });
    } catch (_) {}

    // 2. Try ss + process.kill
    try {
      const ssOut = execSync(`ss -lptn 'sport = :${targetPort}' 2>/dev/null || true`, { encoding: 'utf8' });
      const pidMatches = ssOut.match(/pid=(\d+)/g);
      if (pidMatches) {
        for (const m of pidMatches) {
          const pid = m.replace('pid=', '');
          if (pid && pid !== `${process.pid}`) {
            try {
              process.kill(Number(pid), 'SIGKILL');
            } catch (_) {}
          }
        }
      }
    } catch (_) {}

    // 3. Try lsof (if installed)
    try {
      const lsofOut = execSync(`lsof -ti tcp:${targetPort} 2>/dev/null || true`, { encoding: 'utf8' }).trim();
      if (lsofOut) {
        const pids = lsofOut.split('\n').map((p) => p.trim()).filter(Boolean);
        for (const pid of pids) {
          if (pid && pid !== `${process.pid}`) {
            try {
              process.kill(Number(pid), 'SIGKILL');
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
  } else if (process.platform === 'win32') {
    try {
      const netstatOut = execSync(`netstat -ano | findstr :${targetPort} 2>nul || exit 0`, { encoding: 'utf8' });
      const lines = netstatOut.split('\n');
      for (const line of lines) {
        const parts = line.trim().split(/\s+/);
        const pid = parts[parts.length - 1];
        if (pid && !isNaN(Number(pid)) && pid !== '0' && pid !== `${process.pid}`) {
          try {
            execSync(`taskkill /F /PID ${pid} 2>nul`, { stdio: 'ignore' });
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}

function checkPortFree(targetPort) {
  return new Promise((resolve) => {
    const tester = net.createServer()
      .once('error', (err) => {
        if (err.code === 'EADDRINUSE') {
          resolve(false);
        } else {
          resolve(true);
        }
      })
      .once('listening', () => {
        tester.once('close', () => resolve(true)).close();
      })
      .listen(targetPort);
  });
}

async function ensurePort(targetPort) {
  const isFreeInitially = await checkPortFree(targetPort);
  if (isFreeInitially) {
    return;
  }

  console.log(`[Port Guard] ⚠️ Puerto ${targetPort} en uso por proceso anterior. Liberando...`);

  // Intento 1: kill-port npm library
  if (typeof killPort === 'function') {
    try {
      await killPort(targetPort, 'tcp');
    } catch (_) {}
  }

  // Intento 2: Fallback comandos nativos (fuser, ss, lsof)
  killWithCommands(targetPort);

  // Verificación y reintentos breves
  for (let i = 0; i < 5; i++) {
    await new Promise((r) => setTimeout(r, 200));
    const isFree = await checkPortFree(targetPort);
    if (isFree) {
      console.log(`[Port Guard] ✅ Puerto ${targetPort} liberado limpiamente.`);
      return;
    }
    killWithCommands(targetPort);
  }

  console.log(`[Port Guard] ℹ️ Continuando arranque en puerto ${targetPort}...`);
}

ensurePort(port)
  .then(() => {
    process.exit(0);
  })
  .catch((err) => {
    console.error('[Port Guard] Error asegurando puerto:', err);
    process.exit(0);
  });
