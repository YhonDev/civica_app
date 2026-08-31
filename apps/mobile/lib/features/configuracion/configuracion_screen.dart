import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../screens/auth/auth_cubit.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/user_profile_header.dart';
import '../../shared/widgets/basic_information_section.dart';
import '../../shared/widgets/system_settings_section.dart';

/// Screen Configuración.
///
/// Refactored under Design System Atomic Design architecture:
/// 1. [UserProfileHeader] -> Avatar + Name + Role Badge.
/// 2. [BasicInformationSection] -> Role-adaptive basic info card.
/// 3. [SystemSettingsSection] -> Dark theme + Biometric auth + Change password.
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
    final rol = user?['rol'] as String? ?? '';

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

              // 1. Componente Atómico: User Profile Header
              UserProfileHeader(
                nombre: nombre,
                rol: rol,
              ),

              const SizedBox(height: AppSpacing.xl),

              // 2. Componente Atómico: Basic Information Section (Adaptativo por rol)
              BasicInformationSection(
                user: user,
                proyectoNombre: _proyectoNombreBackend,
              ),

              // Herramientas adicionales según rol
              if (rol == 'COBRADOR' || rol == 'ADMIN') ...[
                const SizedBox(height: AppSpacing.lg),
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
              ],

              const SizedBox(height: AppSpacing.lg),

              // 3. Componente Atómico: System Settings Section (Tema oscuro, Biometría, Cambiar Contraseña)
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
      ),
    );
  }
}
