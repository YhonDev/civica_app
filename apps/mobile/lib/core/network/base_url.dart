import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

/// URL de la API en builds **debug**: backend local.
const _debugDefaultUrl = 'http://127.0.0.1:3000/api';
const _debugWebDefaultUrl = 'http://localhost:3000/api';

/// URL de la API en builds **release**: despliegue de producción en Render.
/// HTTPS, por lo que no aplica la restricción de texto plano de Android.
const _releaseDefaultUrl = 'https://cuentiva.onrender.com/api';

/// Detects the API base URL by build flavor.
///
/// Priority:
/// 1. `API_BASE_URL` from `--dart-define` (override explícito para cualquier
///    entorno: staging, emulador, producción, etc.)
/// 2. Debug → backend local (`localhost:3000/api` en web, `127.0.0.1:3000/api` en móvil).
/// 3. Release → Render (`https://cuentiva.onrender.com/api`).
String detectBaseUrl() {
  const envUrl = String.fromEnvironment('API_BASE_URL');
  if (envUrl.isNotEmpty) return envUrl;

  // Debug apunta al backend local.
  // En Web usamos localhost para evitar conflicto de origen cruzado con 127.0.0.1.
  if (kDebugMode) {
    if (kIsWeb) return _debugWebDefaultUrl;
    return _debugDefaultUrl;
  }

  return _releaseDefaultUrl;
}

/// Detects the WebSocket server URL (same host, no /api suffix).
String detectWsUrl() {
  final base = detectBaseUrl();
  return base.endsWith('/api') ? base.substring(0, base.length - 4) : base;
}
