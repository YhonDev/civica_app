import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/auth_cubit.dart';
import '../../features/shell/scaffold_with_bottom_nav.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/dashboard_cobrador/jornada_screen.dart';
import '../../features/dashboard_cobrador/casas_explorer_screen.dart';
import '../../features/dashboard_cobrador/modo_inmersivo_ruta_screen.dart';
import '../../features/dashboard_cobrador/casas_cubit.dart';
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
import '../../features/dashboard/estado_admin_screen.dart';
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
import '../../features/cartera/cartera_consolidada_screen.dart';
import '../../features/residentes/asignar_etapas_screen.dart';
import '../../features/residentes/montos_screen.dart';
import '../../features/residentes/residente_inmueble_screen.dart';
import '../../features/notificaciones/notificaciones_fallidas_screen.dart';
import '../../features/sync/sync_queue_screen.dart';

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
      builder: (_, _) => const LoginScreen(),
    ),

    // ── Shell with Bottom Navigation ───────────────────────────────────
    ShellRoute(
      builder: (_, _, child) => ScaffoldWithBottomNav(child: child),
      routes: [
        // Dashboard por rol (Admin, Cobrador, Residente)
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
          path: '/modo-inmersivo-ruta',
          name: 'modo-inmersivo-ruta',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return ModoInmersivoRutaScreen(
              etapas: extra['etapas'] as List<EtapaExplorer>? ?? [],
              solicitudes: extra['solicitudes'] as List<dynamic>? ?? [],
              selectedEtapaId: extra['selectedEtapaId'] as String? ?? 'TODAS',
              selectedEstadoFiltro: extra['selectedEstadoFiltro'] as String? ?? 'TODAS',
              sentidoInverso: extra['sentidoInverso'] as bool? ?? false,
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
                    final residente = state.extra as ResidenteItem;
                    return ResidenteDetailScreen(residente: residente);
                  },
                  routes: [
                    GoRoute(
                      path: 'finanzas',
                      builder: (_, state) {
                        final residente = state.extra as ResidenteItem;
                        return ResidenteFinanzasScreen(residente: residente);
                      },
                    ),
                    GoRoute(
                      path: 'historial',
                      builder: (_, state) {
                        final residente = state.extra as ResidenteItem;
                        return ResidenteHistorialScreen(residente: residente);
                      },
                    ),
                    GoRoute(
                      path: 'inmueble',
                      builder: (_, state) {
                        final residente = state.extra as ResidenteItem;
                        return ResidenteInmuebleScreen(residente: residente);
                      },
                    ),
                  ],
                ),
                GoRoute(
                  path: 'editar',
                  name: 'comunidad-residente-editar',
                  builder: (_, state) {
                    final residente = state.extra as ResidenteItem;
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
        GoRoute(
          path: '/mas',
          redirect: (_, _) => '/configuracion',
        ),

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

        // Notificaciones Fallidas (Admin)
        GoRoute(
          path: '/notificaciones-fallidas',
          name: 'notificaciones-fallidas',
          builder: (_, _) => const NotificacionesFallidasScreen(),
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
      builder: (_, _) => const NuevaSolicitudScreen(),
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
      builder: (_, state) => CobradorDetailScreen(
        cobrador: state.extra as CobradorItem,
      ),
    ),
  ],
);

/// Returns the appropriate dashboard screen for the given role.
Widget _dashboardForRol(String? rol) {
  switch (rol) {
    case 'COBRADOR':
      return const JornadaScreen();
    case 'RESIDENTE':
      return const ResidenteDashboardScreen();
    default:
      return const DashboardScreen();
  }
}

/// Returns the appropriate cartera/payment screen for the given role.
Widget _carteraForRol(String? rol) {
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
