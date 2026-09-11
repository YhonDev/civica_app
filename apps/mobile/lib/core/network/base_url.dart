import 'package:flutter/foundation.dart' show kDebugMode;

/// URL de la API en builds **debug**: backend local.
const _debugDefaultUrl = 'http://127.0.0.1:3000/api';

/// URL de la API en builds **release**: despliegue de producción en Render.
/// HTTPS, por lo que no aplica la restricción de texto plano de Android.
const _releaseDefaultUrl = 'https://cuentiva.onrender.com/api';

/// Detects the API base URL by build flavor.
///
/// Priority:
/// 1. `API_BASE_URL` from `--dart-define` (override explícito para cualquier
///    entorno: staging, emulador, producción, etc.)
/// 2. Debug → backend local (`127.0.0.1:3000/api`, requiere `adb reverse`
///    en dispositivo físico).
/// 3. Release → Render (`https://cuentiva.onrender.com/api`).
///
/// `flutter run` (debug) apunta al local sin flags; `flutter run --release`
/// (o el APK de tienda) apunta a Render sin flags.
String detectBaseUrl() {
  const envUrl = String.fromEnvironment('API_BASE_URL');
  if (envUrl.isNotEmpty) return envUrl;

  // Debug apunta al backend local (127.0.0.1:3000/api).
  // Release (incluido Web en producción) apunta a Render.
  if (kDebugMode) return _debugDefaultUrl;

  return _releaseDefaultUrl;
}

/// Detects the WebSocket server URL (same host, no /api suffix).
String detectWsUrl() {
  final base = detectBaseUrl();
  return base.endsWith('/api') ? base.substring(0, base.length - 4) : base;
}
