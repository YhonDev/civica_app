/// Base exception for all API errors.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thrown when authentication fails (401) and refresh also fails.
class AuthException extends ApiException {
  const AuthException({
    super.message = 'Sesión expirada. Inicie sesión nuevamente.',
    super.statusCode = 401,
  });
}

/// Thrown when the user has no network connection.
class NetworkException extends ApiException {
  const NetworkException({
    super.message = 'Sin conexión a internet.',
  });
}

/// Thrown when a conflict is detected (409).
class ConflictException extends ApiException {
  final String? serverId;

  const ConflictException({
    super.message = 'Conflicto: el recurso ya fue modificado en el servidor.',
    super.statusCode = 409,
    this.serverId,
  });
}

/// Thrown for server errors (5xx).
class ServerException extends ApiException {
  const ServerException({
    super.message = 'Error interno del servidor.',
    super.statusCode = 500,
  });
}

/// Thrown for validation errors (422).
class ValidationException extends ApiException {
  final Map<String, List<String>>? errors;

  const ValidationException({
    super.message = 'Error de validación.',
    super.statusCode = 422,
    this.errors,
  });
}
