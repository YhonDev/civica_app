import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/screens/auth/auth_cubit.dart';
import 'package:civica_pago_mobile/features/dashboard/dashboard_screen.dart';
import 'package:civica_pago_mobile/features/dashboard/dashboard_cubit.dart';
import 'package:civica_pago_mobile/features/dashboard/models/dashboard_data.dart';

Widget createDashboardScreen({DashboardCubit? cubit}) {
  final authCubit = AuthCubit();
  authCubit.emit(AuthState.authenticated({
    'nombre': 'Admin Test', 'rol': 'ADMIN', 'email': 'admin@test.com',
  }));
  return MaterialApp(
    home: BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: DashboardScreen(cubit: cubit),
    ),
  );
}

DashboardData _makeData({
  double recaudoMes = 7800000,
  int pagaron = 65,
  int pendientes = 17,
  int totalResidentes = 200,
  int solicitudesPendientes = 5,
  int residentesMora = 6,
}) {
  return DashboardData(
    mes: 3, anio: 2026,
    recaudoMes: recaudoMes, metaMensual: 10560000,
    pagaron: pagaron, pendientes: pendientes, mora: 720000,
    porcentaje: 73.9,
    evolucion: [],
    modalidades: [],
    estadosCobro: [
      const CobroEstadoItem(estado: 'Pagados', porcentaje: 73.9, cantidad: 65),
      const CobroEstadoItem(estado: 'Pendientes', porcentaje: 19.3, cantidad: 17),
      const CobroEstadoItem(estado: 'Revisión', porcentaje: 6.8, cantidad: 0),
    ],
    actividadReciente: [],
    totalResidentes: totalResidentes,
    nuevosResidentesSemana: 3,
    solicitudesPendientes: solicitudesPendientes,
    residentesMora: residentesMora,
    pagosRevision: 2,
    acumuladoAnual: 21000000,
    metaAnual: 126720000,
    historialMeses: [],
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.init(baseUrl: 'http://test.local');
    initializeDateFormatting('es');
    initializeDateFormatting('es_CO');
  });

  group('DashboardScreen — loading state', () {
    testWidgets('sin datos no mustra KPIs', (tester) async {
      final cubit = DashboardCubit();
      await tester.pumpWidget(createDashboardScreen(cubit: cubit));
      await tester.pump();
      expect(find.text('Recaudo del Mes'), findsNothing);
      await tester.pump(const Duration(milliseconds: 1000));
    });
  });

  group('DashboardScreen — loaded state', () {
    testWidgets('KPI card', (tester) async {
      final cubit = DashboardCubit();
      cubit.emit(DashboardLoaded(data: _makeData(), mes: 3, anio: 2026));
      await tester.pumpWidget(createDashboardScreen(cubit: cubit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('Recaudo del Mes'), findsOneWidget);
    });

    testWidgets('Centro de Atención', (tester) async {
      final cubit = DashboardCubit();
      cubit.emit(DashboardLoaded(
        data: _makeData(solicitudesPendientes: 5, residentesMora: 6),
        mes: 3, anio: 2026,
      ));
      await tester.pumpWidget(createDashboardScreen(cubit: cubit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('⚠ CENTRO DE ATENCIÓN'), findsOneWidget);
    });

    testWidgets('Cobros section', (tester) async {
      final cubit = DashboardCubit();
      cubit.emit(DashboardLoaded(
        data: _makeData(pagaron: 65, pendientes: 17),
        mes: 3, anio: 2026,
      ));
      await tester.pumpWidget(createDashboardScreen(cubit: cubit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('COBROS'), findsOneWidget);
      expect(find.text('65'), findsOneWidget);
      expect(find.text('17'), findsOneWidget);
    });

    testWidgets('Comunidad section', (tester) async {
      final cubit = DashboardCubit();
      cubit.emit(DashboardLoaded(
        data: _makeData(totalResidentes: 200),
        mes: 3, anio: 2026,
      ));
      await tester.pumpWidget(createDashboardScreen(cubit: cubit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('COMUNIDAD'), findsOneWidget);
    });
  });

  group('DashboardScreen — error state', () {
    testWidgets('botón de reintentar', (tester) async {
      final cubit = DashboardCubit();
      cubit.emit(const DashboardError('Error al cargar dashboard'));
      await tester.pumpWidget(createDashboardScreen(cubit: cubit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });
}
