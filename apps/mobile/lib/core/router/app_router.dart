import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../screens/auth/login_screen.dart';
import '../../screens/auth/auth_cubit.dart';
import '../../features/shell/scaffold_with_bottom_nav.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/dashboard_cobrador/jornada_screen.dart';
import '../../features/dashboard_propietario/mi_estado_screen.dart';
import '../../features/cartera/cartera_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/historial/historial_screen.dart';
import '../../features/dashboard/estado_admin_screen.dart';
import '../../features/solicitudes/solicitudes_screen.dart';
import '../../features/solicitudes/nueva_solicitud_screen.dart';

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

        // Lista de propietarios (solo Admin)
        GoRoute(
          path: '/propietarios',
          name: 'propietarios',
          builder: (_, __) => const PlaceholderScreen('Propietarios'),
        ),

        // Perfil y configuración
        GoRoute(
          path: '/perfil',
          name: 'perfil',
          builder: (_, __) => const ProfileScreen(),
        ),

        // Historial (Propietario)
        GoRoute(
          path: '/historial',
          name: 'historial',
          builder: (_, __) => const HistorialScreen(),
        ),
      ],
    ),

    // ── Solicitudes (Pantallas fuera del ShellRoute) ──────────────────────
    GoRoute(
      path: '/solicitudes',
      name: 'solicitudes',
      builder: (_, __) => const SolicitudesScreen(),
    ),
    GoRoute(
      path: '/solicitud-nueva',
      name: 'solicitud-nueva',
      builder: (_, __) => const NuevaSolicitudScreen(),
    ),
  ],
);

/// Returns the appropriate dashboard screen for the given role.
Widget _dashboardForRol(String? rol) {
  switch (rol) {
    case 'COBRADOR':
      return const JornadaScreen();
    case 'PROPIETARIO':
      return const MiEstadoScreen();
    default:
      return const DashboardScreen();
  }
}

/// Returns the appropriate cartera/payment screen for the given role.
Widget _carteraForRol(String? rol) {
  switch (rol) {
    case 'COBRADOR':
    case 'PROPIETARIO':
      // TODO: Cobrar screen / Pagar screen when implemented
      return const PlaceholderScreen('Cartera');
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
