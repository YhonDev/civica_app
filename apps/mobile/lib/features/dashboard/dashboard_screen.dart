import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../screens/auth/auth_cubit.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/month_selector.dart';
import '../../shared/widgets/kpi_card.dart';
import '../../shared/widgets/module_summary_card.dart';
import 'dashboard_cubit.dart';
import 'models/dashboard_data.dart';
import 'widgets/actividad_section.dart';
import 'widgets/acciones_rapidas_section.dart';
import 'widgets/skeleton_loading.dart';

/// Admin Dashboard.
///
/// Per doc/19-dashboard-specification.md:
///   Header: Avatar + Nombre + Rol + Mes + Notificaciones
///   Sin AppBar — header integrado en el scroll
///   Skeleton loading, no spinner
class DashboardScreen extends StatelessWidget {
  /// Optional pre-configured cubit (for testing or custom setups).
  /// If null, a default [DashboardCubit] is created and loadCurrentMonth() is called.
  final DashboardCubit? cubit;

  const DashboardScreen({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<DashboardCubit>.value(
        value: cubit!,
        child: const _DashboardBody(),
      );
    }
    return BlocProvider<DashboardCubit>(
      create: (_) => DashboardCubit()..loadCurrentMonth(),
      child: const _DashboardBody(),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.usuario;
    final nombre = user?['nombre'] as String? ?? 'Admin';
    final rol = user?['rol'] as String? ?? '';
    final rolLabel = rol == 'ADMIN' ? 'Administrador' : rol;

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            switch (state) {
              case DashboardInitial():
              case DashboardLoading():
                return _DashboardHeader(
                  nombre: nombre,
                  rolLabel: rolLabel,
                  child: const _SkeletonBody(),
                );
              case DashboardLoaded(data: final data, mes: final mes, anio: final anio):
                return _DashboardHeader(
                  nombre: nombre,
                  rolLabel: rolLabel,
                  child: _DashboardContent(
                    data: data,
                    currentMonth: DateTime(anio, mes, 1),
                  ),
                );
              case DashboardError(message: final msg):
                return _DashboardHeader(
                  nombre: nombre,
                  rolLabel: rolLabel,
                  child: _ErrorView(
                    message: msg,
                    onRetry: () =>
                        context.read<DashboardCubit>().loadCurrentMonth(),
                  ),
                );
              default:
                return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }
}

/// Clean header per dashboard-specification.md.
///
/// Layout: Avatar + (Nombre + Rol) | Mes | Notificaciones
class _DashboardHeader extends StatelessWidget {
  final String nombre;
  final String rolLabel;
  final Widget child;

  const _DashboardHeader({
    required this.nombre,
    required this.rolLabel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  nombre.split(' ').map((w) => w[0]).take(2).join(),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Nombre + rol
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre.split(' ').first,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      rolLabel,
                      style: AppTypography.small.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Notificaciones
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: AppColors.textSecondary,
                onPressed: () {},
                tooltip: 'Notificaciones',
              ),
            ],
          ),
        ),

        // ── Content (scrollable) ─────────────────────────────────────
        Expanded(child: child),
      ],
    );
  }
}

class _DashboardContent extends StatefulWidget {
  final DashboardData data;
  final DateTime currentMonth;

  const _DashboardContent({
    required this.data,
    required this.currentMonth,
  });

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;

  static const _sectionCount = 7;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  @override
  void didUpdateWidget(covariant _DashboardContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data || oldWidget.currentMonth != widget.currentMonth) {
      _restartAnimations();
    }
  }

  void _initAnimations() {
    _controllers = List.generate(
      _sectionCount,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 250),
      ),
    );

    _fadeAnimations = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOutCubic))
        .map((c) => Tween<double>(begin: 0.0, end: 1.0).animate(c))
        .toList();

    _slideAnimations = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOutCubic))
        .map((c) =>
            Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
                .animate(c))
        .toList();

    _startStagger();
  }

  void _restartAnimations() {
    for (var c in _controllers) {
      c.reset();
    }
    _startStagger();
  }

  Future<void> _startStagger() async {
    for (var i = 0; i < _controllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) _controllers[i].forward();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _buildAnimatedSection({required int index, required Widget child}) {
    if (index >= _controllers.length) return child;
    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(
        position: _slideAnimations[index],
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await context.read<DashboardCubit>().loadDashboard(
              widget.currentMonth.month,
              widget.currentMonth.year,
            );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month selector
            Center(
              child: MonthSelector(
                currentMonth: widget.currentMonth,
                onMonthChanged: (newMonth) {
                  context.read<DashboardCubit>().changeMonth(
                        newMonth.month,
                        newMonth.year,
                      );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _buildAnimatedSection(
              index: 0,
              child: Builder(
                builder: (context) {
                  final recaudo = widget.data.recaudoMes;
                  final amountStr = '\$ ${NumberFormat.decimalPattern('es_CO').format(recaudo.toInt())}';
                  return KpiCard(
                    title: 'Recaudo del Mes',
                    amount: amountStr,
                    percentage: widget.data.porcentaje,
                    subtitle: 'Meta alcanzada',
                    actionLabel: 'Abrir módulo',
                    onTap: () => context.go('/estado'),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 2. Centro de Atención
            _buildAnimatedSection(
              index: 1,
              child: ModuleSummaryCard(
                title: '⚠ Centro de Atención',
                items: [
                  ModuleSummaryItem(
                    label: 'Solicitudes pendientes',
                    value: widget.data.solicitudesPendientes.toString(),
                    color: AppColors.warning,
                  ),
                  ModuleSummaryItem(
                    label: 'Propietarios en mora',
                    value: widget.data.propietariosMora.toString(),
                    color: AppColors.error,
                  ),
                  ModuleSummaryItem(
                    label: 'Pagos requieren revisión',
                    value: widget.data.pagosRevision.toString(),
                    color: AppColors.info,
                  ),
                ],
                actionLabel: 'Abrir módulo',
                onActionTap: () => context.push('/solicitudes'),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 3. Cobros (Grid Layout)
            _buildAnimatedSection(
              index: 2,
              child: ModuleSummaryCard(
                title: 'Cobros',
                isGrid: true,
                items: [
                  ModuleSummaryItem(
                    label: 'Pagados',
                    value: widget.data.pagaron.toString(),
                    color: AppColors.success,
                  ),
                  ModuleSummaryItem(
                    label: 'Pendientes',
                    value: widget.data.pendientes.toString(),
                    color: AppColors.textPrimary,
                  ),
                  ModuleSummaryItem(
                    label: 'En mora',
                    value: widget.data.propietariosMora.toString(),
                    color: AppColors.error,
                  ),
                ],
                actionLabel: 'Abrir módulo',
                onActionTap: () => context.go('/cartera'),
                extraContent: widget.data.cobrosPorSemana.isNotEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Desglose semanal', style: AppTypography.small.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          const SizedBox(height: AppSpacing.sm),
                          ...widget.data.cobrosPorSemana.map((semana) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 70,
                                    child: Text('Semana ${semana.semana}', style: AppTypography.small.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                                  ),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('${semana.pagados} pagados', style: AppTypography.small.copyWith(color: AppColors.success)),
                                        Text('${semana.pendientes} pend.', style: AppTypography.small.copyWith(color: AppColors.textSecondary)),
                                        if (semana.mora > 0)
                                          Text('${semana.mora} mora', style: AppTypography.small.copyWith(color: AppColors.error)),
                                        if (semana.mora == 0)
                                          const SizedBox(width: 30),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 4. Actividad (Hoy)
            _buildAnimatedSection(
              index: 3,
              child: ActividadSection(actividad: widget.data.actividadReciente),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 5. Comunidad
            _buildAnimatedSection(
              index: 4,
              child: ModuleSummaryCard(
                title: 'Comunidad',
                items: [
                  ModuleSummaryItem(
                    label: 'Propietarios registrados',
                    value: widget.data.totalPropietarios.toString(),
                    color: AppColors.textPrimary,
                  ),
                  ModuleSummaryItem(
                    label: 'Nuevos esta semana',
                    value: widget.data.nuevosPropietariosSemana.toString(),
                    color: AppColors.info,
                  ),
                ],
                actionLabel: 'Abrir módulo',
                onActionTap: () => context.go('/comunidad'),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 6. Acciones rápidas
            _buildAnimatedSection(
              index: 5,
              child: const AccionesRapidasSection(),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loading state — per docs, no full-screen spinner.
class _SkeletonBody extends StatelessWidget {
  const _SkeletonBody();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          // Month skeleton
          const Center(child: SkeletonBox(width: 140, height: 32)),
          const SizedBox(height: AppSpacing.lg),
          // KPI skeleton
          const SkeletonCard(),
          const SizedBox(height: AppSpacing.md),
          // Mini stats row
          const Row(
            children: [
              Expanded(child: SkeletonBox(height: 80)),
              SizedBox(width: 8),
              Expanded(child: SkeletonBox(height: 80)),
              SizedBox(width: 8),
              Expanded(child: SkeletonBox(height: 80)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const SkeletonCard(),
          const SizedBox(height: AppSpacing.md),
          const Row(
            children: [
              Expanded(child: SkeletonCard()),
              SizedBox(width: 8),
              Expanded(child: SkeletonCard()),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
