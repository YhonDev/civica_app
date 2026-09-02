import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:civica_pago_mobile/features/dashboard_cobrador/cobrador_solicitudes_screen.dart';
import 'package:civica_pago_mobile/features/dashboard_cobrador/casas_cubit.dart';
import 'package:civica_pago_mobile/features/dashboard_cobrador/dashboard_cobrador_cubit.dart';
import 'package:civica_pago_mobile/features/dashboard_cobrador/widgets/cobrador_solicitud_card.dart';

void main() {
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
  });
}
