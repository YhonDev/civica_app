import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/top_toast.dart';
import '../cubits/platform_audit_cubit.dart';
import '../models/platform_models.dart';

/// Screen displaying the immutable platform audit log with filtering and expandable metadata.
class PlatformAuditScreen extends StatefulWidget {
  const PlatformAuditScreen({super.key});

  @override
  State<PlatformAuditScreen> createState() => _PlatformAuditScreenState();
}

class _PlatformAuditScreenState extends State<PlatformAuditScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PlatformAuditCubit>().loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<PlatformAuditCubit, PlatformAuditState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            TopToast.showError(context, state.errorMessage!);
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Title & Refresh ─────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Registro de Auditoría',
                            style: AppTypography.title.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Trazabilidad inmutable de eventos y operaciones de plataforma',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Recargar eventos de auditoría',
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                        child: IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          color: AppColors.primary,
                          tooltip: 'Recargar',
                          onPressed: () {
                            context.read<PlatformAuditCubit>().loadEvents();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Action Filter Chips ────────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _AuditFilterChip(
                        label: 'Todos',
                        isSelected: state.actionFilter == null,
                        onSelected: () {
                          context
                              .read<PlatformAuditCubit>()
                              .loadEvents(actionFilter: () => null);
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _AuditFilterChip(
                        label: 'Logins',
                        isSelected: state.actionFilter == 'PLATFORM_LOGIN',
                        onSelected: () {
                          context
                              .read<PlatformAuditCubit>()
                              .loadEvents(actionFilter: () => 'PLATFORM_LOGIN');
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _AuditFilterChip(
                        label: 'Creación Tenants',
                        isSelected: state.actionFilter == 'TENANT_CREATED',
                        onSelected: () {
                          context
                              .read<PlatformAuditCubit>()
                              .loadEvents(actionFilter: () => 'TENANT_CREATED');
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _AuditFilterChip(
                        label: 'Invitaciones',
                        isSelected: state.actionFilter == 'ADMIN_INVITATION_CREATED',
                        onSelected: () {
                          context.read<PlatformAuditCubit>().loadEvents(
                                actionFilter: () => 'ADMIN_INVITATION_CREATED',
                              );
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _AuditFilterChip(
                        label: 'Activaciones',
                        isSelected: state.actionFilter == 'ADMIN_ACTIVATED',
                        onSelected: () {
                          context
                              .read<PlatformAuditCubit>()
                              .loadEvents(actionFilter: () => 'ADMIN_ACTIVATED');
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _AuditFilterChip(
                        label: 'Estado Tenants',
                        isSelected: state.actionFilter == 'TENANT_STATUS_UPDATED',
                        onSelected: () {
                          context.read<PlatformAuditCubit>().loadEvents(
                                actionFilter: () => 'TENANT_STATUS_UPDATED',
                              );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Event Timeline List ────────────────────────────────────
                Expanded(
                  child: state.isLoading && state.events.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primary,
                          ),
                        )
                      : state.events.isEmpty
                          ? Center(
                              child: Text(
                                'No se registraron eventos con los filtros seleccionados',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () =>
                                  context.read<PlatformAuditCubit>().loadEvents(),
                              child: ListView.separated(
                                itemCount: state.events.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (context, index) {
                                  final event = state.events[index];
                                  return _AuditEventCard(event: event);
                                },
                              ),
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Card showing individual immutable audit event with expandable metadata.
class _AuditEventCard extends StatefulWidget {
  final PlatformAuditEventItem event;

  const _AuditEventCard({required this.event});

  @override
  State<_AuditEventCard> createState() => _AuditEventCardState();
}

class _AuditEventCardState extends State<_AuditEventCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final hasMetadata = event.metadata != null && event.metadata!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Event Header: Action Badge & Timestamp ───────────────────
            Row(
              children: [
                _ActionBadge(action: event.action),
                const Spacer(),
                Text(
                  _formatDate(event.createdAt),
                  style: AppTypography.micro.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Resource and Actor Info ──────────────────────────────────
            Row(
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Recurso: ',
                  style: AppTypography.small.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  event.resource,
                  style: AppTypography.small.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (event.resourceId != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '(${event.resourceId})',
                      style: AppTypography.micro.copyWith(
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xs),

            // ── Actor & IP Address ───────────────────────────────────────
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Actor: ',
                  style: AppTypography.small.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  event.actorId != null
                      ? event.actorId!.substring(0, 8)
                      : 'Sistema',
                  style: AppTypography.small.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
                if (event.ipAddress != null) ...[
                  const SizedBox(width: AppSpacing.md),
                  Icon(
                    Icons.language_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    event.ipAddress!,
                    style: AppTypography.micro.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),

            // ── Metadata Expandable Section ──────────────────────────────
            if (hasMetadata) ...[
              const SizedBox(height: AppSpacing.sm),
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        _expanded ? 'Ocultar metadatos' : 'Ver metadatos',
                        style: AppTypography.micro.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_expanded) ...[
                const SizedBox(height: AppSpacing.xs),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: SelectableText(
                    const JsonEncoder.withIndent('  ').convert(event.metadata),
                    style: AppTypography.micro.copyWith(
                      fontFamily: 'monospace',
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year;
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min:$s';
  }
}

/// Action badge with distinctive semantic colors.
class _ActionBadge extends StatelessWidget {
  final String action;

  const _ActionBadge({required this.action});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    if (action.contains('LOGIN')) {
      color = AppColors.info;
      icon = Icons.login_rounded;
    } else if (action.contains('CREATED')) {
      color = AppColors.success;
      icon = Icons.add_circle_outline_rounded;
    } else if (action.contains('ACTIVATED')) {
      color = AppColors.accentTeal;
      icon = Icons.verified_rounded;
    } else if (action.contains('UPDATED')) {
      color = AppColors.warning;
      icon = Icons.edit_note_rounded;
    } else if (action.contains('REVOKED') || action.contains('DELETED')) {
      color = AppColors.error;
      icon = Icons.cancel_outlined;
    } else {
      color = AppColors.accentPurple;
      icon = Icons.shield_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            action,
            style: AppTypography.micro.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Accessible filter chip for audit screen.
class _AuditFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _AuditFilterChip({
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
