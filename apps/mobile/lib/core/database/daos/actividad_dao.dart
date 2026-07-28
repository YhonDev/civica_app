import 'package:drift/drift.dart';
import '../app_database.dart';

class ActividadDao extends DatabaseAccessor<AppDatabase> {
  ActividadDao(super.db);

  Future<List<Actividade>> getRecientes(String tenantId, {int limit = 50}) {
    return (select(db.actividades)
          ..where((t) => t.tenantId.equals(tenantId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
          ..limit(limit))
        .get();
  }

  Future<int> insert(ActividadesCompanion actividad) {
    return into(db.actividades).insert(actividad);
  }
}
