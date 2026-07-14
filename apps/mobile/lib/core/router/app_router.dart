import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../screens/auth/login_screen.dart';
import '../../screens/auth/auth_cubit.dart';
import '../../features/shell/scaffold_with_bottom_nav.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/dashboard_cobrador/jornada_screen.dart';
import '../../features/dashboard_cobrador/viviendas_explorer_screen.dart';
import '../../features/dashboard_propietario/mi_estado_screen.dart';
import '../../features/dashboard_propietario/propietario_dashboard_screen.dart';
import '../../features/cartera/cartera_screen.dart';
import '../../features/propietarios/nuevo_propietario_screen.dart';
import '../../features/propietarios/nuevo_cobrador_screen.dart';
import '../../features/propietarios/proyecto_detail_screen.dart';
import '../../features/propietarios/etapas_screen.dart';
import '../../features/propietarios/manzanas_screen.dart';
import '../../features/propietarios/casas_screen.dart';
import '../../features/propietarios/proyecto_ajustes_screen.dart';
import '../../features/mas/mas_screen.dart';
import '../../features/mas/configuracion_screen.dart';
import '../../features/historial/historial_screen.dart';
import '../../features/dashboard/estado_admin_screen.dart';
import '../../features/dashboard/actividad_admin_screen.dart';
import '../../features/solicitudes/solicitudes_screen.dart';
import '../../features/solicitudes/nueva_solicitud_screen.dart';
import '../../features/propietarios/comunidad_screen.dart';
import '../../features/propietarios/propietarios_screen.dart';
import '../../features/propietarios/models/propietarios_models.dart';
import '../../features/propietarios/propietario_detail_screen.dart';
import '../../features/propietarios/editar_propietario_screen.dart';
import '../../features/propietarios/cobradores_screen.dart';
import '../../features/propietarios/urbanizacion_screen.dart';
import '../../features/propietarios/widgets/propietario_finanzas_tab.dart';
import '../../features/propietarios/widgets/propietario_historial_tab.dart';
import '../../features/propietarios/propietario_inmueble_screen.dart';

import '../../features/propietarios/tarifas_screen.dart';

/// GoRouter configuration — role-aware.
///
/// Per doc/20-screen-specifications.md:
///   Login → backend obtiene rol → Carga Dashboard correspondiente
///
/// Routes / and /cartera adapt the shown screen based on the
/// authenticated user's role (ADMIN, COBRADOR, PROPIETARIO).
final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  debugLogDiagnostics: false,

  // ── Auth redirect ────────────────────────────────────────────────────
  redirect: (context, state) {
    final auth = context.read<AuthCubit>();
    final isLoggedIn = auth.state.isAuthenticated;
    final isLoginRoute = state.matchedLocation == '/login';

    if (!isLoggedIn && !isLoginRoute) return '/login';
    if (isLoggedIn && isLoginRoute) return '/';
    return null;
  },

  routes: [
    // ── Login ──────────────────────────────────────────────────────────
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (_, __) => const LoginScreen(),
    ),

    // ── Shell with Bottom Navigation ───────────────────────────────────
    ShellRoute(
      builder: (_, __, child) => ScaffoldWithBottomNav(child: child),
      routes: [
        // Dashboard por rol (Admin, Cobrador, Propietario)
        GoRoute(
          path: '/',
          name: 'dashboard',
          builder: (context, _) {
            final rol = context.read<AuthCubit>().state.usuario?['rol'] as String?;
            return _dashboardForRol(rol);
          },
        ),

        // Estado/Cartera según rol
        GoRoute(
          path: '/estado',
          name: 'estado',
          builder: (context, _) {
            final rol = context.read<AuthCubit>().state.usuario?['rol'] as String?;
            if (rol == 'ADMIN') {
              return const EstadoAdminScreen();
            }
            return _carteraForRol(rol);
          },
        ),
        
        // Cobrar/Pagar según rol (Cartera fallback)
        GoRoute(
          path: '/cartera',
          name: 'cartera',
          builder: (context, _) {
            final rol = context.read<AuthCubit>().state.usuario?['rol'] as String?;
            return _carteraForRol(rol);
          },
        ),

        // Viviendas Explorer (Cobrador)
        GoRoute(
          path: '/viviendas',
          name: 'viviendas',
          builder: (_, __) => const ViviendasExplorerScreen(),
        ),

        // Módulo Comunidad (Hub) y sub-rutas
        GoRoute(
          path: '/comunidad',
          name: 'comunidad',
          builder: (_, __) => const ComunidadScreen(),
          routes: [
            GoRoute(
              path: 'propietarios',
              name: 'comunidad-propietarios',
              builder: (_, __) => const PropietariosScreen(),
              routes: [
                GoRoute(
                  path: 'detalle',
                  name: 'comunidad-propietario-detalle',
                  builder: (_, state) {
                    final propietario = state.extra as PropietarioItem;
                    return PropietarioDetailScreen(propietario: propietario);
                  },
                  routes: [
                    GoRoute(
                      path: 'finanzas',
                      builder: (_, state) {
                        final propietario = state.extra as PropietarioItem;
                        return PropietarioFinanzasScreen(propietario: propietario);
                      },
                    ),
                    GoRoute(
                      path: 'historial',
                      builder: (_, state) {
                        final propietario = state.extra as PropietarioItem;
                        return PropietarioHistorialScreen(propietario: propietario);
                      },
                    ),
                    GoRoute(
                      path: 'inmueble',
                      builder: (_, state) {
                        final propietario = state.extra as PropietarioItem;
                        return PropietarioInmuebleScreen(propietario: propietario);
                      },
                    ),
                  ],
                ),
                GoRoute(
                  path: 'editar',
                  name: 'comunidad-propietario-editar',
                  builder: (_, state) {
                    final propietario = state.extra as PropietarioItem;
                    return EditarPropietarioScreen(propietario: propietario);
                  },
                ),
              ],
            ),
            GoRoute(
              path: 'cobradores',
              name: 'comunidad-cobradores',
              builder: (_, __) => const CobradoresScreen(),
            ),
            GoRoute(
              path: 'tarifas',
              name: 'comunidad-tarifas',
              builder: (_, __) => const TarifasScreen(),
            ),
            GoRoute(
              path: 'urbanizacion',
              name: 'comunidad-urbanizacion',
              builder: (_, __) => const UrbanizacionScreen(),
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
                      builder: (_, __) => const ManzanasScreen(),
                    ),
                    GoRoute(
                      path: 'casas',
                      name: 'comunidad-proyecto-casas',
                      builder: (_, __) => const CasasScreen(),
                    ),
                    GoRoute(
                      path: 'ajustes',
                      name: 'comunidad-proyecto-ajustes',
                      builder: (_, __) => const ProyectoAjustesScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // Menú Más
        GoRoute(
          path: '/mas',
          name: 'mas',
          builder: (_, __) => const MasScreen(),
          routes: [
            GoRoute(
              path: 'configuracion',
              name: 'mas-configuracion',
              builder: (_, __) => const ConfiguracionScreen(),
            ),
          ],
        ),

        // Historial (Propietario)
        GoRoute(
          path: '/historial',
          name: 'historial',
          builder: (_, __) => const HistorialScreen(),
        ),
      ],
    ),

    // ── Solicitudes y Actividad (Pantallas fuera del ShellRoute) ──────────────────────
    GoRoute(
      path: '/solicitudes',
      name: 'solicitudes',
      builder: (_, __) => const SolicitudesScreen(),
    ),
    GoRoute(
      path: '/actividad-admin',
      name: 'actividad-admin',
      builder: (_, __) => const ActividadAdminScreen(),
    ),
    GoRoute(
      path: '/solicitud-nueva',
      name: 'solicitud-nueva',
      builder: (_, __) => const NuevaSolicitudScreen(),
    ),
    GoRoute(
      path: '/nuevo-propietario',
      name: 'nuevo-propietario',
      builder: (_, __) => const NuevoPropietarioScreen(),
    ),
    GoRoute(
      path: '/nuevo-cobrador',
      name: 'nuevo-cobrador',
      builder: (_, __) => const NuevoCobradorScreen(),
    ),
  ],
);

/// Returns the appropriate dashboard screen for the given role.
Widget _dashboardForRol(String? rol) {
  switch (rol) {
    case 'COBRADOR':
      return const JornadaScreen();
    case 'PROPIETARIO':
      return const PropietarioDashboardScreen();
    default:
      return const DashboardScreen();
  }
}

/// Returns the appropriate cartera/payment screen for the given role.
Widget _carteraForRol(String? rol) {
  switch (rol) {
    case 'COBRADOR':
    case 'PROPIETARIO':
      return const CarteraScreen();
    default:
      return const CarteraScreen();
  }
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
