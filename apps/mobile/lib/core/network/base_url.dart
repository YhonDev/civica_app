import 'package:flutter/foundation.dart'
    show kReleaseMode, kIsWeb;

/// Detects the API base URL from compile-time environment or platform defaults.
///
/// Priority:
/// 1. `API_BASE_URL` from `--dart-define`
/// 2. Web / Android: `http://127.0.0.1:3000/api`
///
/// En builds release sin `API_BASE_URL` explícito se lanza un error de
/// compilación/arranque: nunca debe desplegarse una app apuntando a
/// localhost HTTP en texto plano.
String detectBaseUrl() {
  const envUrl = String.fromEnvironment('API_BASE_URL');
  if (envUrl.isNotEmpty) return envUrl;

  if (kReleaseMode && !kIsWeb) {
    throw StateError(
      'API_BASE_URL no configurada para build release. '
      'Compila con --dart-define=API_BASE_URL=https://tu-dominio/api',
    );
  }

  // 127.0.0.1 explícito en todas las plataformas. "localhost" puede
  // resolverse a ::1 (IPv6) en el navegador; si el backend no escucha
  // dual-stack la petición falla con DioException [unknown] / OperationError
  // antes de recibir respuesta.
  return 'http://127.0.0.1:3000/api';
}

/// Detects the WebSocket server URL (same host, no /api suffix).
String detectWsUrl() {
  final base = detectBaseUrl();
  return base.endsWith('/api') ? base.substring(0, base.length - 4) : base;
}
