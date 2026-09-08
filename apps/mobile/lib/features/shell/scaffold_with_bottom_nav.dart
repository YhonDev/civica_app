import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../features/auth/auth_cubit.dart';
import '../../shared/widgets/connectivity_banner.dart';

/// Shell route widget that wraps all navigation screens with responsive navigation.
/// Uses BottomNavigationBar on mobile (<600px) and DesktopSidebar on wide screens.
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

            return Scaffold(
              body: Row(
                children: [
                  DesktopSidebar(
                    tabs: tabs,
                    currentIndex: currentIndex,
                    isExpanded: isExpanded,
                    onTabTap: (tab) => _onTabTap(context, tab),
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
    List<NavTabItem> tabs,
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

  void _onTabTap(BuildContext context, NavTabItem tab) {
    if (tab.route == '/') {
      // Replace top of stack with dashboard to avoid stacking / → /
      context.go('/');
    } else {
      context.go(tab.route);
    }
  }

  List<NavTabItem> _tabsForRol(String rol) {
    switch (rol) {
      case 'COBRADOR':
        return [
          NavTabItem(
            label: 'Inicio',
            icon: const Icon(Icons.home_outlined),
            iconActive: const Icon(Icons.home_rounded),
            route: '/',
          ),
          NavTabItem(
            label: 'Cobros',
            icon: const Icon(Icons.payments_outlined),
            iconActive: const Icon(Icons.payments_rounded),
            route: '/cartera',
          ),
          NavTabItem(
            label: 'Rutas',
            icon: const Icon(Icons.alt_route_outlined),
            iconActive: const Icon(Icons.alt_route_rounded),
            route: '/casas',
          ),
          NavTabItem(
            label: 'Actividad',
            icon: const Icon(Icons.history_outlined),
            iconActive: const Icon(Icons.history_rounded),
            route: '/historial',
          ),
          NavTabItem(
            label: 'Config',
            icon: const Icon(Icons.settings_outlined),
            iconActive: const Icon(Icons.settings_rounded),
            route: '/configuracion',
          ),
        ];
      case 'PROPIETARIO':
      case 'RESIDENTE':
        return [
          NavTabItem(
            label: 'Inicio',
            icon: const Icon(Icons.home_outlined),
            iconActive: const Icon(Icons.home_rounded),
            route: '/',
          ),
          NavTabItem(
            label: 'Pagos',
            icon: const Icon(Icons.payments_outlined),
            iconActive: const Icon(Icons.payments_rounded),
            route: '/cartera',
          ),
          NavTabItem(
            label: 'Mi Casa',
            icon: const Icon(Icons.home_work_outlined),
            iconActive: const Icon(Icons.home_work_rounded),
            route: '/mi-casa',
          ),
          NavTabItem(
            label: 'Config',
            icon: const Icon(Icons.settings_outlined),
            iconActive: const Icon(Icons.settings_rounded),
            route: '/configuracion',
          ),
        ];
      default: // ADMIN
        return [
          NavTabItem(
            label: 'Inicio',
            icon: const Icon(Icons.home_outlined),
            iconActive: const Icon(Icons.home_rounded),
            route: '/',
          ),
          NavTabItem(
            label: 'Cobros',
            icon: const Icon(Icons.account_balance_outlined),
            iconActive: const Icon(Icons.account_balance_rounded),
            route: '/cartera',
          ),
          NavTabItem(
            label: 'Comunidad',
            icon: const Icon(Icons.people_outlined),
            iconActive: const Icon(Icons.people_rounded),
            route: '/comunidad',
          ),
          NavTabItem(
            label: 'Reportes',
            icon: const Icon(Icons.analytics_outlined),
            iconActive: const Icon(Icons.analytics_rounded),
            route: '/reportes',
          ),
          NavTabItem(
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
class NavTabItem {
  final String label;
  final Widget icon;
  final Widget iconActive;
  final String route;

  const NavTabItem({
    required this.label,
    required this.icon,
    required this.iconActive,
    required this.route,
  });
}

/// Enterprise unified sidebar for desktop and tablet screens.
/// Encloses icon and label in a single active pill when expanded.
class DesktopSidebar extends StatelessWidget {
  final List<NavTabItem> tabs;
  final int currentIndex;
  final bool isExpanded;
  final ValueChanged<NavTabItem> onTabTap;

  const DesktopSidebar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.isExpanded,
    required this.onTabTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sidebarWidth = isExpanded ? 220.0 : 76.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: sidebarWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Institutional Header
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: isExpanded ? 16.0 : 14.0,
            ),
            child: isExpanded
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.payments_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Cívica Pago',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.payments_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 8),

          // Navigation Items
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: isExpanded ? 12.0 : 8.0),
              itemCount: tabs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final isSelected = index == currentIndex;

                final itemContent = Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isExpanded ? 14.0 : 0.0,
                    vertical: 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.30)
                          : Colors.transparent,
                      width: 1.2,
                    ),
                  ),
                  child: isExpanded
                      ? Row(
                          children: [
                            IconTheme(
                              data: IconThemeData(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                size: 22,
                              ),
                              child: isSelected ? tab.iconActive : tab.icon,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                tab.label,
                                style: AppTypography.body.copyWith(
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: IconTheme(
                            data: IconThemeData(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              size: 22,
                            ),
                            child: isSelected ? tab.iconActive : tab.icon,
                          ),
                        ),
                );

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    hoverColor: AppColors.primary.withValues(alpha: 0.05),
                    onTap: () => onTabTap(tab),
                    child: isExpanded
                        ? itemContent
                        : Tooltip(message: tab.label, child: itemContent),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
}

