import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../core/security/biometric_auth_service.dart';
import '../../core/widgets/top_toast.dart';
import '../../features/residentes/widgets/security_section.dart';
import '../../screens/auth/auth_cubit.dart';

/// Reusable System Settings Section (Ajustes del Sistema).
///
/// Shared across Residente, Cobrador, and Admin roles per Atomic Design.
/// Encapsulates:
/// 1. Dark Theme Toggle
/// 2. Native Biometric Auth Toggle (Fingerprint / Face ID)
/// 3. Change Password Trigger
class SystemSettingsSection extends StatefulWidget {
  final Map<String, dynamic>? user;

  const SystemSettingsSection({super.key, this.user});

  @override
  State<SystemSettingsSection> createState() => _SystemSettingsSectionState();
}

class _SystemSettingsSectionState extends State<SystemSettingsSection> {
  bool _isBiometricsSupported = false;
  bool _isBiometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    _cargarBiometriaState();
  }

  Future<void> _cargarBiometriaState() async {
    final supported = await BiometricAuthService.instance.isHardwareSupported();
    final enabled = await BiometricAuthService.instance.isBiometricsEnabled();
    if (mounted) {
      setState(() {
        _isBiometricsSupported = supported;
        _isBiometricsEnabled = enabled;
      });
    }
  }

  Future<void> _toggleBiometria(bool newValue) async {
    if (newValue == true) {
      final authSuccess = await BiometricAuthService.instance.authenticate(
        localizedReason: 'Escanea tu huella para activar el acceso biométrico',
      );
      if (authSuccess) {
        await BiometricAuthService.instance.setBiometricsEnabled(true);
        if (mounted) {
          setState(() => _isBiometricsEnabled = true);
          TopToast.showSuccess(context, 'Autenticación biométrica activada');
        }
      } else {
        if (mounted) {
          TopToast.showError(context, 'No se pudo verificar la huella dactilar');
        }
      }
    } else {
      await BiometricAuthService.instance.setBiometricsEnabled(false);
      if (mounted) {
        setState(() => _isBiometricsEnabled = false);
        TopToast.showSuccess(context, 'Autenticación biométrica desactivada');
      }
    }
  }

  void _mostrarModalCambiarPassword(BuildContext context) {
    final currentUser = widget.user ?? context.read<AuthCubit>().state.usuario;
    final usuarioId = currentUser?['id'] as String? ?? '';
    final nombre = currentUser?['nombre'] as String? ?? 'Usuario';
    final username = currentUser?['username'] as String? ?? currentUser?['email'] as String? ?? '';

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(
            'Ajustes del Sistema',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          child: Column(
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
                leading: Icon(
                  Icons.fingerprint_rounded,
                  color: _isBiometricsSupported ? AppColors.primary : AppColors.textDisabled,
                ),
                title: const Text('Iniciar sesión con huella / Face ID'),
                subtitle: Text(
                  _isBiometricsSupported
                      ? (_isBiometricsEnabled ? 'Habilitado para acceso rápido' : 'Deshabilitado')
                      : 'No disponible en este dispositivo',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
                trailing: _isBiometricsSupported
                    ? Switch(
                        value: _isBiometricsEnabled,
                        onChanged: _toggleBiometria,
                        activeThumbColor: AppColors.primary,
                      )
                    : null,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_outlined),
                title: const Text('Cambiar contraseña'),
                subtitle: const Text('Actualiza tu clave de acceso'),
                trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled),
                onTap: () => _mostrarModalCambiarPassword(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
