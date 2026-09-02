import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

/// Detects the API base URL from compile-time environment or platform defaults.
///
/// Priority:
/// 1. `API_BASE_URL` from `--dart-define`
/// 2. Android (usando adb reverse tcp:3000 tcp:3000): `http://127.0.0.1:3000/api`
/// 3. Fallback: `http://localhost:3000/api`
String detectBaseUrl() {
  const envUrl = String.fromEnvironment('API_BASE_URL');
  if (envUrl.isNotEmpty) return envUrl;
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://127.0.0.1:3000/api';
  }
  return 'http://localhost:3000/api';
}

/// Detects the WebSocket server URL (same host, no /api suffix).
String detectWsUrl() {
  final base = detectBaseUrl();
  return base.endsWith('/api') ? base.substring(0, base.length - 4) : base;
}
