import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/features/auth/auth_cubit.dart';
import 'package:civica_pago_mobile/features/auth/unauthorized_role_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.init(baseUrl: 'http://test.local');
  });

  group('UnauthorizedRoleScreen Widget Tests', () {
    testWidgets('renders unauthorized title, message and icon correctly', (tester) async {
      final authCubit = AuthCubit();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: const UnauthorizedRoleScreen(),
          ),
        ),
      );

      expect(find.text('Acceso no autorizado'), findsOneWidget);
      expect(find.byIcon(Icons.lock_person_outlined), findsOneWidget);
      expect(
        find.textContaining('Tu cuenta no tiene permisos operativos asignados'),
        findsOneWidget,
      );
      expect(find.text('Cerrar sesión'), findsOneWidget);
    });

    testWidgets('renders custom message if provided', (tester) async {
      final authCubit = AuthCubit();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: const UnauthorizedRoleScreen(
              message: 'Mensaje personalizado de prueba',
            ),
          ),
        ),
      );

      expect(find.text('Mensaje personalizado de prueba'), findsOneWidget);
    });

    testWidgets('logout button has accessible tap target >= 48dp and triggers onLogout callback', (tester) async {
      bool logoutCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnauthorizedRoleScreen(
              onLogout: () {
                logoutCalled = true;
              },
            ),
          ),
        ),
      );

      final buttonFinder = find.widgetWithText(OutlinedButton, 'Cerrar sesión');
      expect(buttonFinder, findsOneWidget);

      final size = tester.getSize(buttonFinder);
      expect(size.height, greaterThanOrEqualTo(48.0));
      expect(size.width, greaterThanOrEqualTo(160.0));

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(logoutCalled, isTrue);
    });
  });
}
