import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/top_toast.dart';
import '../cubits/platform_overview_cubit.dart';
import '../models/platform_models.dart';

/// Main dashboard view for Cuentiva Platform (`SUPERADMIN`).
class PlatformOverviewScreen extends StatefulWidget {
  const PlatformOverviewScreen({super.key});

  @override
  State<PlatformOverviewScreen> createState() => _PlatformOverviewScreenState();
}

class _PlatformOverviewScreenState extends State<PlatformOverviewScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PlatformOverviewCubit>().loadOverview();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<PlatformOverviewCubit, PlatformOverviewState>(
        listener: (context, state) {
          if (state is PlatformOverviewError) {
            TopToast.showError(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is PlatformOverviewLoading) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            );
          }

          if (state is PlatformOverviewLoaded) {
            return _buildContent(context, state.data);
          }

          return Center(
            child: Semantics(
              button: true,
              label: 'Reintentar carga de métricas',
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48, minWidth: 160),
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<PlatformOverviewCubit>().loadOverview();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, PlatformOverviewData data) {
    final columns = context.gridColumns;

    return RefreshIndicator(
      onRefresh: () => context.read<PlatformOverviewCubit>().loadOverview(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section Title & Refresh ────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumen de Plataforma',
                        style: AppTypography.title.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Supervisión global de instancias, infraestructura y usuarios',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Actualizar métricas',
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      color: AppColors.primary,
                      tooltip: 'Actualizar',
                      onPressed: () {
                        context.read<PlatformOverviewCubit>().loadOverview();
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Responsive KPI Grid ────────────────────────────────────────
            _buildKpiGrid(context, data, columns),
            const SizedBox(height: AppSpacing.lg),

            // ── Infrastructure & Scope Card ────────────────────────────────
            _buildInfrastructureCard(context),
            const SizedBox(height: AppSpacing.lg),

            // ── Quick Navigation Actions ───────────────────────────────────
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context, PlatformOverviewData data, int columns) {
    final activeTenants = data.tenantsByStatus[TenantStatus.active] ?? 0;
    final suspendedTenants = data.tenantsByStatus[TenantStatus.suspended] ?? 0;

    final kpiCards = [
      _KpiCard(
        title: 'Tenants Registrados',
        value: '${data.totalTenants}',
        subtitle: '$activeTenants activos · $suspendedTenants suspendidos',
        icon: Icons.domain_rounded,
        accentColor: AppColors.primary,
        onTap: () => context.go('/platform/tenants'),
      ),
      _KpiCard(
        title: 'Usuarios Activos',
        value: '${data.activeUsers}',
        subtitle: 'Cuentas operativas en tenants',
        icon: Icons.people_alt_rounded,
        accentColor: AppColors.accentTeal,
      ),
      _KpiCard(
        title: 'Urbanizaciones / Proyectos',
        value: '${data.projects}',
        subtitle: 'Proyectos habitacionales creados',
        icon: Icons.apartment_rounded,
        accentColor: AppColors.accentPurple,
      ),
      _KpiCard(
        title: 'Residentes Totales',
        value: '${data.residents}',
        subtitle: 'Unidades habitacionales en plataforma',
        icon: Icons.home_work_rounded,
        accentColor: AppColors.accentOrange,
      ),
    ];

    if (columns == 1) {
      return Column(
        children: kpiCards
            .map((card) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: card,
                ))
            .toList(),
      );
    }

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: context.isExpanded ? 2.1 : 1.8,
      children: kpiCards,
    );
  }

  Widget _buildInfrastructureCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.dns_rounded,
                  color: AppColors.info,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado de la Infraestructura de Plataforma',
                      style: AppTypography.cardTitle.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Aislamiento estricto y seguridad criptográfica',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _InfraBadge(
                label: 'Base de Datos',
                value: 'Neon AWS Postgres (Healthy)',
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
              ),
              _InfraBadge(
                label: 'Ámbito de Acceso',
                value: 'PLATFORM (SUPERADMIN aislado)',
                icon: Icons.shield_rounded,
                color: AppColors.primary,
              ),
              _InfraBadge(
                label: 'Invitaciones',
                value: 'SHA-256 One-Time (TTL 48h)',
                icon: Icons.key_rounded,
                color: AppColors.accentTeal,
              ),
              _InfraBadge(
                label: 'Auditoría',
                value: 'Inmutable (Append-only)',
                icon: Icons.lock_clock_rounded,
                color: AppColors.accentPurple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: 'Ver inventario de tenants',
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                ),
                onPressed: () => context.go('/platform/tenants'),
                icon: const Icon(Icons.domain_rounded),
                label: Text(
                  'Gestionar Tenants',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Semantics(
            button: true,
            label: 'Ver registro de auditoría',
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: AppColors.border, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                ),
                onPressed: () => context.go('/platform/audit'),
                icon: const Icon(Icons.shield_outlined),
                label: Text(
                  'Ver Auditoría Global',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tokenized KPI Card with high contrast and responsive layout.
class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.stat.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTypography.small.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return Semantics(
      button: true,
      label: '$title: $value',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: content,
      ),
    );
  }
}

/// Compact badge for infrastructure items.
class _InfraBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfraBadge({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$label: ',
            style: AppTypography.small.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: AppTypography.small.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
