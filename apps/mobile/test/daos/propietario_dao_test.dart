import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civica_pago_mobile/core/database/app_database.dart';
import 'package:civica_pago_mobile/core/database/daos/propietario_dao.dart';

/// Helper para crear el fixture de prueba con datos conocidos.
///
/// Estructura:
/// - Etapa "Alfa"   → Casa 101, Casa 102
/// - Etapa "Beta"   → Casa 201
/// - Propietarios:
///   1. Juan Pérez (tel 555-0101) → Casa 101, Etapa Alfa, tenant t1
///   2. María García (tel 555-0102) → Casa 102, Etapa Alfa, tenant t1
///   3. Pedro López (tel 555-0201) → Casa 201, Etapa Beta, tenant t1
///   4. (ausente en buscarCompleto porque tiene tenant t2)
Future<AppDatabase> _crearDb() async {
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final now = DateTime(2025, 1, 1);

  await db.into(db.etapas).insert(EtapasCompanion.insert(
    id: 'ETP_ALFA',
    nombre: 'Etapa Alfa',
    conjuntoId: 'CJTO_1',
    createdAt: now,
  ));
  await db.into(db.etapas).insert(EtapasCompanion.insert(
    id: 'ETP_BETA',
    nombre: 'Etapa Beta',
    conjuntoId: 'CJTO_1',
    createdAt: now,
  ));

  await db.into(db.casas).insert(CasasCompanion.insert(
    id: 'CSA_101',
    direccionInterna: 'Casa 101',
    etapaId: 'ETP_ALFA',
    createdAt: now,
  ));
  await db.into(db.casas).insert(CasasCompanion.insert(
    id: 'CSA_102',
    direccionInterna: 'Casa 102',
    etapaId: 'ETP_ALFA',
    createdAt: now,
  ));
  await db.into(db.casas).insert(CasasCompanion.insert(
    id: 'CSA_201',
    direccionInterna: 'Casa 201',
    etapaId: 'ETP_BETA',
    createdAt: now,
  ));

  await db.into(db.propietarios).insert(PropietariosCompanion.insert(
    id: 'PRO_JUAN',
    nombre: 'Juan Pérez',
    telefono: '555-0101',
    tenantId: 't1',
    email: Value('juan@mail.com'),
    createdAt: now,
    updatedAt: now,
  ));
  await db.into(db.propietarios).insert(PropietariosCompanion.insert(
    id: 'PRO_MARIA',
    nombre: 'María García',
    telefono: '555-0102',
    tenantId: 't1',
    createdAt: now,
    updatedAt: now,
  ));
  await db.into(db.propietarios).insert(PropietariosCompanion.insert(
    id: 'PRO_PEDRO',
    nombre: 'Pedro López',
    telefono: '555-0201',
    tenantId: 't1',
    createdAt: now,
    updatedAt: now,
  ));
  // Propietario de otro tenant (no debe aparecer)
  await db.into(db.propietarios).insert(PropietariosCompanion.insert(
    id: 'PRO_OTRO',
    nombre: 'Otro Tenant',
    telefono: '555-9999',
    tenantId: 't2',
    createdAt: now,
    updatedAt: now,
  ));

  await db.into(db.tenencias).insert(TenenciasCompanion.insert(
    id: 'TEN_JUAN_101',
    propietarioId: 'PRO_JUAN',
    casaId: 'CSA_101',
    fechaInicio: now,
    createdAt: now,
  ));
  await db.into(db.tenencias).insert(TenenciasCompanion.insert(
    id: 'TEN_MARIA_102',
    propietarioId: 'PRO_MARIA',
    casaId: 'CSA_102',
    fechaInicio: now,
    createdAt: now,
  ));
  await db.into(db.tenencias).insert(TenenciasCompanion.insert(
    id: 'TEN_PEDRO_201',
    propietarioId: 'PRO_PEDRO',
    casaId: 'CSA_201',
    fechaInicio: now,
    createdAt: now,
  ));
  // Tenencia del otro tenant
  await db.into(db.tenencias).insert(TenenciasCompanion.insert(
    id: 'TEN_OTRO_101',
    propietarioId: 'PRO_OTRO',
    casaId: 'CSA_101',
    fechaInicio: now,
    createdAt: now,
  ));

  return db;
}

void main() {
  late AppDatabase db;
  late PropietarioDao dao;

  setUp(() async {
    db = await _crearDb();
    dao = PropietarioDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('buscarCompleto', () {
    test('sin filtros retorna todos los propietarios del tenant', () async {
      final resultados = await dao.buscarCompleto(tenantId: 't1');

      expect(resultados.length, 3);
      expect(resultados.map((r) => r.propietario.nombre),
          containsAll(['Juan Pérez', 'María García', 'Pedro López']));
    });

    test('filtra por tenant — no incluye propietarios de otro tenant', () async {
      final resultados = await dao.buscarCompleto(tenantId: 't2');

      expect(resultados.length, 1);
      expect(resultados.first.propietario.nombre, 'Otro Tenant');
    });

    test('filtro por nombre exacto', () async {
      final resultados =
          await dao.buscarCompleto(tenantId: 't1', nombre: 'Juan Pérez');

      expect(resultados.length, 1);
      expect(resultados.first.propietario.nombre, 'Juan Pérez');
    });

    test('filtro por nombre parcial (LIKE)', () async {
      final resultados =
          await dao.buscarCompleto(tenantId: 't1', nombre: 'Pérez');

      expect(resultados.length, 1);
      expect(resultados.first.propietario.nombre, 'Juan Pérez');
    });

    test('filtro por nombre parcial sin acentos — LIKE en SQLite no empareja é con e',
        () async {
      final resultados =
          await dao.buscarCompleto(tenantId: 't1', nombre: 'Perez');

      // SQLite LIKE no empareja 'e' con 'é' por defecto
      // Este test documenta ese comportamiento: no encuentra a 'Juan Pérez'
      expect(resultados, isEmpty);
    });

    test('filtro por teléfono', () async {
      final resultados =
          await dao.buscarCompleto(tenantId: 't1', telefono: '555-0102');

      expect(resultados.length, 1);
      expect(resultados.first.propietario.nombre, 'María García');
    });

    test('filtro por teléfono parcial', () async {
      final resultados =
          await dao.buscarCompleto(tenantId: 't1', telefono: '0102');

      expect(resultados.length, 1);
      expect(resultados.first.propietario.nombre, 'María García');
    });

    test('filtro por etapa', () async {
      final resultados =
          await dao.buscarCompleto(tenantId: 't1', etapaId: 'ETP_ALFA');

      expect(resultados.length, 2);
      expect(resultados.map((r) => r.propietario.nombre),
          containsAll(['Juan Pérez', 'María García']));
    });

    test('filtro por etapa Beta retorna 1 propietario', () async {
      final resultados =
          await dao.buscarCompleto(tenantId: 't1', etapaId: 'ETP_BETA');

      expect(resultados.length, 1);
      expect(resultados.first.propietario.nombre, 'Pedro López');
    });

    test('filtro por casa', () async {
      final resultados =
          await dao.buscarCompleto(tenantId: 't1', casaId: 'CSA_101');

      expect(resultados.length, 1);
      expect(resultados.first.propietario.nombre, 'Juan Pérez');
    });

    test('filtro combinado etapa + nombre', () async {
      final resultados = await dao.buscarCompleto(
        tenantId: 't1',
        etapaId: 'ETP_ALFA',
        nombre: 'María',
      );

      expect(resultados.length, 1);
      expect(resultados.first.propietario.nombre, 'María García');
    });

    test('filtro combinado etapa + teléfono', () async {
      final resultados = await dao.buscarCompleto(
        tenantId: 't1',
        etapaId: 'ETP_ALFA',
        telefono: '555-0101',
      );

      expect(resultados.length, 1);
      expect(resultados.first.propietario.nombre, 'Juan Pérez');
    });

    test('sin resultados retorna lista vacía', () async {
      final resultados =
          await dao.buscarCompleto(tenantId: 't1', nombre: 'NoExiste');

      expect(resultados, isEmpty);
    });

    test('propietario tiene datos de casa y etapa en el resultado', () async {
      final resultados =
          await dao.buscarCompleto(tenantId: 't1', nombre: 'Juan Pérez');

      expect(resultados.length, 1);
      final item = resultados.first;
      expect(item.casaDireccion, 'Casa 101');
      expect(item.casaId, 'CSA_101');
      expect(item.etapaNombre, 'Etapa Alfa');
      expect(item.etapaId, 'ETP_ALFA');
    });

    test('propietario sin email tiene email null', () async {
      final resultados =
          await dao.buscarCompleto(tenantId: 't1', nombre: 'María García');

      expect(resultados.length, 1);
      expect(resultados.first.propietario.email, isNull);
    });

    test('propietario con email se retorna correctamente', () async {
      final resultados =
          await dao.buscarCompleto(tenantId: 't1', nombre: 'Juan Pérez');

      expect(resultados.length, 1);
      expect(resultados.first.propietario.email, 'juan@mail.com');
    });

    test('resultados ordenados alfabéticamente por nombre', () async {
      final resultados = await dao.buscarCompleto(tenantId: 't1');

      expect(resultados.length, 3);
      expect(resultados[0].propietario.nombre, 'Juan Pérez');
      expect(resultados[1].propietario.nombre, 'María García');
      expect(resultados[2].propietario.nombre, 'Pedro López');
    });
  });
}
