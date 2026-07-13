import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/features/dashboard/dashboard_cubit.dart';
import 'package:civica_pago_mobile/features/dashboard/models/dashboard_data.dart';
import 'package:civica_pago_mobile/features/dashboard/dashboard_repository.dart';

/// Fake [DashboardRepository] with configurable results.
/// Parent constructor accesses ApiClient.instance, so ApiClient.init() must be called first.
class FakeDashboardRepository extends DashboardRepository {
  final DashboardData? data;
  final Object? loadError;

  FakeDashboardRepository({this.data, this.loadError}) : super();

  @override
  Future<DashboardData> getDashboard(int mes, int anio) async {
    if (loadError != null) throw loadError!;
    return data ?? _defaultData(mes, anio);
  }

  DashboardData _defaultData(int mes, int anio) {
    return DashboardData(
      mes: mes, anio: anio,
      recaudoMes: 7800000, metaMensual: 10560000,
      pagaron: 65, pendientes: 17, mora: 720000,
      porcentaje: 73.9,
      evolucion: [],
      modalidades: [],
      estadosCobro: [
        const CobroEstadoItem(estado: 'Pagados', porcentaje: 73.9, cantidad: 65),
        const CobroEstadoItem(estado: 'Pendientes', porcentaje: 19.3, cantidad: 17),
        const CobroEstadoItem(estado: 'Revisión', porcentaje: 6.8, cantidad: 0),
      ],
      actividadReciente: [],
      totalPropietarios: 200, nuevosPropietariosSemana: 3,
      solicitudesPendientes: 5, propietariosMora: 6, pagosRevision: 2,
      acumuladoAnual: 21000000, metaAnual: 126720000,
      historialMeses: [],
    );
  }
}

DashboardData _dummyData(int mes, int anio) {
  return DashboardData(
    mes: mes, anio: anio,
    recaudoMes: 0, metaMensual: 0,
    pagaron: 0, pendientes: 0, mora: 0, porcentaje: 0,
    evolucion: [], modalidades: [],
    estadosCobro: [
      const CobroEstadoItem(estado: 'Pagados', porcentaje: 0, cantidad: 0),
      const CobroEstadoItem(estado: 'Pendientes', porcentaje: 0, cantidad: 0),
      const CobroEstadoItem(estado: 'Revisión', porcentaje: 0, cantidad: 0),
    ],
    actividadReciente: [],
    totalPropietarios: 0, nuevosPropietariosSemana: 0,
    solicitudesPendientes: 0, propietariosMora: 0, pagosRevision: 0,
    acumuladoAnual: 0, metaAnual: 0, historialMeses: [],
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.init(baseUrl: 'http://test.local');
  });

  // ════════════════════════════════════════════════════════════
  // DashboardState
  // ════════════════════════════════════════════════════════════
  group('DashboardState', () {
    test('DashboardInitial es el estado por defecto', () {
      const state = DashboardInitial();
      expect(state, isA<DashboardState>());
    });

    test('DashboardLoading es válido', () {
      const state = DashboardLoading();
      expect(state, isA<DashboardState>());
    });

    test('DashboardLoaded guarda data, mes, anio', () {
      final data = _dummyData(3, 2026);
      final state = DashboardLoaded(data: data, mes: 3, anio: 2026);
      expect(state.data, data);
      expect(state.mes, 3);
      expect(state.anio, 2026);
    });

    test('DashboardError guarda mensaje', () {
      const state = DashboardError('Error');
      expect(state.message, 'Error');
    });

    test('Equatable — DashboardLoaded igualdad', () {
      final data = _dummyData(3, 2026);
      final a = DashboardLoaded(data: data, mes: 3, anio: 2026);
      final b = DashboardLoaded(data: data, mes: 3, anio: 2026);
      final c = DashboardLoaded(data: data, mes: 4, anio: 2026);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('Equatable — DashboardError igualdad por mensaje', () {
      const a = DashboardError('Error');
      const b = DashboardError('Error');
      const c = DashboardError('Otro');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  // ════════════════════════════════════════════════════════════
  // DashboardCubit
  // ════════════════════════════════════════════════════════════
  group('DashboardCubit.loadDashboard', () {
    test('initial → loading → loaded en éxito', () async {
      final repo = FakeDashboardRepository();
      final cubit = DashboardCubit(repository: repo);
      addTearDown(() => cubit.close());

      final states = <Type>[];
      cubit.stream.listen((s) => states.add(s.runtimeType));

      expect(cubit.state, isA<DashboardInitial>());
      await cubit.loadDashboard(3, 2026);

      expect(states, contains(DashboardLoading));
      expect(cubit.state, isA<DashboardLoaded>());
      expect((cubit.state as DashboardLoaded).mes, 3);
      expect((cubit.state as DashboardLoaded).anio, 2026);
    });

    test('data del repositorio se refleja', () async {
      final repo = FakeDashboardRepository();
      final cubit = DashboardCubit(repository: repo);
      addTearDown(() => cubit.close());

      await cubit.loadDashboard(6, 2027);
      final state = cubit.state as DashboardLoaded;
      expect(state.mes, 6);
      expect(state.anio, 2027);
    });

    test('error del repositorio → DashboardError', () async {
      final repo = FakeDashboardRepository(loadError: Exception('Sin conexión'));
      final cubit = DashboardCubit(repository: repo);
      addTearDown(() => cubit.close());

      await cubit.loadDashboard(3, 2026);
      expect(cubit.state, isA<DashboardError>());
      expect((cubit.state as DashboardError).message, contains('Sin conexión'));
    });
  });

  group('DashboardCubit.changeMonth', () {
    test('cambia mes y recarga', () async {
      final repo = FakeDashboardRepository();
      final cubit = DashboardCubit(repository: repo);
      addTearDown(() => cubit.close());

      cubit.changeMonth(12, 2025);
      await Future.delayed(Duration.zero);

      expect(cubit.state, isA<DashboardLoaded>());
      expect((cubit.state as DashboardLoaded).mes, 12);
      expect((cubit.state as DashboardLoaded).anio, 2025);
    });


  });

  group('DashboardCubit.loadCurrentMonth', () {
    test('carga el mes y año actual', () async {
      final repo = FakeDashboardRepository();
      final cubit = DashboardCubit(repository: repo);
      addTearDown(() => cubit.close());
      final now = DateTime.now();

      await cubit.loadCurrentMonth();

      expect(cubit.state, isA<DashboardLoaded>());
      expect((cubit.state as DashboardLoaded).mes, now.month);
      expect((cubit.state as DashboardLoaded).anio, now.year);
    });
  });
}
