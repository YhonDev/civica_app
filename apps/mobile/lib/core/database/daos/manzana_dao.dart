import 'package:drift/drift.dart';
import '../app_database.dart';

class ManzanaDao extends DatabaseAccessor<AppDatabase> {
  ManzanaDao(super.db);

  Future<List<Manzana>> getAll(String etapaId) {
    return (select(db.manzanas)..where((t) => t.etapaId.equals(etapaId))).get();
  }

  Future<int> insert(ManzanasCompanion manzana) {
    return into(db.manzanas).insert(manzana);
  }
}
