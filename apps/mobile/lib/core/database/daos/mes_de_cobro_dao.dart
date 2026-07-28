import 'package:drift/drift.dart';
import '../app_database.dart';

class MesDeCobroDao extends DatabaseAccessor<AppDatabase> {
  MesDeCobroDao(super.db);

  Future<List<MesesDeCobroData>> getAll(String tenantId, String proyectoId) {
    return (select(db.mesesDeCobro)
          ..where((t) => t.tenantId.equals(tenantId) & t.proyectoId.equals(proyectoId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  Future<int> insert(MesesDeCobroCompanion mes) {
    return into(db.mesesDeCobro).insert(mes);
  }
}
