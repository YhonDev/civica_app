import 'package:drift/drift.dart';

import '../app_database.dart';

/// DAO para operaciones con pagos en SQLite local.
/// Los pagos se crean offline con syncStatus = PENDIENTE_SYNC
/// y se sincronizan cuando hay conexión.
class PagoDao extends DatabaseAccessor<AppDatabase> {
  PagoDao(super.db);

  /// Inserta un pago offline (aún no sincronizado).
  Future<void> insertOffline(PagosCompanion pago) {
    return db.into(db.pagos).insert(pago);
  }

  /// Obtiene pagos de un residente.
  Future<List<Pago>> getByResidente(String residenteId) {
    return (db.select(db.pagos)
          ..where((t) => t.residenteId.equals(residenteId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  /// Obtiene todos los pagos pendientes de sincronización.
  Future<List<Pago>> getPendientesSync() {
    return (db.select(db.pagos)
          ..where((t) => t.syncStatus.equals('PENDIENTE_SYNC'))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc)]))
        .get();
  }

  /// Marca un pago como sincronizado tras éxito en el servidor.
  /// Guarda el serverId en la columna separada, manteniendo el ID local intacto.
  Future<void> marcarSincronizado(String id, String serverId) {
    return (db.update(db.pagos)..where((t) => t.id.equals(id))).write(
      PagosCompanion(
        serverId: Value(serverId),
        syncStatus: Value('SYNC_OK'),
        fechaSync: Value(DateTime.now()),
      ),
    );
  }

  /// Marca un pago en conflicto (409 del servidor).
  Future<void> marcarConflicto(String id) {
    return (db.update(db.pagos)..where((t) => t.id.equals(id))).write(
      PagosCompanion(
        syncStatus: Value('CONFLICTO'),
        fechaSync: Value(DateTime.now()),
      ),
    );
  }

  /// Obtiene pagos en conflicto.
  Future<List<Pago>> getEnConflicto() {
    return (db.select(db.pagos)..where((t) => t.syncStatus.equals('CONFLICTO'))).get();
  }

  /// Busca un pago por clientPaymentId (idempotencia).
  Future<Pago?> getByClientPaymentId(String clientPaymentId) {
    return (db.select(db.pagos)..where((t) => t.clientPaymentId.equals(clientPaymentId)))
        .getSingleOrNull();
  }

  /// Obtiene todos los elementos en la cola (pendientes, sincronizados OK, y conflictos/errores).
  Future<List<Pago>> getAllQueueItems() {
    return (db.select(db.pagos)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  /// Limpia de la memoria local los pagos que ya se sincronizaron exitosamente (verde).
  Future<int> limpiarSincronizados() {
    return (db.delete(db.pagos)..where((t) => t.syncStatus.equals('SYNC_OK'))).go();
  }

  /// Restablece un pago con error/conflicto para reintentar la sincronización.
  Future<void> reintentarPago(String id) {
    return (db.update(db.pagos)..where((t) => t.id.equals(id))).write(
      const PagosCompanion(
        syncStatus: Value('PENDIENTE_SYNC'),
      ),
    );
  }
}
