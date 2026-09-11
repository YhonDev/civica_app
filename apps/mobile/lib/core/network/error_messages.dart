import 'dart:io' show HandshakeException, HttpException, SocketException;

import 'package:dio/dio.dart' show DioException;
import 'package:flutter/foundation.dart' show kDebugMode;

import 'api_exceptions.dart';

/// Mensajes de error seguros para la UI.
///
/// Nunca interpolles `e` (ni `e.toString()`) directamente en un SnackBar o
/// toast: un `Exception` técnico filtra detalles internos (stacks, URIs,
/// "Instance of 'X'", "Bad state: …"). Usa [sanitizeApiError].
///
/// Política: **allowlist**. Solo dos clases de error producen texto visible:
///
/// 1. `ApiException` con mensaje propio → ese mensaje (ya es de autoría
///    propia del equipo/API, apto para usuario).
/// 2. Errores técnicos conocidos (`DioException`, `SocketException`,
///    `HandshakeException`, `HttpException`) → mensaje genérico de conexión.
///
/// Todo lo demás (objetos anónimos, `StateError`, `FormatException`, strings
/// técnicos) cae al mensaje genérico [fallback]. El error crudo nunca se
/// muestra, pero en builds de debug sí se loguea (ver [debugReportUnknownError])
/// para que el desarrollador no pierda la pista del fallo real.
///
/// Regla de guardian (doc/DESIGN_SYSTEM.md y convención de la app):
/// `'Error al X: ${sanitizeApiError(e)}'` — nunca `'Error al X: $e'`.
///
/// Nota: `Exception('mensaje propio')` y `Exception('mensaje propio').toString()`
/// son ambos aceptados, porque `Exception.toString()` es `'Exception: <mensaje>'`
/// y ese mensaje fue escrito por el equipo. Sirve como puente para call sites
/// que aún capturan `catch (e)` y pasan `e.toString()`; el objetivo es pasar
/// siempre el objeto completo. Los `String` se tratan como contenido escrito
/// en código (compile-time): jamás interpolles `'$e'` dentro de ellos.
String sanitizeApiError(Object error, {String fallback = _fallbackGenerico}) {
  // 1) Excepciones de dominio: el mensaje ya es apto para el usuario.
  if (error is ApiException) {
    final msg = error.message.trim();
    if (msg.isNotEmpty) return msg;
    // ApiException sin mensaje útil no aporta nada; cae al fallback.
    return fallback;
  }

  // 2) Errores técnicos de red/framework → mensaje genérico de conexión.
  if (error is DioException ||
      error is SocketException ||
      error is HttpException ||
      error is HandshakeException) {
    return _mensajeConexion;
  }

  // 3) `Exception('mensaje propio')` o su `toString()`: el contenido tras el
  //    prefijo lo escribió el equipo, así que es presentable.
  final authored = _authoredExceptionMessage(error);
  if (authored != null) {
    final msg = authored.trim();
    if (msg.isNotEmpty) return msg;
  }

  // 4) Cualquier otra cosa no es apto para usuario → fallback (+ log de debug).
  debugReportUnknownError(error, fallback);
  return fallback;
}

const String _fallbackGenerico =
    'Ocurrió un error inesperado. Intenta de nuevo.';
const String _mensajeConexion =
    'No se pudo conectar con el servidor. Verifica tu conexión a internet.';

/// Extrae el mensaje de autoría propia de un error.
///
/// - `Exception('…')` base: su `toString()` es `'Exception: <mensaje>'`; si el
///   prefijo no está (subclase con toString propio), NO es de autoría propia → null.
/// - `String`: contenido escrito en código (compile-time), se acepta y se le
///   quita un prefijo técnico heredado si lo traía.
String? _authoredExceptionMessage(Object error) {
  if (error is Exception) {
    final raw = error.toString();
    // `Exception('x').toString()` == 'Exception: x'. Si el runtime añadió
    // contexto técnico (otra subclase), no coincide y cae al fallback.
    if (!raw.startsWith('Exception: ')) return null;
    final content = _stripAuthoredPrefix(raw.substring('Exception: '.length));
    // Un Exception cuyo contenido viste ropa de excepción de runtime es un
    // diagnóstico envuelto (patrón `Exception('$e')`), no copy del equipo.
    return _technicalPrefix.hasMatch(content) ? null : content;
  }
  if (error is String) {
    return _authoredFromString(error);
  }
  return null;
}

/// Prefijos de excepciones de runtime: si un String los trae, no es copy del
/// equipo sino un diagnóstico pegado (típicamente `'$e'` violando la regla de
/// guardian) → no es de autoría propia. Defensa en profundidad SOLO en la
/// ruta de String; la ruta de objetos es allowlist pura por tipo.
final RegExp _technicalPrefix = RegExp(
  r'^(DioException|SocketException|HttpException|HandshakeException|'
  r'ClientException|FormatException|StateError|RangeError|ArgumentError|'
  r'TypeError|NoSuchMethodError|Unhandled exception)\b',
  caseSensitive: false,
);

String? _authoredFromString(String s) {
  if (_technicalPrefix.hasMatch(s)) return null;
  return _stripAuthoredPrefix(s);
}

/// Quita un prefijo técnico heredado (`Exception:`, `Error:`) del contenido
/// de autoría propia. Una sola pasada, case-insensitive.
String _stripAuthoredPrefix(String message) {
  return message.replaceFirst(
    RegExp(r'^(Exception|Error)\s*:\s*', caseSensitive: false),
    '',
  );
}

/// Loguea el error crudo en debug (con stack si existe) para que el
/// desarrollador conserve el diagnóstico que la UI oculta a propósito.
///
/// En release es un no-op: el usuario solo ve [fallback].
void debugReportUnknownError(Object error, String shownFallback,
    {StackTrace? stackTrace}) {
  if (kDebugMode) {
    // ignore: avoid_print
    print(
      '[sanitizeApiError] error no reconocido ocultado al usuario. '
      'Mostrado: "$shownFallback" | Crudo: $error',
    );
    if (stackTrace != null) {
      // ignore: avoid_print
      print(stackTrace);
    }
  }
}

/// Mensaje genérico para errores de conexión (expuesto para tests y para
/// call sites que quieran reutilizarlo).
const String kConnectionErrorMessage = _mensajeConexion;

/// Mensaje genérico por defecto (expuesto para tests y call sites).
const String kGenericErrorMessage = _fallbackGenerico;
