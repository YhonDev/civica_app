import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import 'connection/connection.dart' as conn;

import 'daos/residente_dao.dart';
import 'daos/cobro_dao.dart';
import 'daos/pago_dao.dart';
import 'daos/actividad_dao.dart';

part 'app_database.g.dart';

// ════════════════════════════════════════════════════════════
// TABLE: conjuntos
// ════════════════════════════════════════════════════════════

class Proyectos extends Table {
  TextColumn get id => text()();
  TextColumn get nombre => text()();
  TextColumn get tenantId => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ════════════════════════════════════════════════════════════
// TABLE: etapas
// ════════════════════════════════════════════════════════════

class Etapas extends Table {
  TextColumn get id => text()();
  TextColumn get nombre => text()();
  TextColumn get proyectoId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ════════════════════════════════════════════════════════════
// TABLE: manzanas
// ════════════════════════════════════════════════════════════

class Manzanas extends Table {
  TextColumn get id => text()();
  TextColumn get nombre => text()();
  TextColumn get etapaId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ════════════════════════════════════════════════════════════
// TABLE: casas
// ════════════════════════════════════════════════════════════

class Casas extends Table {
  TextColumn get id => text()();
  TextColumn get direccionInterna => text()();
  TextColumn get manzanaId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ════════════════════════════════════════════════════════════
// TABLE: residentes
// ════════════════════════════════════════════════════════════

class Residentes extends Table {
  TextColumn get id => text()();
  TextColumn get nombre => text()();
  TextColumn get telefono => text()();
  TextColumn? get email => text().nullable()();
  TextColumn get tenantId => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ════════════════════════════════════════════════════════════
// TABLE: tenencias
// ════════════════════════════════════════════════════════════

class Tenencias extends Table {
  TextColumn get id => text()();
  TextColumn get residenteId => text()();
  TextColumn get casaId => text()();
  DateTimeColumn get fechaInicio => dateTime()();
  DateTimeColumn? get fechaFin => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ════════════════════════════════════════════════════════════
// TABLE: usuarios
// ════════════════════════════════════════════════════════════

class Usuarios extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get nombre => text()();
  TextColumn get rol => text()(); // ADMIN | COBRADOR | RESIDENTE
  TextColumn? get residenteId => text().nullable()();
  TextColumn get tenantId => text()();
  BoolColumn get activo => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ════════════════════════════════════════════════════════════
// TABLE: asignaciones_etapa
// ════════════════════════════════════════════════════════════

class AsignacionesEtapa extends Table {
  TextColumn get id => text()();
  TextColumn get usuarioId => text()();
  TextColumn get etapaId => text()();
  TextColumn get tenantId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ════════════════════════════════════════════════════════════
// TABLE: tarifas
// ════════════════════════════════════════════════════════════

class Tarifas extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get proyectoId => text()();
  TextColumn get frecuencia => text()(); // SEMANAL | QUINCENAL | MENSUAL
  IntColumn get monto => integer()(); // centavos COP
  TextColumn get fechaVigencia => text()(); // ISO date
  BoolColumn get activa => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ════════════════════════════════════════════════════════════
// TABLE: montos_predefinidos
// ════════════════════════════════════════════════════════════

class MontosPredefinidos extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get proyectoId => text()();
  IntColumn get monto => integer()(); // centavos COP
  TextColumn get descripcion => text()();
  BoolColumn get activo => boolean()();
  IntColumn get orden => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ════════════════════════════════════════════════════════════
// TABLE: cuentas_cartera
// ════════════════════════════════════════════════════════════

class PlanesDeCobro extends Table {
  TextColumn get id => text()();
  TextColumn get residenteId => text()();
  TextColumn get tenantId => text()();
  TextColumn get proyectoId => text()();
  TextColumn get frecuencia => text()(); // SEMANAL | QUINCENAL | MENSUAL
  TextColumn get fechaActivacion => text()(); // ISO date
  BoolColumn get activa => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ════════════════════════════════════════════════════════════
// TABLE: meses_de_cobro
// ════════════════════════════════════════════════════════════

class MesesDeCobro extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get proyectoId => text()();
  IntColumn get mes => integer()();
  IntColumn get anio => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ════════════════════════════════════════════════════════════
// TABLE: cuotas (Cobros)
// ════════════════════════════════════════════════════════════

class Cobros extends Table {
  TextColumn get id => text()();
  TextColumn get residenteId => text()();
  TextColumn get tenantId => text()();
  TextColumn? get tarifaId => text().nullable()();
  TextColumn? get mesDeCobroId => text().nullable()();
  TextColumn get concepto => text()();
  IntColumn get monto => integer()(); // centavos COP
  IntColumn get montoPagado => integer()();
  TextColumn get periodoInicio => text()(); // ISO date
  TextColumn get periodoFin => text()(); // ISO date
  TextColumn get fechaVencimiento => text()(); // ISO date
  TextColumn get estado => text()(); // PROGRAMADA | PENDIENTE | SOLICITADA | EN_COBRO | PAGO_PARCIAL | PAGADA | VENCIDA
  BoolColumn get notificacionEnviada => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ════════════════════════════════════════════════════════════
// TABLE: pagos
// ════════════════════════════════════════════════════════════

class Pagos extends Table {
  TextColumn get id => text()();
  TextColumn get clientPaymentId => text()();
  TextColumn get tenantId => text()();
  TextColumn? get cobroId => text().nullable()();
  TextColumn? get serverId => text().nullable()(); // ID asignado por el servidor tras sync
  TextColumn? get solicitudId => text().nullable()(); // Request ID associated with this payment
  IntColumn get monto => integer()(); // centavos COP
  TextColumn get fechaPago => text()(); // ISO date
  TextColumn get cobradorId => text()();
  TextColumn get residenteId => text()();
  DateTimeColumn? get fechaSync => dateTime().nullable()();
  TextColumn get syncStatus => text()(); // PENDIENTE_SYNC | SYNC_OK | CONFLICTO
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ════════════════════════════════════════════════════════════
// TABLE: solicitudes
// ════════════════════════════════════════════════════════════

class Solicitudes extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get residenteId => text()();
  TextColumn get casaId => text()();
  TextColumn get tipo => text()(); // COBRO | REVISION
  TextColumn get estado => text()(); // PENDIENTE | ATENDIDA | RECHAZADA
  TextColumn? get observacion => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ════════════════════════════════════════════════════════════
// TABLE: actividades
// ════════════════════════════════════════════════════════════

class Actividades extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId => text()();
  TextColumn get tipo => text()(); // CASA_CREADA, RESIDENTE_ASIGNADO, PAGO_REGISTRADO, etc.
  TextColumn get entidadId => text()(); // ID of the related entity
  TextColumn get entidadTipo => text()(); // CASA, RESIDENTE, PAGO, CUOTA, etc.
  TextColumn? get descripcion => text().nullable()();
  TextColumn? get usuarioId => text().nullable()(); // Who performed it
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ════════════════════════════════════════════════════════════
// DATABASE
// ════════════════════════════════════════════════════════════

/// Singleton que maneja la base de datos SQLite local.
@DriftDatabase(
  tables: [
    Proyectos,
    Etapas,
    Manzanas,
    Casas,
    Residentes,
    Tenencias,
    Usuarios,
    AsignacionesEtapa,
    Tarifas,
    MontosPredefinidos,
    PlanesDeCobro,
    MesesDeCobro,
    Cobros,
    Pagos,
    Solicitudes,
    Actividades,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(conn.openConnection());

  // DAOs
  ResidenteDao get residenteDao => ResidenteDao(this);
  CobroDao get cobroDao => CobroDao(this);
  PagoDao get pagoDao => PagoDao(this);
  ActividadDao get actividadDao => ActividadDao(this);

  AppDatabase.forTesting(super.executor);

  static AppDatabase? _instance;

  /// Inicializa la instancia singleton. Llamar una vez al iniciar la app.
  static Future<AppDatabase> init() async {
    _instance ??= AppDatabase();
    return _instance!;
  }

  /// Acceso a la instancia singleton.
  static AppDatabase get instance {
    if (_instance == null) {
      throw StateError('AppDatabase no inicializado. Llama init() primero.');
    }
    return _instance!;
  }

  /// Libera recursos. Útil en tests.
  static Future<void> reset() async {
    await _instance?.close();
    _instance = null;
  }
  /// Inyecta una instancia para testing. Solo usar en tests.
  @visibleForTesting
  static void setTestingInstance(AppDatabase db) {
    _instance = db;
  }


  @override
  final int schemaVersion = 2;
  
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // Se sugiere recrear la BD en dev, o escribir la migración formal:
            await m.createTable(manzanas);
            await m.createTable(mesesDeCobro);
            await m.createTable(solicitudes);
            await m.createTable(actividades);
            
            // Alterar casas para agregar manzanaId y migrar datos
            await m.addColumn(casas, casas.manzanaId);
            await m.addColumn(cobros, cobros.mesDeCobroId);
          }
        },
      );
}

