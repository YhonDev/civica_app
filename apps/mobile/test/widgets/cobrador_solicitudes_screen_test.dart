import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:civica_pago_mobile/features/dashboard_cobrador/cobrador_solicitudes_screen.dart';
import 'package:civica_pago_mobile/features/dashboard_cobrador/casas_cubit.dart';
import 'package:civica_pago_mobile/features/dashboard_cobrador/dashboard_cobrador_cubit.dart';
import 'package:civica_pago_mobile/features/dashboard_cobrador/widgets/cobrador_solicitud_card.dart';
import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'mock_http_adapter.dart';

void main() {
  setUp(() {
    ApiClient.init(baseUrl: 'http://test.local');
    ApiClient.setHttpClientAdapter(MockHttpAdapter());
  });

  group('CobradorSolicitudCard', () {
    testWidgets('muestra estado En espera y botón En camino cuando no está en camino', (tester) async {
      var enCaminoPressed = false;
      var cobrarPressed = false;

      final solicitud = {
        'id': 'sol-1',
        'estado': 'EN_ESPERA',
        'residenteNombre': 'Camilo Torres',
        'manzanaNombre': 'Manzana A',
        'casaDireccion': 'Casa 1',
        'descripcion': 'Cobrar en la tarde',
        'saldo': 10000,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CobradorSolicitudCard(
              solicitud: solicitud,
              compact: true,
              onMarcarEnCamino: () => enCaminoPressed = true,
              onCobrar: () => cobrarPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Camilo Torres'), findsOneWidget);
      expect(find.text('En espera'), findsOneWidget);
      expect(find.text('En camino'), findsOneWidget);
      expect(find.text('Cobrar'), findsNothing);

      await tester.tap(find.text('En camino'));
      expect(enCaminoPressed, isTrue);
      expect(cobrarPressed, isFalse);
    });

    testWidgets('muestra botón Cobrar cuando el estado es EN_CAMINO', (tester) async {
      var enCaminoPressed = false;
      var cobrarPressed = false;

      final solicitud = {
        'id': 'sol-2',
        'estado': 'EN_CAMINO',
        'residenteNombre': 'Carmen Ramos',
        'manzanaNombre': 'Manzana B',
        'casaDireccion': 'Casa 5',
        'descripcion': 'Esperando',
        'saldo': 20000,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CobradorSolicitudCard(
              solicitud: solicitud,
              compact: true,
              onMarcarEnCamino: () => enCaminoPressed = true,
              onCobrar: () => cobrarPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Carmen Ramos'), findsOneWidget);
      expect(find.text('En camino'), findsOneWidget); // Status chip
      expect(find.text('Cobrar'), findsOneWidget); // Action button
      expect(find.widgetWithText(OutlinedButton, 'En camino'), findsNothing);

      await tester.tap(find.text('Cobrar'));
      expect(cobrarPressed, isTrue);
      expect(enCaminoPressed, isFalse);
    });

    testWidgets('CobradorSolicitudesScreen renders and connects with cubits without errors', (tester) async {
      final casasCubit = _MockCasasCubit();
      final cobradorCubit = _MockDashboardCobradorCubit();

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<CasasCubit>.value(value: casasCubit),
            BlocProvider<DashboardCobradorCubit>.value(value: cobradorCubit),
          ],
          child: const MaterialApp(
            home: CobradorSolicitudesScreen(),
          ),
        ),
      );

      expect(find.text('Solicitudes de Cobro'), findsOneWidget);

      await tester.pump();
      await casasCubit.close();
      await cobradorCubit.close();
    });
  });
}

class _MockCasasCubit extends Cubit<CasasState> implements CasasCubit {
  _MockCasasCubit() : super(const ViviendasLoaded([], solicitudes: []));

  @override
  Future<void> loadViviendas({bool silent = false, bool forceFresh = true}) async {}

  @override
  Future<void> refresh() async {}

  @override
  void cambiarEstadoSolicitud(String id, String nuevoEstado) {}
}

class _MockDashboardCobradorCubit extends Cubit<CobradorDashboardState> implements DashboardCobradorCubit {
  _MockDashboardCobradorCubit() : super(CobradorDashboardInitial());

  @override
  Future<void> loadDashboard({bool silent = false, bool forceFresh = true}) async {}

  @override
  Future<void> refresh({bool silent = false}) async {}

  @override
  void cambiarEstadoSolicitud(String id, String nuevoEstado) {}

  @override
  void optimisticRegistrarPago({required String residenteId, required int montoPesos}) {}
}
