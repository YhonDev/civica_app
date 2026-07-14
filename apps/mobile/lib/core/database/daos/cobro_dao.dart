import 'package:drift/drift.dart';

import '../app_database.dart';

/// DAO para operaciones con cobros en SQLite local.
class CobroDao extends DatabaseAccessor<AppDatabase> {
  CobroDao(super.db);

  /// Inserta o reemplaza un lote de cobros (desde sync).
  Future<void> upsertCobros(List<CobrosCompanion> cobros) {
    return batch((batch) {
      for (final c in cobros) {
        batch.insert(db.cobros, c, mode: InsertMode.insertOrReplace);
      }
    });
  }

  /// Obtiene cobros de un residente, ordenados por vencimiento descendente.
  Future<List<Cobro>> getByResidente(String residenteId) {
    return (db.select(db.cobros)
          ..where((t) => t.residenteId.equals(residenteId))
          ..orderBy([(t) => OrderingTerm(expression: t.fechaVencimiento, mode: OrderingMode.desc)]))
        .get();
  }

  /// Obtiene cobros pendientes o vencidos de un residente.
  Future<List<Cobro>> getPendientes(String residenteId) {
    return (db.select(db.cobros)
          ..where((t) =>
              t.residenteId.equals(residenteId) &
              t.estado.isIn(['PENDIENTE', 'VENCIDA']))
          ..orderBy([(t) => OrderingTerm(expression: t.fechaVencimiento, mode: OrderingMode.asc)]))
        .get();
  }

  /// Actualiza el estado y monto pagado de un cobro.
  Future<void> actualizarEstado({
    required String cobroId,
    required String estado,
    required int montoPagado,
  }) {
    return (db.update(db.cobros)..where((t) => t.id.equals(cobroId)))
        .write(CobrosCompanion(
          estado: Value(estado),
          montoPagado: Value(montoPagado),
          updatedAt: Value(DateTime.now()),
        ));
  }
}
