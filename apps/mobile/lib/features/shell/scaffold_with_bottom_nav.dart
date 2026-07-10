import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../screens/auth/auth_cubit.dart';

/// Shell route widget that wraps all bottom-navigation screens.
///
/// Per ROLE_DASHBOARDS.md, the bottom nav adapts to the authenticated
/// user's role:
///   Admin:     Dashboard | Cartera | Propiet. | Más
///   Cobrador:  Jornada   | Cobrar  |          | Más
///   Propiet.:  Mi Estado | Pagar   |          | Más
class ScaffoldWithBottomNav extends StatelessWidget {
  final Widget child;

  const ScaffoldWithBottomNav({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final rol = state.usuario?['rol'] as String? ?? 'ADMIN';
        final tabs = _tabsForRol(rol);
        final currentLocation = GoRouterState.of(context).matchedLocation;

        // Find which tab index matches current location
        final currentIndex = tabs.indexWhere(
          (t) => t.route == currentLocation,
        );

        return Scaffold(
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(
              key: ValueKey(currentLocation),
              child: child,
            ),
          ),
          bottomNavigationBar: _buildBottomNav(context, tabs, currentIndex),
        );
      },
    );
  }

  Widget _buildBottomNav(
    BuildContext context,
    List<_TabItem> tabs,
    int currentIndex,
  ) {
    if (currentIndex < 0) return const SizedBox.shrink();

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onTabTap(context, tabs[index]),
      items: tabs.map((t) {
        // Use unselected icon for non-active tabs when there's an active variant
        final isActive = tabs.indexOf(t) == currentIndex;
        return BottomNavigationBarItem(
          icon: isActive ? t.iconActive : t.icon,
          activeIcon: t.iconActive,
          label: t.label,
          tooltip: t.label,
        );
      }).toList(),
    );
  }

  void _onTabTap(BuildContext context, _TabItem tab) {
    if (tab.route == '/') {
      // Replace top of stack with dashboard to avoid stacking / → /
      context.go('/');
    } else {
      context.go(tab.route);
    }
  }

  List<_TabItem> _tabsForRol(String rol) {
    switch (rol) {
      case 'COBRADOR':
        return [
          _TabItem(
            label: 'Inicio',
            icon: const Icon(Icons.home_outlined),
            iconActive: const Icon(Icons.home_rounded),
            route: '/',
          ),
          _TabItem(
            label: 'Cobrar',
            icon: const Icon(Icons.payments_outlined),
            iconActive: const Icon(Icons.payments_rounded),
            route: '/cartera',
          ),
          _TabItem(
            label: 'Propietarios',
            icon: const Icon(Icons.people_outline_rounded),
            iconActive: const Icon(Icons.people_rounded),
            route: '/propietarios',
          ),
          _TabItem(
            label: 'Actividad',
            icon: const Icon(Icons.history_outlined),
            iconActive: const Icon(Icons.history_rounded),
            route: '/historial',
          ),
          _TabItem(
            label: 'Más',
            icon: const Icon(Icons.menu_rounded),
            iconActive: const Icon(Icons.menu_rounded),
            route: '/perfil',
          ),
        ];
      case 'PROPIETARIO':
        return [
          _TabItem(
            label: 'Inicio',
            icon: const Icon(Icons.home_outlined),
            iconActive: const Icon(Icons.home_rounded),
            route: '/',
          ),
          _TabItem(
            label: 'Pagos',
            icon: const Icon(Icons.payments_outlined),
            iconActive: const Icon(Icons.payments_rounded),
            route: '/cartera', // as placeholder
          ),
          _TabItem(
            label: 'Historial',
            icon: const Icon(Icons.history_outlined),
            iconActive: const Icon(Icons.history_rounded),
            route: '/historial',
          ),
          _TabItem(
            label: 'Perfil',
            icon: const Icon(Icons.person_outline_rounded),
            iconActive: const Icon(Icons.person_rounded),
            route: '/perfil',
          ),
          _TabItem(
            label: 'Más',
            icon: const Icon(Icons.menu_rounded),
            iconActive: const Icon(Icons.menu_rounded),
            route: '/mas', // assuming a fallback route for Más if needed, or simply use perfil
          ),
        ];
      default: // ADMIN
        return [
          _TabItem(
            label: 'Inicio',
            icon: const Icon(Icons.home_outlined),
            iconActive: const Icon(Icons.home_rounded),
            route: '/',
          ),
          _TabItem(
            label: 'Cobros',
            icon: const Icon(Icons.account_balance_outlined),
            iconActive: const Icon(Icons.account_balance_rounded),
            route: '/cartera',
          ),
          _TabItem(
            label: 'Comunidad',
            icon: const Icon(Icons.people_outlined),
            iconActive: const Icon(Icons.people_rounded),
            route: '/propietarios',
          ),
          _TabItem(
            label: 'Reportes',
            icon: const Icon(Icons.analytics_outlined),
            iconActive: const Icon(Icons.analytics_rounded),
            route: '/estado',
          ),
          _TabItem(
            label: 'Más',
            icon: const Icon(Icons.menu_rounded),
            iconActive: const Icon(Icons.menu_rounded),
            route: '/perfil',
          ),
        ];
    }
  }
}

/// Internal tab item definition.
class _TabItem {
  final String label;
  final Widget icon;
  final Widget iconActive;
  final String route;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.iconActive,
    required this.route,
  });
}
