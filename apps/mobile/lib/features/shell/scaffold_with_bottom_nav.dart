import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_breakpoints.dart';
import '../../features/auth/auth_cubit.dart';
import '../../shared/widgets/connectivity_banner.dart';

/// Shell route widget that wraps all navigation screens with responsive navigation.
/// Uses BottomNavigationBar on mobile (<600px) and NavigationRail on wide screens.
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
        int currentIndex = tabs.indexWhere((t) => t.route == currentLocation);
        if (currentIndex < 0) {
          currentIndex = tabs.indexWhere(
            (t) => t.route != '/' && currentLocation.startsWith(t.route),
          );
        }
        if (currentIndex < 0) currentIndex = 0;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= AppBreakpoints.compact;
            final isExpanded = constraints.maxWidth >= AppBreakpoints.medium;

            final mainContent = Column(
              children: [
                const ConnectivityBanner(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: KeyedSubtree(
                      key: ValueKey(currentLocation),
                      child: child,
                    ),
                  ),
                ),
              ],
            );

            if (!isWide) {
              return PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) {
                  if (didPop) return;
                  if (currentIndex > 0) {
                    _onTabTap(context, tabs[0]);
                  }
                },
                child: Scaffold(
                  body: mainContent,
                  bottomNavigationBar: _buildBottomNav(context, tabs, currentIndex),
                ),
              );
            }

            final theme = Theme.of(context);
            return Scaffold(
              body: Row(
                children: [
                  NavigationRail(
                    selectedIndex: currentIndex,
                    extended: isExpanded,
                    minExtendedWidth: 190,
                    backgroundColor: theme.colorScheme.surface,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 12.0,
                      ),
                      child: isExpanded
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.payments_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 26,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Cívica Pago',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            )
                          : Icon(
                              Icons.payments_rounded,
                              color: theme.colorScheme.primary,
                              size: 26,
                            ),
                    ),
                    onDestinationSelected: (index) =>
                        _onTabTap(context, tabs[index]),
                    destinations: tabs.map((t) {
                      return NavigationRailDestination(
                        icon: t.icon,
                        selectedIcon: t.iconActive,
                        label: Text(t.label),
                      );
                    }).toList(),
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(child: mainContent),
                ],
              ),
            );
          },
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
            label: 'Cobros',
            icon: const Icon(Icons.payments_outlined),
            iconActive: const Icon(Icons.payments_rounded),
            route: '/cartera',
          ),
          _TabItem(
            label: 'Rutas',
            icon: const Icon(Icons.alt_route_outlined),
            iconActive: const Icon(Icons.alt_route_rounded),
            route: '/casas',
          ),
          _TabItem(
            label: 'Actividad',
            icon: const Icon(Icons.history_outlined),
            iconActive: const Icon(Icons.history_rounded),
            route: '/historial',
          ),
          _TabItem(
            label: 'Config',
            icon: const Icon(Icons.settings_outlined),
            iconActive: const Icon(Icons.settings_rounded),
            route: '/configuracion',
          ),
        ];
      case 'PROPIETARIO':
      case 'RESIDENTE':
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
            route: '/cartera',
          ),
          _TabItem(
            label: 'Mi Casa',
            icon: const Icon(Icons.home_work_outlined),
            iconActive: const Icon(Icons.home_work_rounded),
            route: '/mi-casa',
          ),
          _TabItem(
            label: 'Config',
            icon: const Icon(Icons.settings_outlined),
            iconActive: const Icon(Icons.settings_rounded),
            route: '/configuracion',
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
            route: '/comunidad',
          ),
          _TabItem(
            label: 'Reportes',
            icon: const Icon(Icons.analytics_outlined),
            iconActive: const Icon(Icons.analytics_rounded),
            route: '/reportes',
          ),
          _TabItem(
            label: 'Config',
            icon: const Icon(Icons.settings_outlined),
            iconActive: const Icon(Icons.settings_rounded),
            route: '/configuracion',
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
