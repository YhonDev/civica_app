import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civica_pago_mobile/features/auth/auth_cubit.dart';
import 'package:civica_pago_mobile/features/platform/cubits/platform_overview_cubit.dart';
import 'package:civica_pago_mobile/features/platform/cubits/platform_tenants_cubit.dart';
import 'package:civica_pago_mobile/features/platform/data/platform_api_service.dart';
import 'package:civica_pago_mobile/features/platform/models/platform_models.dart';
import 'package:civica_pago_mobile/features/platform/presentation/platform_login_screen.dart';
import 'package:civica_pago_mobile/features/platform/presentation/platform_overview_screen.dart';
import 'package:civica_pago_mobile/features/platform/presentation/tenant_management_screen.dart';
import 'package:civica_pago_mobile/features/platform/presentation/platform_shell.dart';
import 'package:civica_pago_mobile/core/network/api_client.dart';

class MockPlatformApiService extends PlatformApiService {
  @override
  Future<PlatformOverviewData> getOverview() async {
    return const PlatformOverviewData(
      totalTenants: 3,
      tenantsByStatus: {TenantStatus.active: 2, TenantStatus.suspended: 1},
      activeUsers: 140,
      projects: 4,
      residents: 135,
    );
  }

  @override
  Future<({List<PlatformTenantSummary> data, int total, int page, int limit})> listTenants({
    int page = 1,
    int limit = 25,
    TenantStatus? status,
  }) async {
    final list = [
      PlatformTenantSummary(
        id: 'tenant-abc-123',
        name: 'Residencial Paraíso',
        status: TenantStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        users: 15,
        projects: 1,
        residents: 14,
        houses: 20,
      ),
    ];
    return (data: list, total: 1, page: page, limit: limit);
  }
}

void main() {
  setUpAll(() {
    ApiClient.init(
      baseUrl: 'https://api.cuentiva.test',
      storage: InMemorySecureStorage(),
    );
  });

  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('PlatformLoginScreen Widget Tests', () {
    testWidgets('renders all login controls and labels', (tester) async {
      await tester.pumpWidget(
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(),
          child: wrapWithMaterial(const PlatformLoginScreen()),
        ),
      );

      expect(find.text('Cuentiva Platform'), findsOneWidget);
      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.text('Iniciar sesión en Plataforma'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });
  });

  group('PlatformOverviewScreen Widget Tests', () {
    testWidgets('renders KPI cards and infrastructure card when loaded', (tester) async {
      final mockApi = MockPlatformApiService();
      final overviewCubit = PlatformOverviewCubit(mockApi);

      await tester.pumpWidget(
        BlocProvider<PlatformOverviewCubit>.value(
          value: overviewCubit,
          child: wrapWithMaterial(const PlatformOverviewScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Resumen de Plataforma'), findsOneWidget);
      expect(find.text('Tenants Registrados'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Usuarios Activos'), findsOneWidget);
      expect(find.text('140'), findsOneWidget);
      expect(find.text('Estado de la Infraestructura de Plataforma'), findsOneWidget);
    });
  });

  group('TenantManagementScreen Widget Tests', () {
    testWidgets('renders search field, filter chips, and tenant cards', (tester) async {
      final mockApi = MockPlatformApiService();
      final tenantsCubit = PlatformTenantsCubit(mockApi);

      await tester.pumpWidget(
        BlocProvider<PlatformTenantsCubit>.value(
          value: tenantsCubit,
          child: wrapWithMaterial(const TenantManagementScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gestión de Tenants'), findsOneWidget);
      expect(find.text('+ Nuevo Tenant'), findsOneWidget);
      expect(find.text('Residencial Paraíso'), findsOneWidget);
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Activo'), findsNWidgets(2));
      expect(find.text('1 proyectos'), findsOneWidget);
      expect(find.text('20 casas'), findsOneWidget);
    });
  });

  group('PlatformShell Widget Tests', () {
    testWidgets('renders navigation destinations in compact mode', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(),
          child: wrapWithMaterial(
            const PlatformShell(
              child: Text('Contenido Central'),
            ),
          ),
        ),
      );

      expect(find.text('Contenido Central'), findsOneWidget);
      expect(find.text('Resumen'), findsOneWidget);
      expect(find.text('Tenants'), findsOneWidget);
      expect(find.text('Auditoría'), findsOneWidget);
      expect(find.text('Producción'), findsOneWidget);
    });

    testWidgets('renders NavigationRail in tablet/desktop wide mode', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(),
          child: wrapWithMaterial(
            const PlatformShell(
              child: Text('Contenido Desktop'),
            ),
          ),
        ),
      );

      expect(find.text('Contenido Desktop'), findsOneWidget);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Cuentiva Platform'), findsOneWidget);
      expect(find.text('SUPERADMIN'), findsOneWidget);
    });
  });
}
