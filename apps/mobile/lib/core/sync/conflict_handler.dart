import 'dart:async';

/// Resultado de intentar resolver un conflicto de sincronización.
enum ConflictResolution {
  /// El conflicto se resolvió exitosamente (el pago fue procesado o verificado).
  resolved,

  /// No se pudo resolver el conflicto tras los reintentos correspondientes.
  failed,
}

/// Orquestador para manejar reintentos de resolución de conflictos
/// con un esquema de exponential backoff (1s -> 2s -> 4s).
class SyncConflictHandler {
  /// Acción a reintentar. Debe retornar `true` si se resolvió exitosamente.
  final Future<bool> Function() retryAction;

  /// Callback opcional llamado antes de cada reintento, indicando el número
  /// de intento (1-indexed) y el retraso aplicado.
  final void Function(int attempt, Duration delay)? onRetryAttempt;

  SyncConflictHandler({
    required this.retryAction,
    this.onRetryAttempt,
  });

  /// Resuelve el conflicto reintentando la acción.
  /// Realiza hasta un máximo de 3 reintentos (4 intentos en total).
  Future<ConflictResolution> resolve() async {
    const maxRetries = 3;
    final backoffs = [
      const Duration(seconds: 1),
      const Duration(seconds: 2),
      const Duration(seconds: 4),
    ];

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final success = await retryAction();
        if (success) {
          return ConflictResolution.resolved;
        }
      } catch (_) {
        // Si hay una excepción, la tratamos como fallo y procedemos al reintento
      }

      if (attempt < maxRetries) {
        final delay = backoffs[attempt];
        if (onRetryAttempt != null) {
          onRetryAttempt!(attempt + 1, delay);
        }
        await Future.delayed(delay);
      }
    }

    return ConflictResolution.failed;
  }
}
