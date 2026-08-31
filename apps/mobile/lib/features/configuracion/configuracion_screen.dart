import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../screens/auth/auth_cubit.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../residentes/widgets/security_section.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  String? _proyectoNombreBackend;

  @override
  void initState() {
    super.initState();
    _cargarDatosBackend();
  }

  Future<void> _cargarDatosBackend() async {
    try {
      final resProj = await ApiClient.instance.get<Map<String, dynamic>>('/proyectos/actual');
      if (mounted && resProj.data != null) {
        final nombreBackend = resProj.data!['nombre'] as String?;
        if (nombreBackend != null && nombreBackend.isNotEmpty) {
          setState(() {
            _proyectoNombreBackend = nombreBackend;
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.usuario;
    final nombre = user?['nombre'] as String? ?? 'Usuario';
    final email = user?['email'] as String? ?? '';
    final rol = user?['rol'] as String? ?? '';
    final tenantId = user?['tenantId'] as String? ?? '';

    final rolLabel = _rolName(rol);

    // Obtención dinámica del nombre del proyecto desde el backend
    final proyectoNombre = _proyectoNombreBackend ??
        ((tenantId.isEmpty || tenantId.contains('-'))
            ? 'Urbanización San Sebastián'
            : tenantId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  nombre.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join(),
                  style: AppTypography.title.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Name and Role
              Text(
                nombre,
                style: AppTypography.subtitle.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

              // Basic Info
              _SectionCard(
                title: 'Información Básica',
                children: [
                  _InfoTile(
                    icon: Icons.email_outlined,
                    label: 'Correo registrado',
                    value: email.isNotEmpty ? email : 'No se ha agregado correo',
                  ),
                  const Divider(height: 1, indent: 56),
                  _InfoTile(
                    icon: Icons.business_outlined,
                    label: 'Proyecto / Urbanización',
                    value: proyectoNombre,
                  ),
                ],
              ),

              // Herramientas según rol
              if (rol == 'COBRADOR' || rol == 'ADMIN') ...[
                const SizedBox(height: AppSpacing.lg),
                _SectionCard(
                  title: 'Herramientas',
                  children: [
                    if (rol == 'COBRADOR')
                      ListTile(
                        leading: const Icon(Icons.cloud_sync_outlined),
                        title: const Text('Cola de Sincronización'),
                        subtitle: const Text('Ver pagos pendientes de envío'),
                        trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled),
                        onTap: () => context.push('/sync-queue'),
                      ),
                    if (rol == 'ADMIN')
                      ListTile(
                        leading: const Icon(Icons.mail_lock_outlined),
                        title: const Text('Notificaciones Fallidas'),
                        subtitle: const Text('Revisar correos no entregados'),
                        trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled),
                        onTap: () => context.push('/notificaciones-fallidas'),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Configuration / Settings
              _SectionCard(
                title: 'Ajustes del Sistema',
                children: [
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
                    subtitle: const Text('Actualiza tu clave de acceso'),
                    trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled),
                    onTap: () => _mostrarModalCambiarPassword(context, user),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Botón rojo para Cerrar Sesión
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

  void _mostrarModalCambiarPassword(BuildContext context, Map<String, dynamic>? user) {
    final usuarioId = user?['id'] as String? ?? '';
    final nombre = user?['nombre'] as String? ?? 'Usuario';
    final username = user?['username'] as String? ?? user?['email'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle indicator
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SecuritySection(
                  usuarioId: usuarioId,
                  nombre: nombre,
                  initialUsername: username,
                  isAdmin: false,
                  autoExpandPassword: true,
                  onCredentialsUpdated: () {
                    Navigator.of(ctx).pop();
                  },
                  onCancel: () {
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _rolName(String rol) {
    switch (rol) {
      case 'ADMIN':
        return 'Administrador';
      case 'COBRADOR':
        return 'Cobrador';
      case 'PROPIETARIO':
      case 'RESIDENTE':
        return 'Residente';
      default:
        return rol;
    }
  }
}

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
            padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
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
