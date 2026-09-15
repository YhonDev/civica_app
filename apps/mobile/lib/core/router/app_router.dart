import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/user_role.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/auth_cubit.dart';
import '../../features/auth/unauthorized_role_screen.dart';
import '../../features/shell/scaffold_with_bottom_nav.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/dashboard_cobrador/jornada_screen.dart';
import '../../features/dashboard_cobrador/casas_explorer_screen.dart';
import '../../features/dashboard_cobrador/cobrador_solicitudes_screen.dart';
import '../../features/dashboard_cobrador/modo_inmersivo_ruta_screen.dart';
import '../../features/dashboard_cobrador/casas_cubit.dart';
import '../../features/dashboard_cobrador/dashboard_cobrador_cubit.dart';
import '../../features/dashboard_residente/residente_dashboard_screen.dart';
import '../../features/cartera/cartera_screen.dart';
import '../../features/residentes/nuevo_residente_screen.dart';
import '../../features/residentes/nuevo_cobrador_screen.dart';
import '../../features/residentes/cobrador_detail_screen.dart';
import '../../features/residentes/models/cobradores_models.dart';
import '../../features/residentes/proyecto_detail_screen.dart';
import '../../features/residentes/etapas_screen.dart';
import '../../features/residentes/manzanas_screen.dart';
import '../../features/residentes/casas_screen.dart';
import '../../features/residentes/proyecto_ajustes_screen.dart';
import '../../features/configuracion/configuracion_screen.dart';
import '../../features/historial/historial_screen.dart';

import '../../features/dashboard/actividad_admin_screen.dart';
import '../../features/solicitudes/solicitudes_screen.dart';
import '../../features/solicitudes/nueva_solicitud_screen.dart';
import '../../features/residentes/comunidad_screen.dart';
import '../../features/residentes/residentes_screen.dart';
import '../../features/residentes/models/residentes_models.dart';
import '../../features/residentes/residente_detail_screen.dart';
import '../../features/residentes/editar_residente_screen.dart';
import '../../features/residentes/cobradores_screen.dart';
import '../../features/residentes/urbanizacion_screen.dart';
import '../../features/residentes/widgets/residente_finanzas_tab.dart';
import '../../features/residentes/widgets/residente_historial_tab.dart';
import '../../features/residentes/tarifas_screen.dart';
import '../../features/dashboard_residente/mi_casa_screen.dart';
import '../../features/reportes/reportes_screen.dart';
import '../../features/residentes/asignar_etapas_screen.dart';
import '../../features/residentes/montos_screen.dart';
import '../../features/residentes/residente_inmueble_screen.dart';
import '../../features/sync/sync_queue_screen.dart';
import '../../features/platform/cubits/platform_overview_cubit.dart';
import '../../features/platform/cubits/platform_tenants_cubit.dart';
import '../../features/platform/cubits/platform_audit_cubit.dart';
import '../../features/platform/presentation/platform_shell.dart';
import '../../features/platform/presentation/platform_login_screen.dart';
import '../../features/platform/presentation/platform_overview_screen.dart';
import '../../features/platform/presentation/tenant_management_screen.dart';
import '../../features/platform/presentation/tenant_detail_screen.dart';
import '../../features/platform/presentation/platform_audit_screen.dart';

/// GoRouter configuration — role-aware.
///
/// Per doc/20-screen-specifications.md:
///   Login → backend obtiene rol → Carga Dashboard correspondiente
///
/// Routes / and /cartera adapt the shown screen based on the
/// authenticated user's role (ADMIN, COBRADOR, RESIDENTE).
final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  debugLogDiagnostics: false,

  // ── Auth redirect ────────────────────────────────────────────────────
  redirect: (context, state) {
    final auth = context.read<AuthCubit>();
    final isLoggedIn = auth.state.isAuthenticated;
    final location = state.matchedLocation;
    final isLoginRoute = location == '/login' || location == '/platform/login';
    final rawRol = auth.state.usuario?['rol'] as String?;
    final role = UserRole.fromString(rawRol);

    if (!isLoggedIn && !isLoginRoute) return '/login';
    if (isLoggedIn && isLoginRoute) {
      if (role == UserRole.superadmin) {
        return '/platform/overview';
      }
      return '/';
    }

    // Role isolation guards:
    final isPlatformRoute = location.startsWith('/platform');

    // Operational roles cannot access platform console -> redirect to operational home
    if (isPlatformRoute && role != UserRole.superadmin) {
      return '/';
    }

    // Superadmin cannot access operational tenant routes -> redirect to platform overview
    if (role == UserRole.superadmin && !isPlatformRoute) {
      return '/platform/overview';
    }

    return null;
  },

  routes: [
    // ── Login Operativo ────────────────────────────────────────────────
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (_, _) => const LoginScreen(),
    ),

    // ── Login de Plataforma (Exclusivo SUPERADMIN) ─────────────────────
    GoRoute(
      path: '/platform/login',
      name: 'platform_login',
      builder: (_, _) => const PlatformLoginScreen(),
    ),

    // ── Shell de Plataforma (Consola Operativa SUPERADMIN) ─────────────
    ShellRoute(
      builder: (context, state, child) {
        return MultiBlocProvider(
          key: const ValueKey('shell_platform_providers'),
          providers: [
            BlocProvider<PlatformOverviewCubit>(
              create: (_) => PlatformOverviewCubit(),
            ),
            BlocProvider<PlatformTenantsCubit>(
              create: (_) => PlatformTenantsCubit(),
            ),
            BlocProvider<PlatformAuditCubit>(
              create: (_) => PlatformAuditCubit(),
            ),
          ],
          child: PlatformShell(child: child),
        );
      },
      routes: [
        GoRoute(
          path: '/platform/overview',
          name: 'platform_overview',
          builder: (_, _) => const PlatformOverviewScreen(),
        ),
        GoRoute(
          path: '/platform/tenants',
          name: 'platform_tenants',
          builder: (_, _) => const TenantManagementScreen(),
          routes: [
            GoRoute(
              path: ':id',
              name: 'platform_tenant_detail',
              builder: (context, state) {
                final tenantId = state.pathParameters['id'] ?? '';
                return TenantDetailScreen(tenantId: tenantId);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/platform/audit',
          name: 'platform_audit',
          builder: (_, _) => const PlatformAuditScreen(),
        ),
      ],
    ),

    // ── Shell with Bottom Navigation ───────────────────────────────────
    ShellRoute(
      builder: (context, state, child) {
        final rawRol = context.watch<AuthCubit>().state.usuario?['rol'] as String?;
        final role = UserRole.fromString(rawRol);

        if (!role.isAuthorized) {
          return const Scaffold(
            body: UnauthorizedRoleScreen(),
          );
        }

        if (role == UserRole.cobrador) {
          return MultiBlocProvider(
            key: const ValueKey('shell_cobrador_providers'),
            providers: [
              BlocProvider<DashboardCobradorCubit>(
                create: (_) => DashboardCobradorCubit()..loadDashboard(),
              ),
              BlocProvider<CasasCubit>(
                create: (_) => CasasCubit()..loadViviendas(),
              ),
            ],
            child: ScaffoldWithBottomNav(child: child),
          );
        }
        return ScaffoldWithBottomNav(child: child);
      },
      routes: [
        // Dashboard por rol (Admin, Cobrador, Residente)
        GoRoute(
          path: '/',
          name: 'dashboard',
          builder: (context, _) {
            final rol =
                context.read<AuthCubit>().state.usuario?['rol'] as String?;
            return _dashboardForRol(rol);
          },
        ),

        // Estado/Cartera según rol (unified — all roles use CarteraScreen)
        GoRoute(
          path: '/estado',
          name: 'estado',
          builder: (context, _) {
            final rol =
                context.read<AuthCubit>().state.usuario?['rol'] as String?;
            return _carteraForRol(rol);
          },
        ),

        // Cobrar/Pagar según rol (Cartera fallback)
        GoRoute(
          path: '/cartera',
          name: 'cartera',
          builder: (context, _) {
            final rol =
                context.read<AuthCubit>().state.usuario?['rol'] as String?;
            return _carteraForRol(rol);
          },
        ),
        GoRoute(
          path: '/casas',
          name: 'casas',
          builder: (_, _) => const CasasExplorerScreen(),
        ),
        GoRoute(
          path: '/casas-explorer',
          name: 'casas-explorer',
          builder: (_, _) => const CasasExplorerScreen(),
        ),
        GoRoute(
          path: '/cobrador-solicitudes',
          name: 'cobrador-solicitudes',
          builder: (_, _) => const CobradorSolicitudesScreen(),
        ),
        GoRoute(
          path: '/modo-inmersivo-ruta',
          name: 'modo-inmersivo-ruta',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return ModoInmersivoRutaScreen(
              etapas: extra['etapas'] as List<EtapaExplorer>? ?? [],
              solicitudes: extra['solicitudes'] as List<dynamic>? ?? [],
              selectedEtapaId: extra['selectedEtapaId'] as String? ?? 'TODAS',
              selectedEstadoFiltro:
                  extra['selectedEstadoFiltro'] as String? ?? 'TODAS',
              sentidoInverso: extra['sentidoInverso'] as bool? ?? false,
              selectedRecorridoFecha:
                  (extra['selectedRecorrido']
                          as Map<String, dynamic>?)?['fecha']
                      as String?,
              selectedRecorridoLabel: () {
                final rec = extra['selectedRecorrido'] as Map<String, dynamic>?;
                if (rec == null) return null;
                final nombre = rec['nombre'] as String? ?? 'Recorrido';
                final legible = rec['fechaLegible'] as String? ?? '';
                return legible.isEmpty ? nombre : '$nombre · $legible';
              }(),
            );
          },
        ),

        // Módulo Comunidad (Hub) y sub-rutas
        GoRoute(
          path: '/comunidad',
          name: 'comunidad',
          builder: (_, _) => const ComunidadScreen(),
          routes: [
            GoRoute(
              path: 'residentes',
              name: 'comunidad-residentes',
              builder: (_, _) => const ResidentesScreen(),
              routes: [
                GoRoute(
                  path: 'detalle',
                  name: 'comunidad-residente-detalle',
                  builder: (_, state) {
                    final residente = state.extra;
                    if (residente is! ResidenteItem) {
                      return const InvalidRouteArgumentsScreen();
                    }
                    return ResidenteDetailScreen(residente: residente);
                  },
                  routes: [
                    GoRoute(
                      path: 'finanzas',
                      builder: (_, state) {
                        final residente = state.extra;
                        if (residente is! ResidenteItem) {
                          return const InvalidRouteArgumentsScreen();
                        }
                        return ResidenteFinanzasScreen(residente: residente);
                      },
                    ),
                    GoRoute(
                      path: 'historial',
                      builder: (_, state) {
                        final residente = state.extra;
                        if (residente is! ResidenteItem) {
                          return const InvalidRouteArgumentsScreen();
                        }
                        return ResidenteHistorialScreen(residente: residente);
                      },
                    ),
                    GoRoute(
                      path: 'inmueble',
                      builder: (_, state) {
                        final residente = state.extra;
                        if (residente is! ResidenteItem) {
                          return const InvalidRouteArgumentsScreen();
                        }
                        return ResidenteInmuebleScreen(residente: residente);
                      },
                    ),
                  ],
                ),
                GoRoute(
                  path: 'editar',
                  name: 'comunidad-residente-editar',
                  builder: (_, state) {
                    final residente = state.extra;
                    if (residente is! ResidenteItem) {
                      return const InvalidRouteArgumentsScreen();
                    }
                    return EditarResidenteScreen(residente: residente);
                  },
                ),
              ],
            ),
            GoRoute(
              path: 'cobradores',
              name: 'comunidad-cobradores',
              builder: (_, _) => const CobradoresScreen(),
            ),
            GoRoute(
              path: 'tarifas',
              name: 'comunidad-tarifas',
              builder: (_, _) => const TarifasScreen(),
            ),
            GoRoute(
              path: 'urbanizacion',
              name: 'comunidad-urbanizacion',
              builder: (_, _) => const UrbanizacionScreen(),
              routes: [
                GoRoute(
                  path: 'proyecto-detalle',
                  name: 'comunidad-proyecto-detalle',
                  builder: (_, state) {
                    final extra = state.extra as Map<String, dynamic>? ?? {};
                    return ProyectoDetailScreen(proyecto: extra);
                  },
                  routes: [
                    GoRoute(
                      path: 'etapas',
                      name: 'comunidad-proyecto-etapas',
                      builder: (_, state) {
                        final pId = state.extra as String?;
                        // Si pId es null, la pantalla usará el fallback default (currentTenantId)
                        return EtapasScreen(proyectoId: pId ?? '');
                      },
                    ),
                    GoRoute(
                      path: 'manzanas',
                      name: 'comunidad-proyecto-manzanas',
                      builder: (_, _) => const ManzanasScreen(),
                    ),
                    GoRoute(
                      path: 'casas',
                      name: 'comunidad-proyecto-casas',
                      builder: (_, _) => const CasasScreen(),
                    ),
                    GoRoute(
                      path: 'ajustes',
                      name: 'comunidad-proyecto-ajustes',
                      builder: (_, state) {
                        final proyectoId = state.extra as String? ?? '';
                        return ProyectoAjustesScreen(proyectoId: proyectoId);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // Configuración
        GoRoute(
          path: '/configuracion',
          name: 'configuracion',
          builder: (_, _) => const ConfiguracionScreen(),
        ),
        GoRoute(path: '/mas', redirect: (_, _) => '/configuracion'),

        // Historial (Residente)
        GoRoute(
          path: '/historial',
          name: 'historial',
          builder: (_, _) => const HistorialScreen(),
        ),

        // Mi Casa (Residente)
        GoRoute(
          path: '/mi-casa',
          name: 'mi-casa',
          builder: (_, _) => const MiCasaScreen(),
        ),

        // Reportes (Admin)
        GoRoute(
          path: '/reportes',
          name: 'reportes',
          builder: (_, _) => const ReportesScreen(),
        ),

        // Montos Predefinidos (Admin)
        GoRoute(
          path: '/montos',
          name: 'montos',
          builder: (_, _) => const MontosScreen(),
        ),

        // Sync Queue (Cobrador)
        GoRoute(
          path: '/sync-queue',
          name: 'sync-queue',
          builder: (_, _) => const SyncQueueScreen(),
        ),
      ],
    ),

    // ── Solicitudes y Actividad (Pantallas fuera del ShellRoute) ──────────────────────
    GoRoute(
      path: '/solicitudes',
      name: 'solicitudes',
      builder: (_, _) => const SolicitudesScreen(),
    ),
    GoRoute(
      path: '/actividad-admin',
      name: 'actividad-admin',
      builder: (_, _) => const ActividadAdminScreen(),
    ),
    GoRoute(
      path: '/solicitud-nueva',
      name: 'solicitud-nueva',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return NuevaSolicitudScreen(
          initialCobroId: extra?['cobroId'] as String?,
          initialPagoId: extra?['pagoId'] as String?,
          initialConcepto: extra?['concepto'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/nuevo-residente',
      name: 'nuevo-residente',
      builder: (_, _) => const NuevoResidenteScreen(),
    ),
    GoRoute(
      path: '/nuevo-cobrador',
      name: 'nuevo-cobrador',
      builder: (_, _) => const NuevoCobradorScreen(),
    ),
    GoRoute(
      path: '/asignar-etapas',
      name: 'asignar-etapas',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return AsignarEtapasScreen(
          cobradorId: extra['cobradorId'] ?? '',
          cobradorNombre: extra['cobradorNombre'] ?? 'Cobrador',
        );
      },
    ),
    GoRoute(
      path: '/cobrador-detalle',
      name: 'cobrador-detalle',
      builder: (_, state) {
        final cobrador = state.extra;
        if (cobrador is! CobradorItem) {
          return const InvalidRouteArgumentsScreen();
        }
        return CobradorDetailScreen(cobrador: cobrador);
      },
    ),
  ],
);

/// Returns the appropriate dashboard screen for the given role.
Widget _dashboardForRol(String? rawRol) {
  final role = UserRole.fromString(rawRol);
  switch (role) {
    case UserRole.cobrador:
      return const JornadaScreen();
    case UserRole.residente:
      return const ResidenteDashboardScreen();
    case UserRole.admin:
      return const DashboardScreen();
    case UserRole.superadmin:
    case UserRole.unauthorized:
      return const UnauthorizedRoleScreen();
  }
}

/// Returns the appropriate cartera/payment screen for the given role.
Widget _carteraForRol(String? rawRol) {
  final role = UserRole.fromString(rawRol);
  if (!role.isAuthorized) {
    return const UnauthorizedRoleScreen();
  }
  return const CarteraScreen();
}

/// Placeholder for screens not yet implemented.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title — Próximamente',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class InvalidRouteArgumentsScreen extends StatelessWidget {
  const InvalidRouteArgumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pantalla no disponible')),
      body: Center(
        child: Text(
          'Los datos de esta navegación ya no están disponibles.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
