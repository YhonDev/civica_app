import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/user_profile_header.dart';
import '../../shared/widgets/system_settings_section.dart';
import '../../shared/widgets/screen_header.dart';

/// Screen Configuración.
///
/// Refactored under Design System Atomic Design architecture:
/// 1. [UserProfileHeader] -> Avatar + Name + Role Badge.
/// 2. [SystemSettingsSection] -> Dark theme + Biometric auth + Change password.
class ConfiguracionScreen extends StatelessWidget {
  const ConfiguracionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.usuario;
    final nombre = user?['nombre'] as String? ?? 'Usuario';
    final rol = user?['rol'] as String? ?? '';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenHeader(title: 'Configuración'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Column(
                  children: [
                    UserProfileHeader(
                      nombre: nombre,
                      rol: rol,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Herramientas adicionales según rol
                    if (rol == 'COBRADOR' || rol == 'ADMIN') ...[
                      Card(
                        child: Column(
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
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // 2. Componente Atómico: System Settings Section (Tema oscuro, Biometría, Notificaciones, Seguridad en modal)
                    SystemSettingsSection(user: user),

                    const SizedBox(height: AppSpacing.xl),

                    // Botón para Cerrar Sesión
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
            ],
          ),
        ),
      ),
    );
  }
}
