import 'package:drift/drift.dart';
import '../app_database.dart';

class SolicitudDao extends DatabaseAccessor<AppDatabase> {
  SolicitudDao(super.db);

  Future<List<Solicitude>> getByResidente(String residenteId) {
    return (select(db.solicitudes)
          ..where((t) => t.residenteId.equals(residenteId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }
  
  Future<List<Solicitude>> getPendientes(String tenantId) {
    return (select(db.solicitudes)
          ..where((t) => t.tenantId.equals(tenantId) & t.estado.equals('PENDIENTE'))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  Future<int> insert(SolicitudesCompanion solicitud) {
    return into(db.solicitudes).insert(solicitud);
  }
}
