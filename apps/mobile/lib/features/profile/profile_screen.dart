import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../screens/auth/auth_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';

/// Perfil / Más screen.
///
/// Per doc/20-screen-specifications.md (PERFIL):
///   Debe mostrar: foto, nombre, correo, teléfono, rol, conjunto, cerrar sesión.
///   Acciones: editar datos permitidos, cambiar contraseña, tema claro/oscuro.
///
/// Extended: includes "Mi Casa" section and "Solicitudes" menu item
/// with pending badge (solicitudes live here, not in bottom nav).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Mock data — pending solicitudes count
  static const _pendingSolicitudes = 1;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.usuario;
    final nombre = user?['nombre'] as String? ?? 'Usuario';
    final email = user?['email'] as String? ?? '';
    final rol = user?['rol'] as String? ?? '';
    final tenantId = user?['tenantId'] as String? ?? '';

    final rolLabel = _rolName(rol);
    final isPropietario = rol == 'PROPIETARIO';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.xl),

              // ── Avatar ──────────────────────────────────────────────
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  nombre.split(' ').map((w) => w[0]).take(2).join(),
                  style: AppTypography.title.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Nombre + rol ────────────────────────────────────────
              Text(
                nombre,
                style: AppTypography.subtitle.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  rolLabel,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Info personal ────────────────────────────────────────
              _SectionCard(
                children: [
                  _InfoTile(
                    icon: Icons.email_outlined,
                    label: 'Correo',
                    value: email,
                  ),
                  const Divider(height: 1, indent: 56),
                  _InfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Teléfono',
                    value: '+57 300 123 4567', // TODO: real data
                  ),
                  const Divider(height: 1, indent: 56),
                  _InfoTile(
                    icon: Icons.business_outlined,
                    label: 'Conjunto',
                    value: tenantId.isNotEmpty ? 'Portal del Prado' : '—',
                  ),
                  const Divider(height: 1, indent: 56),
                  _InfoTile(
                    icon: Icons.badge_outlined,
                    label: 'Rol',
                    value: rolLabel,
                  ),
                ],
              ),

              // ── Mi Casa (Propietario only) ──────────────────────────
              if (isPropietario) ...[
                const SizedBox(height: AppSpacing.lg),
                _SectionCard(
                  title: 'Mi Casa',
                  children: [
                    _InfoTile(
                      icon: Icons.home_outlined,
                      label: 'Dirección',
                      value: 'Casa 101',
                    ),
                    const Divider(height: 1, indent: 56),
                    _InfoTile(
                      icon: Icons.location_on_outlined,
                      label: 'Etapa',
                      value: 'Etapa 1 — Manzana A',
                    ),
                    const Divider(height: 1, indent: 56),
                    _InfoTile(
                      icon: Icons.calendar_month_outlined,
                      label: 'Modalidad',
                      value: 'Mensual',
                    ),
                    const Divider(height: 1, indent: 56),
                    _InfoTile(
                      icon: Icons.history_outlined,
                      label: 'Antigüedad',
                      value: '2 años',
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // ── Actions menu ─────────────────────────────────────────
              _SectionCard(
                children: [
                  // Solicitudes (Propietario only) — with badge
                  if (isPropietario) ...[
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Solicitudes'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_pendingSolicitudes > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$_pendingSolicitudes',
                                style: AppTypography.small.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textDisabled,
                          ),
                        ],
                      ),
                      onTap: () => context.push('/solicitudes'),
                    ),
                    const Divider(height: 1),
                  ],
                  ValueListenableBuilder<bool>(
                    valueListenable: darkThemeNotifier,
                    builder: (context, isDark, _) {
                      return ListTile(
                        leading: const Icon(Icons.palette_outlined),
                        title: const Text('Tema oscuro'),
                        trailing: Switch(
                          value: isDark,
                          onChanged: (value) {
                            darkThemeNotifier.value = value;
                          },
                          activeThumbColor: AppColors.primary,
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_outlined),
                    title: const Text('Cambiar contraseña'),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textDisabled,
                    ),
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Logout ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<AuthCubit>().logout();
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Cerrar sesión'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  String _rolName(String rol) {
    switch (rol) {
      case 'ADMIN':
        return 'Administrador';
      case 'COBRADOR':
        return 'Cobrador';
      case 'PROPIETARIO':
        return 'Propietario';
      default:
        return rol;
    }
  }
}

/// A grouped card section with optional title.
class _SectionCard extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _SectionCard({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: 4,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              title!,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        Card(child: Column(children: children)),
      ],
    );
  }
}

/// Individual info tile inside a section card.
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      subtitle: Text(
        value,
        style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }
}
