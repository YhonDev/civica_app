import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../screens/auth/auth_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/month_selector.dart';
import 'dashboard_cubit.dart';
import 'models/dashboard_data.dart';
import 'widgets/resumen_section.dart';
import 'widgets/evolucion_section.dart';
import 'widgets/modalidades_section.dart';
import 'widgets/estado_cobros_section.dart';
import 'widgets/actividad_section.dart';
import 'widgets/acciones_rapidas_section.dart';
import 'widgets/alertas_section.dart';
import 'widgets/skeleton_loading.dart';

/// Admin Dashboard.
///
/// Per doc/19-dashboard-specification.md:
///   Header: Avatar + Nombre + Rol + Mes + Notificaciones
///   Sin AppBar — header integrado en el scroll
///   Skeleton loading, no spinner
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
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

  static const _sectionCount = 5;

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

            // 1. Resumen: KPI + mini stats
            _buildAnimatedSection(
              index: 0,
              child: ResumenSection(
                recaudoMes: widget.data.recaudoMes,
                metaMensual: widget.data.metaMensual,
                porcentaje: widget.data.porcentaje,
                pagaron: widget.data.pagaron,
                pendientes: widget.data.pendientes,
                mora: widget.data.mora,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 2. Alertas (condicional)
            _buildAnimatedSection(
              index: 1,
              child: AlertasSection(
                alertas: [
                  AlertaItem(
                    titulo: 'Atención',
                    descripcion: 'Existen 3 solicitudes sin revisar.',
                    onTap: () {},
                  )
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 3. Actividad (Hoy)
            _buildAnimatedSection(
              index: 2,
              child: ActividadSection(actividad: widget.data.actividadReciente),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 4. Acciones rápidas
            _buildAnimatedSection(
              index: 3,
              child: const AccionesRapidasSection(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 5. Row: Modalidades + Estado Cobros
            _buildAnimatedSection(
              index: 4,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ModalidadesSection(modalidades: widget.data.modalidades),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: EstadoCobrosSection(estados: widget.data.estadosCobro),
                  ),
                ],
              ),
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
