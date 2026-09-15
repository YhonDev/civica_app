import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/top_toast.dart';
import '../cubits/platform_tenants_cubit.dart';
import '../models/platform_models.dart';

/// Screen for managing tenant inventory, filtering by status, creating new instances,
/// and updating tenant lifecycle states.
class TenantManagementScreen extends StatefulWidget {
  const TenantManagementScreen({super.key});

  @override
  State<TenantManagementScreen> createState() => _TenantManagementScreenState();
}

class _TenantManagementScreenState extends State<TenantManagementScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<PlatformTenantsCubit>().loadTenants();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showCreateTenantDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    TenantStatus selectedStatus = TenantStatus.active;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                side: BorderSide(color: AppColors.border),
              ),
              title: Text(
                'Nuevo Tenant',
                style: AppTypography.subtitle.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nombre de la Urbanización o Instancia',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: nameCtrl,
                        autofocus: true,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ej. Villa Campestre',
                          filled: true,
                          fillColor: AppColors.searchField,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Estado Inicial',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      DropdownButtonFormField<TenantStatus>(
                        initialValue: selectedStatus,
                        dropdownColor: AppColors.card,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.searchField,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                        ),
                        items: TenantStatus.values.map((s) {
                          return DropdownMenuItem(
                            value: s,
                            child: Text(s.label),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedStatus = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Semantics(
                  button: true,
                  label: 'Cancelar',
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48, minWidth: 80),
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(
                        'Cancelar',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Guardar tenant',
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48, minWidth: 100),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                        ),
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final cubit = context.read<PlatformTenantsCubit>();
                        Navigator.of(dialogContext).pop();
                        final ok = await cubit.createTenant(
                          name: nameCtrl.text.trim(),
                          status: selectedStatus,
                        );
                        if (ok && context.mounted) {
                          TopToast.showSuccess(
                            context,
                            'Tenant "${nameCtrl.text.trim()}" creado correctamente',
                          );
                        }
                      },
                      child: Text(
                        'Crear Tenant',
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangeStatusSheet(
    BuildContext context,
    PlatformTenantSummary tenant,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.bottomSheetRadius),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusProgress),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Cambiar Estado de Tenant',
                  style: AppTypography.subtitle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  tenant.name,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...TenantStatus.values.map((status) {
                  final isCurrent = status == tenant.status;
                  return Semantics(
                    button: true,
                    label: 'Cambiar a ${status.label}',
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      leading: Icon(
                        _iconForStatus(status),
                        color: _colorForStatus(status),
                      ),
                      title: Text(
                        status.label,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      trailing: isCurrent
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                            )
                          : null,
                      onTap: isCurrent
                          ? null
                          : () async {
                              final cubit = context.read<PlatformTenantsCubit>();
                              Navigator.of(sheetContext).pop();
                              final ok = await cubit.updateTenantStatus(tenant.id, status);
                              if (ok && context.mounted) {
                                TopToast.showSuccess(
                                  context,
                                  'Estado actualizado a ${status.label}',
                                );
                              }
                            },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlatformTenantsCubit, PlatformTenantsState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          TopToast.showError(context, state.errorMessage!);
        }
      },
      builder: (context, state) {
        final tenants = state.filteredTenants;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Title & Add Button ──────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gestión de Tenants',
                            style: AppTypography.title.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Instancias activas de urbanizaciones en Cuentiva',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Crear nuevo tenant',
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
                          onPressed: () => _showCreateTenantDialog(context),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(
                            '+ Nuevo Tenant',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Search & Filter Controls ───────────────────────────────
                TextField(
                  controller: _searchCtrl,
                  onChanged: (val) {
                    context.read<PlatformTenantsCubit>().updateSearchQuery(val);
                  },
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Buscar tenant por nombre o ID...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchCtrl.clear();
                              context.read<PlatformTenantsCubit>().updateSearchQuery('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.searchField,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // ── Filter Chips ───────────────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Todos',
                        isSelected: state.statusFilter == null,
                        onSelected: () {
                          context
                              .read<PlatformTenantsCubit>()
                              .loadTenants(statusFilter: () => null);
                        },
                      ),
                      ...TenantStatus.values.map((status) {
                        return Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.sm),
                          child: _FilterChip(
                            label: status.label,
                            isSelected: state.statusFilter == status,
                            onSelected: () {
                              context
                                  .read<PlatformTenantsCubit>()
                                  .loadTenants(statusFilter: () => status);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Tenant List ────────────────────────────────────────────
                Expanded(
                  child: state.isLoading && tenants.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primary,
                          ),
                        )
                      : tenants.isEmpty
                          ? Center(
                              child: Text(
                                'No se encontraron tenants con los filtros seleccionados',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () =>
                                  context.read<PlatformTenantsCubit>().loadTenants(),
                              child: ListView.separated(
                                itemCount: tenants.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (context, index) {
                                  final tenant = tenants[index];
                                  return _TenantCard(
                                    tenant: tenant,
                                    onTap: () {
                                      context.go('/platform/tenants/${tenant.id}');
                                    },
                                    onChangeStatus: () {
                                      _showChangeStatusSheet(context, tenant);
                                    },
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static IconData _iconForStatus(TenantStatus status) {
    switch (status) {
      case TenantStatus.active:
        return Icons.check_circle_outline_rounded;
      case TenantStatus.suspended:
        return Icons.pause_circle_outline_rounded;
      case TenantStatus.maintenance:
        return Icons.build_circle_outlined;
      case TenantStatus.archived:
        return Icons.archive_outlined;
    }
  }

  static Color _colorForStatus(TenantStatus status) {
    switch (status) {
      case TenantStatus.active:
        return AppColors.success;
      case TenantStatus.suspended:
        return AppColors.error;
      case TenantStatus.maintenance:
        return AppColors.warning;
      case TenantStatus.archived:
        return AppColors.textDisabled;
    }
  }
}

/// Tenant presentation card with infrastructure statistics.
class _TenantCard extends StatelessWidget {
  final PlatformTenantSummary tenant;
  final VoidCallback onTap;
  final VoidCallback onChangeStatus;

  const _TenantCard({
    required this.tenant,
    required this.onTap,
    required this.onChangeStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name, Status Badge, More Actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tenant.name,
                          style: AppTypography.cardTitle.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'ID: ${tenant.id}',
                          style: AppTypography.micro.copyWith(
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: tenant.status),
                  const SizedBox(width: AppSpacing.xs),
                  Semantics(
                    button: true,
                    label: 'Cambiar estado del tenant',
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                      child: IconButton(
                        icon: const Icon(Icons.more_vert_rounded),
                        color: AppColors.textSecondary,
                        tooltip: 'Opciones de estado',
                        onPressed: onChangeStatus,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),

              // Metrics Row
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: [
                  _MetricPill(
                    icon: Icons.apartment_rounded,
                    label: '${tenant.projects} proyectos',
                  ),
                  _MetricPill(
                    icon: Icons.home_rounded,
                    label: '${tenant.houses} casas',
                  ),
                  _MetricPill(
                    icon: Icons.people_outline_rounded,
                    label: '${tenant.residents} residentes',
                  ),
                  _MetricPill(
                    icon: Icons.badge_outlined,
                    label: '${tenant.users} usuarios',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Status badge pill with design token colors.
class _StatusBadge extends StatelessWidget {
  final TenantStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status) {
      case TenantStatus.active:
        bg = AppColors.success.withValues(alpha: 0.12);
        fg = AppColors.success;
        break;
      case TenantStatus.suspended:
        bg = AppColors.error.withValues(alpha: 0.12);
        fg = AppColors.error;
        break;
      case TenantStatus.maintenance:
        bg = AppColors.warning.withValues(alpha: 0.12);
        fg = AppColors.warning;
        break;
      case TenantStatus.archived:
        bg = AppColors.textDisabled.withValues(alpha: 0.12);
        fg = AppColors.textDisabled;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        status.label,
        style: AppTypography.micro.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Compact pill for metrics inside cards.
class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.small.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Filter chip component complying with minimum touch targets.
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Filtrar por $label',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: FilterChip(
          label: Text(
            label,
            style: AppTypography.small.copyWith(
              color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onSelected(),
          backgroundColor: AppColors.surface,
          selectedColor: AppColors.primary,
          showCheckmark: false,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
        ),
      ),
    );
  }
}
