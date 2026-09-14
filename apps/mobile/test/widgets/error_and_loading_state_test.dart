import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:civica_pago_mobile/shared/widgets/error_state.dart';
import 'package:civica_pago_mobile/shared/widgets/loading_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ErrorState Widget Tests', () {
    testWidgets('renders title, description and default icon correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorState(
              title: 'Error de prueba',
              description: 'Detalle del error ocurrido',
            ),
          ),
        ),
      );

      expect(find.text('Error de prueba'), findsOneWidget);
      expect(find.text('Detalle del error ocurrido'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      // No retry button rendered if onRetry is null
      expect(find.text('Reintentar'), findsNothing);
    });

    testWidgets('renders retry button and triggers onRetry callback', (tester) async {
      var retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorState(
              title: 'Error de red',
              description: 'No hay conexión',
              retryLabel: 'Volver a intentar',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      final retryFinder = find.text('Volver a intentar');
      expect(retryFinder, findsOneWidget);

      // Verify touch target size meets minimum 48dp
      final buttonSize = tester.getSize(find.byType(FilledButton));
      expect(buttonSize.height, greaterThanOrEqualTo(48.0));

      await tester.tap(retryFinder);
      await tester.pump();

      expect(retried, isTrue);
    });
  });

  group('LoadingState Widget Tests', () {
    testWidgets('renders spinner and custom message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingState(message: 'Cargando datos del servidor...'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Cargando datos del servidor...'), findsOneWidget);
    });

    testWidgets('renders spinner without message when not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingState(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
