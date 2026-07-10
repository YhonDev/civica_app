import 'package:drift/drift.dart';

import '../app_database.dart';

/// DAO para consultas de sincronización.
/// Expone count de entidades pendientes para mostrar estado de sync.
class SyncDao extends DatabaseAccessor<AppDatabase> {
  SyncDao(super.db);

  /// Cuenta pagos pendientes de sincronizar.
  Future<int> countPagosPendientes() {
    return (db.select(db.pagos)
          ..where((t) => t.syncStatus.equals('PENDIENTE_SYNC')))
        .get()
        .then((rows) => rows.length);
  }

  /// Cuenta pagos en conflicto.
  Future<int> countPagosEnConflicto() {
    return (db.select(db.pagos)
          ..where((t) => t.syncStatus.equals('CONFLICTO')))
        .get()
        .then((rows) => rows.length);
  }

  /// Obtiene todos los IDs de propietarios con cuotas pendientes.
  Future<List<String>> propietariosConDeuda() async {
    final cuotas = await (db.select(db.cuotas)
          ..where((t) =>
              t.estado.equals('PENDIENTE') | t.estado.equals('VENCIDA')))
        .get();

    final ids = cuotas.map((c) => c.propietarioId).toSet().toList();
    return ids;
  }

  /// Elimina datos antiguos (útil después de sync completo).
  Future<void> limpiarDatosAntiguos() async {
    // Eliminar pagos sincronizados con más de 90 días
    final corte = DateTime.now().subtract(const Duration(days: 90));

    await (db.delete(db.pagos)
          ..where((t) =>
              t.syncStatus.equals('SYNC_OK') & t.createdAt.isSmallerThanValue(corte)))
        .go();
  }
}
