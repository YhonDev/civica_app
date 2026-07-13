import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// ════════════════════════════════════════════════════════════
// TABLE: conjuntos
// ════════════════════════════════════════════════════════════

class Conjuntos extends Table {
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
  TextColumn get conjuntoId => text()();
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
  TextColumn get etapaId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ════════════════════════════════════════════════════════════
// TABLE: propietarios
// ════════════════════════════════════════════════════════════

class Propietarios extends Table {
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
  TextColumn get propietarioId => text()();
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
  TextColumn get rol => text()(); // ADMIN | COBRADOR | PROPIETARIO
  TextColumn? get propietarioId => text().nullable()();
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
  TextColumn get conjuntoId => text()();
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
  TextColumn get conjuntoId => text()();
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

class CuentasCartera extends Table {
  TextColumn get id => text()();
  TextColumn get propietarioId => text()();
  TextColumn get tenantId => text()();
  TextColumn get conjuntoId => text()();
  TextColumn get frecuencia => text()(); // SEMANAL | QUINCENAL | MENSUAL
  TextColumn get fechaActivacion => text()(); // ISO date
  BoolColumn get activa => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ════════════════════════════════════════════════════════════
// TABLE: cuotas
// ════════════════════════════════════════════════════════════

class Cuotas extends Table {
  TextColumn get id => text()();
  TextColumn get propietarioId => text()();
  TextColumn get tenantId => text()();
  TextColumn? get tarifaId => text().nullable()();
  TextColumn get concepto => text()();
  IntColumn get monto => integer()(); // centavos COP
  IntColumn get montoPagado => integer()();
  TextColumn get periodoInicio => text()(); // ISO date
  TextColumn get periodoFin => text()(); // ISO date
  TextColumn get fechaVencimiento => text()(); // ISO date
  TextColumn get estado => text()(); // PENDIENTE | PARCIAL | PAGADA | VENCIDA
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
  TextColumn? get cuotaId => text().nullable()();
  TextColumn? get serverId => text().nullable()(); // ID asignado por el servidor tras sync
  TextColumn? get solicitudId => text().nullable()(); // Request ID associated with this payment
  IntColumn get monto => integer()(); // centavos COP
  TextColumn get fechaPago => text()(); // ISO date
  TextColumn get cobradorId => text()();
  TextColumn get propietarioId => text()();
  DateTimeColumn? get fechaSync => dateTime().nullable()();
  TextColumn get syncStatus => text()(); // PENDIENTE_SYNC | SYNC_OK | CONFLICTO
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ════════════════════════════════════════════════════════════
// DATABASE
// ════════════════════════════════════════════════════════════

/// Singleton que maneja la base de datos SQLite local.
@DriftDatabase(
  tables: [
    Conjuntos,
    Etapas,
    Casas,
    Propietarios,
    Tenencias,
    Usuarios,
    AsignacionesEtapa,
    Tarifas,
    MontosPredefinidos,
    CuentasCartera,
    Cuotas,
    Pagos,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

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
  final int schemaVersion = 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'civica_pago.db'));
    return NativeDatabase(file);
  });
}
