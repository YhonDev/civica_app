import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/core/sync/connectivity_detector.dart';
import 'package:civica_pago_mobile/core/theme/app_breakpoints.dart';
import 'package:civica_pago_mobile/core/widgets/responsive_builder.dart';
import 'package:civica_pago_mobile/features/auth/auth_cubit.dart';
import 'package:civica_pago_mobile/features/auth/login_screen.dart';
import 'package:civica_pago_mobile/features/cartera/cartera_screen.dart';
import 'package:civica_pago_mobile/features/shell/scaffold_with_bottom_nav.dart';
import 'package:civica_pago_mobile/shared/widgets/system_settings_section.dart';
import 'fake_repositories.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.init(baseUrl: 'http://test.local');
    ConnectivityDetector.init();
  });

  group('ResponsiveBuilder & Breakpoints Unit Tests', () {
    testWidgets('ResponsiveBuilder renders compact on narrow width (<600px)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveBuilder(
              compact: (context, c) => const Text('COMPACT_VIEW'),
              medium: (context, c) => const Text('MEDIUM_VIEW'),
              expanded: (context, c) => const Text('EXPANDED_VIEW'),
            ),
          ),
        ),
      );

      expect(find.text('COMPACT_VIEW'), findsOneWidget);
      expect(find.text('MEDIUM_VIEW'), findsNothing);
      expect(find.text('EXPANDED_VIEW'), findsNothing);
    });

    testWidgets('ResponsiveBuilder renders medium on tablet width (600px - 1023px)', (tester) async {
      tester.view.physicalSize = const Size(800, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveBuilder(
              compact: (context, c) => const Text('COMPACT_VIEW'),
              medium: (context, c) => const Text('MEDIUM_VIEW'),
              expanded: (context, c) => const Text('EXPANDED_VIEW'),
            ),
          ),
        ),
      );

      expect(find.text('MEDIUM_VIEW'), findsOneWidget);
      expect(find.text('COMPACT_VIEW'), findsNothing);
      expect(find.text('EXPANDED_VIEW'), findsNothing);
    });

    testWidgets('ResponsiveBuilder renders expanded on desktop width (>=1024px)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveBuilder(
              compact: (context, c) => const Text('COMPACT_VIEW'),
              medium: (context, c) => const Text('MEDIUM_VIEW'),
              expanded: (context, c) => const Text('EXPANDED_VIEW'),
            ),
          ),
        ),
      );

      expect(find.text('EXPANDED_VIEW'), findsOneWidget);
      expect(find.text('COMPACT_VIEW'), findsNothing);
      expect(find.text('MEDIUM_VIEW'), findsNothing);
    });
  });

  group('ScaffoldWithBottomNav Responsive Tests', () {
    Widget createShellApp({required Size size}) {
      final authCubit = AuthCubit();
      authCubit.emit(AuthState.authenticated({
        'nombre': 'Admin Test',
        'rol': 'ADMIN',
        'email': 'admin@test.com',
      }));

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          ShellRoute(
            builder: (context, state, child) =>
                ScaffoldWithBottomNav(child: child),
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) =>
                    const Scaffold(body: Text('HOME_PAGE')),
              ),
            ],
          ),
        ],
      );

      return BlocProvider<AuthCubit>.value(
        value: authCubit,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('Renders BottomNavigationBar on mobile width (<600px)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createShellApp(size: const Size(400, 800)));
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(DesktopSidebar), findsNothing);
      expect(find.text('HOME_PAGE'), findsOneWidget);
    });

    testWidgets('Renders DesktopSidebar on wide width (>=600px)', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createShellApp(size: const Size(1200, 800)));
      await tester.pumpAndSettle();

      expect(find.byType(DesktopSidebar), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
      expect(find.text('Cívica Pago'), findsOneWidget);
      expect(find.text('HOME_PAGE'), findsOneWidget);
    });
  });

  group('LoginScreen Responsive Constraints Tests', () {
    testWidgets('Constrains Form width to maxFormWidth on wide screen', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final authCubit = AuthCubit();

      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final constrainedBoxes = tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));
      final formConstraint = constrainedBoxes.firstWhere(
        (box) => box.constraints.maxWidth == AppBreakpoints.maxFormWidth,
      );
      expect(formConstraint.constraints.maxWidth, equals(440.0));
    });

    testWidgets('Does not display biometrics button on non-mobile platforms/viewports', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final authCubit = AuthCubit();

      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ingresar con huella dactilar'), findsNothing);
      expect(find.byIcon(Icons.fingerprint_rounded), findsNothing);
    });
  });

  group('CarteraScreen Responsive Grid Tests', () {
    testWidgets('Renders SliverGrid with 4 columns on desktop width (>= 1200px)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final authCubit = AuthCubit();
      authCubit.emit(AuthState.authenticated({
        'nombre': 'Admin Test',
        'rol': 'ADMIN',
        'email': 'admin@test.com',
        'tenantId': 't1',
      }));

      final repo = FakeCarteraData.conTresCuotas();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: CarteraScreen(repository: repo),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(SliverGrid), findsOneWidget);
      final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
      final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, equals(4));
    });
  });

  group('SystemSettingsSection Biometrics Gating Tests', () {
    testWidgets('Completely hides biometrics option on non-supported platforms', (tester) async {
      final authCubit = AuthCubit();
      authCubit.emit(AuthState.authenticated({
        'nombre': 'User Test',
        'rol': 'COBRADOR',
        'id': 'u1',
      }));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: const Scaffold(
              body: SystemSettingsSection(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Acceso biométrico'), findsNothing);
      expect(find.byIcon(Icons.fingerprint_rounded), findsNothing);
      expect(find.text('No disponible en este dispositivo'), findsNothing);
    });
  });
}
