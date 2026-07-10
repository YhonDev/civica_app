import 'package:drift/drift.dart';

import '../app_database.dart';

/// DAO para operaciones con cuotas en SQLite local.
class CuotaDao extends DatabaseAccessor<AppDatabase> {
  CuotaDao(super.db);

  /// Inserta o reemplaza un lote de cuotas (desde sync).
  Future<void> upsertCuotas(List<CuotasCompanion> cuotas) {
    return batch((batch) {
      for (final c in cuotas) {
        batch.insert(db.cuotas, c, mode: InsertMode.insertOrReplace);
      }
    });
  }

  /// Obtiene cuotas de un propietario, ordenadas por vencimiento descendente.
  Future<List<Cuota>> getByPropietario(String propietarioId) {
    return (db.select(db.cuotas)
          ..where((t) => t.propietarioId.equals(propietarioId))
          ..orderBy([(t) => OrderingTerm(expression: t.fechaVencimiento, mode: OrderingMode.desc)]))
        .get();
  }

  /// Obtiene cuotas pendientes o vencidas de un propietario.
  Future<List<Cuota>> getPendientes(String propietarioId) {
    return (db.select(db.cuotas)
          ..where((t) =>
              t.propietarioId.equals(propietarioId) &
              t.estado.isIn(['PENDIENTE', 'VENCIDA']))
          ..orderBy([(t) => OrderingTerm(expression: t.fechaVencimiento, mode: OrderingMode.asc)]))
        .get();
  }

  /// Actualiza el estado y monto pagado de una cuota.
  Future<void> actualizarEstado({
    required String cuotaId,
    required String estado,
    required int montoPagado,
  }) {
    return (db.update(db.cuotas)..where((t) => t.id.equals(cuotaId)))
        .write(CuotasCompanion(
          estado: Value(estado),
          montoPagado: Value(montoPagado),
          updatedAt: Value(DateTime.now()),
        ));
  }
}
