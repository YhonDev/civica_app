import 'api_exceptions.dart';

/// Mensajes de error seguros para la UI.
///
/// Nunca interpolar `e` directamente en un SnackBar/Toast: un `Exception`
/// técnico puede filtrar detalles internos (stacks, URIs, mensajes de Dio).
/// Usa [sanitizeApiError] para convertir cualquier error en un texto
/// apropiado para el usuario.
///
/// Regla de guardian (doc/DESIGN_SYSTEM.md y convención de la app):
/// `'Error al X: ${sanitizeApiError(e)}'` — nunca `'Error al X: $e'`.
String sanitizeApiError(Object error, {String fallback = 'Ocurrió un error inesperado. Intenta de nuevo.'}) {
  // Excepciones de dominio: su mensaje ya es apto para el usuario.
  if (error is ApiException) {
    final msg = error.message.trim();
    if (msg.isNotEmpty) return _clean(msg);
  }

  final raw = error.toString();

  // Errores técnicos de red/framework → mensaje genérico de conexión.
  final lower = raw.toLowerCase();
  if (lower.contains('dioexception') ||
      lower.contains('socketexception') ||
      lower.contains('httpexception') ||
      lower.contains('handshakeexception') ||
      lower.contains('clientexception') ||
      lower.contains('connection refused') ||
      lower.contains('connection reset')) {
    return 'No se pudo conectar con el servidor. Verifica tu conexión a internet.';
  }

  final clean = _clean(raw);
  if (clean.isEmpty) return fallback;
  return clean;
}

/// Quita prefijos técnicos (`Exception:`, `Error:`) y espacios extra.
String _clean(String message) {
  return message
      .replaceFirst(RegExp(r'^(Exception|Error)\s*:\s*', caseSensitive: false), '')
      .replaceFirst(RegExp(r'^(DioException|FormatException|StateError)\s*[^:]*:\s*', caseSensitive: false), '')
      .trim();
}
