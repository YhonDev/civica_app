import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/auth_cubit.dart';

/// Responsive shell for Cuentiva Platform console.
///
/// Automatically presents a [NavigationRail] on tablet and desktop screens (>= 600dp)
/// and a [BottomNavigationBar] on compact smartphone screens (< 600dp).
class PlatformShell extends StatelessWidget {
  final Widget child;

  const PlatformShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    try {
      final location = GoRouterState.of(context).matchedLocation;
      if (location.startsWith('/platform/tenants')) return 1;
      if (location.startsWith('/platform/audit')) return 2;
      return 0;
    } catch (_) {
      return 0;
    }
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/platform/overview');
        break;
      case 1:
        context.go('/platform/tenants');
        break;
      case 2:
        context.go('/platform/audit');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = context.isWideScreen;
    final selectedIndex = _calculateSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isWide) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            // ── Persistent Navigation Rail (Tablet / Desktop) ──────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border(
                  right: BorderSide(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
              ),
              child: NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) => _onItemTapped(context, index),
                backgroundColor: AppColors.card,
                indicatorColor: AppColors.primary.withValues(alpha: 0.15),
                minWidth: 72,
                minExtendedWidth: 220,
                extended: context.screenWidth >= AppBreakpoints.medium,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                    horizontal: AppSpacing.sm,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: AppColors.onPrimary,
                          size: 28,
                        ),
                      ),
                      if (context.screenWidth >= AppBreakpoints.medium) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Cuentiva Platform',
                          style: AppTypography.cardTitle.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            'SUPERADMIN',
                            style: AppTypography.micro.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                trailing: Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: Semantics(
                        button: true,
                        label: 'Cerrar sesión de plataforma',
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: 48,
                            minWidth: 48,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.logout_rounded),
                            color: AppColors.error,
                            tooltip: 'Cerrar sesión',
                            onPressed: () {
                              context.read<AuthCubit>().logout();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard_rounded),
                    label: Text('Resumen'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.domain_outlined),
                    selectedIcon: Icon(Icons.domain_rounded),
                    label: Text('Tenants'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.shield_outlined),
                    selectedIcon: Icon(Icons.shield_rounded),
                    label: Text('Auditoría'),
                  ),
                ],
              ),
            ),

            // ── Main Content Area ──────────────────────────────────────────────
            Expanded(
              child: Column(
                children: [
                  _PlatformTopBar(isWide: true, isDark: isDark),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── Compact Mobile Layout (< 600dp) ──────────────────────────────────
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: _PlatformTopBar(isWide: false, isDark: isDark),
      ),
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.border,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => _onItemTapped(context, index),
          backgroundColor: AppColors.card,
          indicatorColor: AppColors.primary.withValues(alpha: 0.15),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Resumen',
            ),
            NavigationDestination(
              icon: Icon(Icons.domain_outlined),
              selectedIcon: Icon(Icons.domain_rounded),
              label: 'Tenants',
            ),
            NavigationDestination(
              icon: Icon(Icons.shield_outlined),
              selectedIcon: Icon(Icons.shield_rounded),
              label: 'Auditoría',
            ),
          ],
        ),
      ),
    );
  }
}

/// Header bar containing platform identity badges, environment status, and quick user actions.
class _PlatformTopBar extends StatelessWidget {
  final bool isWide;
  final bool isDark;

  const _PlatformTopBar({required this.isWide, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (!isWide) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: AppColors.onPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                'Cuentiva Platform',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else ...[
            Text(
              'Consola Operativa de Plataforma',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          const Spacer(),

          // ── Environment Badge ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Producción',
                  style: AppTypography.small.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          // ── Logout Action on Compact Mobile ────────────────────────────────
          if (!isWide)
            Semantics(
              button: true,
              label: 'Cerrar sesión',
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 48,
                  minWidth: 48,
                ),
                child: IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  color: AppColors.error,
                  tooltip: 'Cerrar sesión',
                  onPressed: () {
                    context.read<AuthCubit>().logout();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
