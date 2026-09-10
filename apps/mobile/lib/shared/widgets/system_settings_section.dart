import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';
import '../../core/security/biometric_auth_service.dart';
import '../../core/widgets/top_toast.dart';
import '../../features/residentes/widgets/security_section.dart';
import '../../features/auth/auth_cubit.dart';

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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.lg)),
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
                      borderRadius: BorderRadius.circular(AppSpacing.radiusProgress),
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
    return ValueListenableBuilder<bool>(
      valueListenable: darkThemeNotifier,
      builder: (context, isDark, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
              child: Text(
                'Ajustes del Sistema',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                border: Border.all(
                  color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                child: Column(
                  children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.accentPurple.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      child: const Icon(Icons.palette_outlined, color: AppColors.accentPurple, size: 20),
                    ),
                    title: Text(
                      'Tema oscuro',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    subtitle: Text(
                      isDark ? 'Modo noche activo' : 'Modo claro activo',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    trailing: Switch(
                      value: isDark,
                      onChanged: (value) {
                        darkThemeNotifier.value = value;
                      },
                      activeThumbColor: AppColors.primary,
                    ),
                  ),
                  Divider(
                    height: 1,
                    indent: 56,
                    color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5),
                  ),
                  if (_isBiometricsSupported) ...[
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        ),
                        child: const Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 20),
                      ),
                      title: Text(
                        'Acceso biométrico',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      subtitle: Text(
                        _isBiometricsEnabled ? 'Protege tu sesión con huella dactilar' : 'Deshabilitado',
                        style: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      trailing: Switch(
                        value: _isBiometricsEnabled,
                        onChanged: _toggleBiometria,
                        activeThumbColor: AppColors.primary,
                      ),
                    ),
                    Divider(
                      height: 1,
                      indent: 56,
                      color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5),
                    ),
                  ],
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      child: const Icon(Icons.lock_outlined, color: AppColors.error, size: 20),
                    ),
                    title: Text(
                      'Seguridad y Contraseña',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Actualiza tu clave de acceso',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? AppColors.darkTextDisabled : AppColors.lightTextDisabled,
                    ),
                    onTap: () => _mostrarModalCambiarPassword(context),
                  ),
                ],
              ),
            ),
          ),
        ],
        );
      },
    );
  }
}
