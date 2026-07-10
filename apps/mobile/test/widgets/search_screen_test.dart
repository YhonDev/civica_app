import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civica_pago_mobile/core/database/app_database.dart';
import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/screens/auth/auth_cubit.dart';
import 'package:civica_pago_mobile/screens/search_screen.dart';

/// Crea la base de datos en memoria con datos de prueba.
///
/// Estructura:
/// - Etapa "Alfa"   → Casa 101, Casa 102
/// - Etapa "Beta"   → Casa 201
/// - Propietarios:
///   1. Juan Pérez → Casa 101, Etapa Alfa
///   2. María García → Casa 102, Etapa Alfa
///   3. Pedro López → Casa 201, Etapa Beta
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
    tenantId: 'default',
    email: Value('juan@mail.com'),
    createdAt: now,
    updatedAt: now,
  ));
  await db.into(db.propietarios).insert(PropietariosCompanion.insert(
    id: 'PRO_MARIA',
    nombre: 'María García',
    telefono: '555-0102',
    tenantId: 'default',
    createdAt: now,
    updatedAt: now,
  ));
  await db.into(db.propietarios).insert(PropietariosCompanion.insert(
    id: 'PRO_PEDRO',
    nombre: 'Pedro López',
    telefono: '555-0201',
    tenantId: 'default',
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

  return db;
}

/// Widget de prueba que envuelve SearchScreen con los providers necesarios.
/// No usa _AuthGate para evitar depender del flujo de autenticación real.
Widget _crearApp({required AuthCubit authCubit}) {
  return MaterialApp(
    home: BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: const SearchScreen(),
    ),
  );
}

void main() {
  late AppDatabase db;
  late AuthCubit authCubit;

  setUp(() async {
    // Mock SharedPreferences para que el AuthApi funcione sin storage real
    SharedPreferences.setMockInitialValues({'access_token': 'test_token'});

    // Inicializar ApiClient para el AuthApi
    ApiClient.init(baseUrl: 'http://test.local');

    // Crear BD en memoria y asignarla como singleton
    db = await _crearDb();
    AppDatabase.setTestingInstance(db);

    // Crear AuthCubit que reporta autenticado
    authCubit = AuthCubit()..checkSession();
    await Future.delayed(Duration.zero); // esperar que checkSession complete
  });

  tearDown(() async {
    await db.close();
    await AppDatabase.reset();
  });

  testWidgets('renderiza estado inicial — muestra placeholder de búsqueda',
      (tester) async {
    await tester.pumpWidget(_crearApp(authCubit: authCubit));
    await tester.pumpAndSettle();

    expect(find.text('Selecciona filtros y presiona Buscar'), findsOneWidget);
    expect(find.text('Buscar Propietarios'), findsOneWidget);
  });

  testWidgets('AppBar muestra botón de logout y filtro', (tester) async {
    await tester.pumpWidget(_crearApp(authCubit: authCubit));
    await tester.pumpAndSettle();

    // Botón de cerrar sesión siempre visible
    expect(find.byIcon(Icons.logout), findsOneWidget);
    // Botón de limpiar filtros no visible inicialmente
    expect(find.byIcon(Icons.filter_alt_off), findsNothing);
  });

  testWidgets('FAB "Nuevo propietario" está presente', (tester) async {
    await tester.pumpWidget(_crearApp(authCubit: authCubit));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo propietario'), findsOneWidget);
  });

  testWidgets('dropdown de etapas carga las opciones', (tester) async {
    await tester.pumpWidget(_crearApp(authCubit: authCubit));
    await tester.pumpAndSettle();
    // Pump adicional para asegurar que _loadEtapas completó
    await tester.pump();

    // Abrir dropdown de etapa
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();

    // Debería mostrar "Etapa Alfa" y "Etapa Beta"
    expect(find.text('Etapa Alfa'), findsWidgets); // aparece en dropdown y card
    expect(find.text('Etapa Beta'), findsWidgets);
  });

  testWidgets('búsqueda retorna resultados', (tester) async {
    await tester.pumpWidget(_crearApp(authCubit: authCubit));
    await tester.pumpAndSettle();
    await tester.pump(); // esperar _loadEtapas

    // No hay filtros — presionar Buscar directamente
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();

    // Deberían aparecer los 3 propietarios
    expect(find.textContaining('propietarios encontrados'), findsOneWidget);
    expect(find.text('Juan Pérez'), findsOneWidget);
    expect(find.text('María García'), findsOneWidget);
    expect(find.text('Pedro López'), findsOneWidget);
  });

  testWidgets('búsqueda con filtro de nombre retorna solo ese propietario',
      (tester) async {
    await tester.pumpWidget(_crearApp(authCubit: authCubit));
    await tester.pumpAndSettle();
    await tester.pump(); // esperar _loadEtapas

    // Escribir nombre
    await tester.enterText(
      find.byType(TextField).first,
      'Juan',
    );

    // Presionar Buscar
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 propietario'), findsOneWidget);
    expect(find.text('Juan Pérez'), findsOneWidget);
    expect(find.text('María García'), findsNothing);
  });

  testWidgets('búsqueda sin resultados muestra mensaje', (tester) async {
    await tester.pumpWidget(_crearApp(authCubit: authCubit));
    await tester.pumpAndSettle();
    await tester.pump(); // esperar _loadEtapas

    // Escribir nombre que no existe
    await tester.enterText(
      find.byType(TextField).first,
      'NoExiste',
    );

    // Presionar Buscar
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();

    expect(find.text('No se encontraron resultados'), findsOneWidget);
  });

  testWidgets('botón limpiar filtros aparece después de buscar',
      (tester) async {
    await tester.pumpWidget(_crearApp(authCubit: authCubit));
    await tester.pumpAndSettle();
    await tester.pump(); // esperar _loadEtapas

    // Buscar primero
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();

    // Botón de limpiar debe aparecer
    expect(find.byIcon(Icons.filter_alt_off), findsOneWidget);

    // Presionar limpiar
    await tester.tap(find.byIcon(Icons.filter_alt_off));
    await tester.pumpAndSettle();

    // Debe volver al estado inicial
    expect(find.text('Selecciona filtros y presiona Buscar'), findsOneWidget);
  });

  testWidgets('seleccionar etapa filtra casas en dropdown', (tester) async {
    await tester.pumpWidget(_crearApp(authCubit: authCubit));
    await tester.pumpAndSettle();
    await tester.pump(); // esperar _loadEtapas

    // Abrir dropdown de etapa
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();

    // Seleccionar "Etapa Alfa"
    await tester.tap(find.text('Etapa Alfa').last);
    await tester.pumpAndSettle();
    await tester.pump(); // esperar _loadCasas

    // Abrir dropdown de casa
    final casaDropdowns = find.byType(DropdownButtonFormField<String>);
    expect(casaDropdowns, findsNWidgets(2)); // etapa + casa

    await tester.tap(casaDropdowns.last);
    await tester.pumpAndSettle();

    // Debería mostrar "Casa 101" y "Casa 102"
    expect(find.text('Casa 101'), findsWidgets);
    expect(find.text('Casa 102'), findsWidgets);
    // "Casa 201" no debería aparecer (es de Etapa Beta)
    expect(find.text('Casa 201'), findsNothing);
  });

  testWidgets('FAB abre modal de registro de propietario', (tester) async {
    await tester.pumpWidget(_crearApp(authCubit: authCubit));
    await tester.pumpAndSettle();
    await tester.pump(); // esperar _loadEtapas

    // Presionar FAB "Nuevo propietario"
    await tester.tap(find.text('Nuevo propietario'));
    await tester.pumpAndSettle();

    // El modal debe mostrar el formulario
    expect(find.text('Nuevo propietario'), findsNWidgets(2)); // FAB + título
    expect(find.text('Guardar propietario'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });
}
