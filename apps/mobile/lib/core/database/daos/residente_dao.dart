import 'package:drift/drift.dart';

import '../app_database.dart';

/// DAO para operaciones con residentes en SQLite local.
/// Usado por búsqueda offline y registro inline.
class ResidenteDao extends DatabaseAccessor<AppDatabase> {
  ResidenteDao(super.db);

  /// Inserta o reemplaza un lote de residentes (desde sync).
  Future<void> upsertResidentes(List<ResidentesCompanion> residentes) {
    return batch((batch) {
      for (final p in residentes) {
        batch.insert(db.residentes, p, mode: InsertMode.insertOrReplace);
      }
    });
  }

  /// Busca residentes por nombre (LIKE) o teléfono.
  Future<List<Residente>> buscar({
    required String tenantId,
    String? nombre,
    String? telefono,
    String? etapaId,
    String? casaId,
  }) {
    final query = db.select(db.residentes)
      ..where((t) => t.tenantId.equals(tenantId));

    if (nombre != null && nombre.isNotEmpty) {
      query.where((t) => t.nombre.like('%$nombre%'));
    }
    if (telefono != null && telefono.isNotEmpty) {
      query.where((t) => t.telefono.like('%$telefono%'));
    }
    // Filtros por etapa/casa requieren join con tenencias → se hacen en
    // [buscarPorEtapaOCasa] para mantenerlo simple.
    return query.get();
  }

  /// Busca residentes que tengan tenencias en una etapa o casa específica.
  Future<List<Residente>> buscarPorEtapaOCasa({
    required String tenantId,
    String? etapaId,
    String? casaId,
  }) {
    // NOTA: drift no soporta JOINs en DAO puro sin queries SQL.
    // Esta implementación hace dos pasos: primero obtiene residenteIds
    // desde tenencias filtradas, luego busca los residentes.
    return _buscarConJoin(
      tenantId: tenantId,
      etapaId: etapaId,
      casaId: casaId,
    );
  }

  Future<List<Residente>> _buscarConJoin({
    required String tenantId,
    String? etapaId,
    String? casaId,
  }) async {
    // Construimos sub-query SQL directamente para el JOIN.
    // drift permite custom SQL con `customSelect`.
    final whereClauses = <String>['p.tenant_id = ?'];
    final variables = <Variable<Object>>[Variable<String>(tenantId)];

    if (etapaId != null) {
      whereClauses.add('c.etapa_id = ?');
      variables.add(Variable<String>(etapaId));
    }
    if (casaId != null) {
      whereClauses.add('t.casa_id = ?');
      variables.add(Variable<String>(casaId));
    }

    final sql = '''
      SELECT DISTINCT p.*
      FROM residentes p
      INNER JOIN tenencias t ON t.residente_id = p.id
      INNER JOIN casas c ON c.id = t.casa_id
      WHERE ${whereClauses.join(' AND ')}
      ORDER BY p.nombre ASC
    ''';

    final result = await db.customSelect(sql, variables: variables).get();

    return result.map((row) {
      return Residente(
        id: row.read<String>('id'),
        nombre: row.read<String>('nombre'),
        telefono: row.read<String>('telefono'),
        email: row.read<String?>('email'),
        tenantId: row.read<String>('tenant_id'),
        createdAt: row.read<DateTime>('created_at'),
        updatedAt: row.read<DateTime>('updated_at'),
      );
    }).toList();
  }

  /// Obtiene un residente por ID.
  Future<Residente?> getById(String id) {
    return (db.select(db.residentes)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Busca residentes combinando filtros de texto (nombre/tel) con etapa/casa.
  /// Retorna datos planos con info de la etapa y casa asociadas.
  Future<List<ResidenteConInfo>> buscarCompleto({
    required String tenantId,
    String? nombre,
    String? telefono,
    String? etapaId,
    String? casaId,
  }) async {
    final where = <String>['p.tenant_id = ?'];
    final vars = <Variable<Object>>[Variable<String>(tenantId)];

    if (nombre != null && nombre.isNotEmpty) {
      where.add('p.nombre LIKE ?');
      vars.add(Variable<String>('%$nombre%'));
    }
    if (telefono != null && telefono.isNotEmpty) {
      where.add('p.telefono LIKE ?');
      vars.add(Variable<String>('%$telefono%'));
    }
    if (etapaId != null) {
      where.add('c.etapa_id = ?');
      vars.add(Variable<String>(etapaId));
    }
    if (casaId != null) {
      where.add('t.casa_id = ?');
      vars.add(Variable<String>(casaId));
    }

    final sql = '''
      SELECT DISTINCT p.*,
             c.direccion_interna AS casa_direccion,
             c.id AS casa_id,
             e.nombre AS etapa_nombre,
             e.id AS etapa_id
      FROM residentes p
      INNER JOIN tenencias t ON t.residente_id = p.id
      INNER JOIN casas c ON c.id = t.casa_id
      INNER JOIN etapas e ON e.id = c.etapa_id
      WHERE ${where.join(' AND ')}
      ORDER BY p.nombre ASC
    ''';

    final result = await db.customSelect(sql, variables: vars).get();

    return result.map((row) {
      return ResidenteConInfo(
        residente: Residente(
          id: row.read<String>('id'),
          nombre: row.read<String>('nombre'),
          telefono: row.read<String>('telefono'),
          email: row.read<String?>('email'),
          tenantId: row.read<String>('tenant_id'),
          createdAt: row.read<DateTime>('created_at'),
          updatedAt: row.read<DateTime>('updated_at'),
        ),
        casaDireccion: row.read<String>('casa_direccion'),
        casaId: row.read<String>('casa_id'),
        etapaNombre: row.read<String>('etapa_nombre'),
        etapaId: row.read<String>('etapa_id'),
      );
    }).toList();
  }

  /// Inserta un nuevo residente (para registro inline offline).
  Future<void> insert(ResidentesCompanion residente) {
    return db.into(db.residentes).insert(residente);
  }

  /// Inserta un residente y su tenencia en una transacción batch.
  /// Crea ambos registros atómicamente para mantener la consistencia.
  Future<void> insertConTenencia({
    required ResidentesCompanion residente,
    required String casaId,
    DateTime? fechaInicio,
  }) async {
    final tenenciaId =
        'TEN_${DateTime.now().microsecondsSinceEpoch}_${residente.id.value.substring(0, 4)}';
    final inicio = fechaInicio ?? DateTime.now();

    await batch((batch) {
      batch.insert(db.residentes, residente);
      batch.insert(
        db.tenencias,
        TenenciasCompanion.insert(
          id: tenenciaId,
          residenteId: residente.id.value,
          casaId: casaId,
          fechaInicio: inicio,
          createdAt: DateTime.now(),
        ),
      );
    });
  }
}

/// Resultado del método [ResidenteDao.buscarCompleto].
/// Contiene datos del residente junto con su casa y etapa asociadas.
class ResidenteConInfo {
  final Residente residente;
  final String casaDireccion;
  final String casaId;
  final String etapaNombre;
  final String etapaId;

  const ResidenteConInfo({
    required this.residente,
    required this.casaDireccion,
    required this.casaId,
    required this.etapaNombre,
    required this.etapaId,
  });
}
