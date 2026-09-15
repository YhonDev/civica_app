import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/top_toast.dart';
import '../cubits/tenant_detail_cubit.dart';
import '../models/platform_models.dart';

/// Screen displaying deep details of a specific tenant: infrastructure projects,
/// current administrators, and cryptographic administrator invitations.
class TenantDetailScreen extends StatelessWidget {
  final String tenantId;

  const TenantDetailScreen({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TenantDetailCubit>(
      create: (_) => TenantDetailCubit()..loadDetail(tenantId),
      child: _TenantDetailView(tenantId: tenantId),
    );
  }
}

class _TenantDetailView extends StatelessWidget {
  final String tenantId;

  const _TenantDetailView({required this.tenantId});

  void _showInviteDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            side: BorderSide(color: AppColors.border),
          ),
          title: Text(
            'Invitar Administrador de Tenant',
            style: AppTypography.subtitle.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Se generará un token criptográfico seguro de un solo uso (TTL 48h). El administrador definirá su contraseña al aceptar la invitación.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Nombre completo',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: nameCtrl,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ej. Carlos Méndez',
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
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'El nombre es obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Correo electrónico',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'admin@urbanizacion.com',
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
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'El correo es obligatorio';
                      }
                      if (!v.contains('@')) {
                        return 'Ingrese un correo válido';
                      }
                      return null;
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
              label: 'Generar invitación',
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48, minWidth: 120),
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
                    final cubit = context.read<TenantDetailCubit>();
                    Navigator.of(dialogContext).pop();
                    final invitation = await cubit.createInvitation(
                      tenantId: tenantId,
                      email: emailCtrl.text.trim(),
                      name: nameCtrl.text.trim(),
                    );
                    if (invitation != null && context.mounted) {
                      _showInvitationCreatedDialog(context, invitation);
                    }
                  },
                  child: Text(
                    'Generar Invitación',
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
  }

  void _showInvitationCreatedDialog(
    BuildContext context,
    TenantInvitationItem invitation,
  ) {
    final token = invitation.invitationToken ?? '';
    final activationUrl = 'https://cuentiva.app/platform/activate?token=$token';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            side: BorderSide(color: AppColors.border),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 26,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Invitación Generada',
                  style: AppTypography.subtitle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Se ha generado la invitación criptográfica para ${invitation.email}.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Copia el enlace de activación para enviarlo al administrador. Por motivos de seguridad, el token no volverá a mostrarse:',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SelectableText(
                    activationUrl,
                    style: AppTypography.micro.copyWith(
                      fontFamily: 'monospace',
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Semantics(
              button: true,
              label: 'Copiar enlace de activación',
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
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: activationUrl));
                    Navigator.of(dialogContext).pop();
                    TopToast.showSuccess(
                      context,
                      'Enlace de activación copiado al portapapeles',
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text(
                    'Copiar Enlace',
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<TenantDetailCubit, TenantDetailState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            TopToast.showError(context, state.errorMessage!);
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.data == null) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            );
          }

          final data = state.data;
          if (data == null) {
            return Center(
              child: Semantics(
                button: true,
                label: 'Reintentar carga de detalle',
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48, minWidth: 160),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<TenantDetailCubit>().loadDetail(tenantId);
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar'),
                  ),
                ),
              ),
            );
          }

          return DefaultTabController(
            length: 3,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.screenPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Navigation & ID Header ─────────────────────────
                          Row(
                            children: [
                              Semantics(
                                button: true,
                                label: 'Volver al inventario de tenants',
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: 48,
                                    minWidth: 48,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_back_rounded),
                                    color: AppColors.textPrimary,
                                    tooltip: 'Volver',
                                    onPressed: () {
                                      if (context.canPop()) {
                                        context.pop();
                                      } else {
                                        context.go('/platform/tenants');
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data.tenant.name,
                                      style: AppTypography.title.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Row(
                                      children: [
                                        Text(
                                          'ID: ${data.tenant.id}',
                                          style: AppTypography.micro.copyWith(
                                            color: AppColors.textSecondary,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Semantics(
                                          button: true,
                                          label: 'Copiar ID del tenant',
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              minHeight: 48,
                                              minWidth: 48,
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.copy_rounded,
                                                size: 14,
                                              ),
                                              color: AppColors.textSecondary,
                                              tooltip: 'Copiar ID',
                                              onPressed: () {
                                                Clipboard.setData(
                                                  ClipboardData(text: data.tenant.id),
                                                );
                                                TopToast.showInfo(
                                                  context,
                                                  'ID del tenant copiado',
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // ── Summary Metrics Bar ────────────────────────────
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.cardPadding),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _SummaryStat(
                                  value: '${data.summary.projects}',
                                  label: 'Proyectos',
                                  icon: Icons.apartment_rounded,
                                ),
                                _SummaryStat(
                                  value: '${data.summary.residents}',
                                  label: 'Residentes',
                                  icon: Icons.home_rounded,
                                ),
                                _SummaryStat(
                                  value: '${data.summary.users}',
                                  label: 'Usuarios',
                                  icon: Icons.people_rounded,
                                ),
                                _SummaryStat(
                                  value: '${data.administrators.length}',
                                  label: 'Admins',
                                  icon: Icons.security_rounded,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // ── Action: Invite Admin ───────────────────────────
                          Align(
                            alignment: Alignment.centerRight,
                            child: Semantics(
                              button: true,
                              label: 'Invitar administrador',
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minHeight: 48),
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.buttonRadius,
                                      ),
                                    ),
                                  ),
                                  onPressed: () => _showInviteDialog(context),
                                  icon: const Icon(Icons.person_add_rounded, size: 18),
                                  label: Text(
                                    '+ Invitar Administrador',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabBarDelegate(
                      tabBar: TabBar(
                        indicatorColor: AppColors.primary,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        tabs: const [
                          Tab(text: 'Proyectos'),
                          Tab(text: 'Administradores'),
                          Tab(text: 'Invitaciones'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  _ProjectsTab(projects: data.projects),
                  _AdminsTab(admins: data.administrators),
                  _InvitationsTab(
                    invitations: state.invitations,
                    tenantId: tenantId,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _SummaryStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.cardValue.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: AppTypography.micro.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ProjectsTab extends StatelessWidget {
  final List<TenantDetailProject> projects;

  const _ProjectsTab({required this.projects});

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return Center(
        child: Text(
          'No hay proyectos registrados en este tenant',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: projects.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final p = projects[index];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: AppColors.accentPurple,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.nombre,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${p.etapas} etapas · ${p.casas} casas',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminsTab extends StatelessWidget {
  final List<TenantDetailAdmin> admins;

  const _AdminsTab({required this.admins});

  @override
  Widget build(BuildContext context) {
    if (admins.isEmpty) {
      return Center(
        child: Text(
          'No hay administradores asignados a este tenant',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: admins.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final admin = admins[index];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  admin.nombre.isNotEmpty ? admin.nombre[0].toUpperCase() : 'A',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      admin.nombre,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      admin.email,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: admin.activo
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  admin.activo ? 'ACTIVO' : 'INACTIVO',
                  style: AppTypography.micro.copyWith(
                    color: admin.activo ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InvitationsTab extends StatelessWidget {
  final List<TenantInvitationItem> invitations;
  final String tenantId;

  const _InvitationsTab({
    required this.invitations,
    required this.tenantId,
  });

  @override
  Widget build(BuildContext context) {
    if (invitations.isEmpty) {
      return Center(
        child: Text(
          'No se han emitido invitaciones en este tenant',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: invitations.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final inv = invitations[index];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.name,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      inv.email,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Expira: ${inv.expiresAt.toLocal().toString().split('.')[0]}',
                      style: AppTypography.micro.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _InvitationStatusBadge(invitation: inv),
                  if (inv.isPending) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Semantics(
                      button: true,
                      label: 'Revocar invitación',
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                          onPressed: () async {
                            final ok = await context
                                .read<TenantDetailCubit>()
                                .revokeInvitation(
                                  tenantId: tenantId,
                                  invitationId: inv.id,
                                );
                            if (ok && context.mounted) {
                              TopToast.showSuccess(
                                context,
                                'Invitación revocada',
                              );
                            }
                          },
                          child: Text(
                            'Revocar',
                            style: AppTypography.micro.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InvitationStatusBadge extends StatelessWidget {
  final TenantInvitationItem invitation;

  const _InvitationStatusBadge({required this.invitation});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    if (invitation.isAccepted) {
      bg = AppColors.success.withValues(alpha: 0.12);
      fg = AppColors.success;
      label = 'ACEPTADA';
    } else if (invitation.isRevoked) {
      bg = AppColors.error.withValues(alpha: 0.12);
      fg = AppColors.error;
      label = 'REVOCADA';
    } else if (invitation.isExpired) {
      bg = AppColors.textDisabled.withValues(alpha: 0.12);
      fg = AppColors.textDisabled;
      label = 'EXPIRADA';
    } else {
      bg = AppColors.info.withValues(alpha: 0.12);
      fg = AppColors.info;
      label = 'PENDIENTE';
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
        label,
        style: AppTypography.micro.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  const _TabBarDelegate({required this.tabBar});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.card,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
