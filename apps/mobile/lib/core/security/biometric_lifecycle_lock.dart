import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/auth_cubit.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/app_theme.dart';
import 'biometric_auth_service.dart';
import 'session_lifecycle_manager.dart';

/// App Lifecycle Biometric Lock (estilo Nequi / Banca Móvil).
///
/// Observa toques táctiles e inactividad mediante [SessionLifecycleManager].
/// Si la biometría está habilitada y el usuario tiene sesión activa,
/// ante inactividad (5 min) o segundo plano (30 seg), se bloquea y
/// solicita la huella dactilar para continuar.
class BiometricLifecycleLock extends StatefulWidget {
  final Widget child;

  const BiometricLifecycleLock({super.key, required this.child});

  @override
  State<BiometricLifecycleLock> createState() => _BiometricLifecycleLockState();
}

class _BiometricLifecycleLockState extends State<BiometricLifecycleLock> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    SessionLifecycleManager.instance.init();
    SessionLifecycleManager.instance.isLockedNotifier.addListener(_onLockStateChanged);
  }

  @override
  void dispose() {
    SessionLifecycleManager.instance.isLockedNotifier.removeListener(_onLockStateChanged);
    super.dispose();
  }

  void _onLockStateChanged() {
    final isLocked = SessionLifecycleManager.instance.isLockedNotifier.value;
    if (isLocked && mounted) {
      final isAuth = context.read<AuthCubit>().state.isAuthenticated;
      if (isAuth) {
        // Disparar automáticamente el prompt al bloquear
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _unlockWithBiometrics();
        });
      } else {
        // Si no está autenticado, no hay nada que bloquear
        SessionLifecycleManager.instance.unlock();
      }
    }
  }

  Future<void> _unlockWithBiometrics() async {
    if (_isAuthenticating) return;
    _isAuthenticating = true;

    final success = await BiometricAuthService.instance.authenticate(
      localizedReason: 'Escanea tu huella dactilar para reanudar Cívica Pago',
    );

    _isAuthenticating = false;

    if (!mounted) return;

    if (success) {
      SessionLifecycleManager.instance.unlock();
    }
  }

  void _handleLogout() {
    SessionLifecycleManager.instance.unlock();
    context.read<AuthCubit>().logout();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => SessionLifecycleManager.instance.recordUserActivity(),
      onPointerMove: (_) => SessionLifecycleManager.instance.recordUserActivity(),
      child: Stack(
        children: [
          widget.child,
          ValueListenableBuilder<bool>(
            valueListenable: SessionLifecycleManager.instance.isLockedNotifier,
            builder: (context, isLocked, _) {
              final authState = context.watch<AuthCubit>().state;
              if (!isLocked || !authState.isAuthenticated) {
                return const SizedBox.shrink();
              }

              final nombreUsuario = authState.usuario?['nombre'] as String? ?? 'Usuario';

              return Positioned.fill(
                child: ValueListenableBuilder<bool>(
                  valueListenable: darkThemeNotifier,
                  builder: (context, isDark, _) {
                    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
                    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
                    final subtextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

                    return Material(
                      color: bgColor,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Spacer(),
                              Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.fingerprint_rounded,
                                  size: 54,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                'Hola, $nombreUsuario',
                                style: AppTypography.subtitle.copyWith(
                                  fontSize: 22,
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Sesión protegida por biometría.\nUsa tu huella dactilar para continuar.',
                                textAlign: TextAlign.center,
                                style: AppTypography.body.copyWith(
                                  color: subtextColor,
                                ),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: FilledButton.icon(
                                  onPressed: _unlockWithBiometrics,
                                  icon: const Icon(Icons.fingerprint_rounded),
                                  label: const Text('Desbloquear con huella'),
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextButton(
                                onPressed: _handleLogout,
                                child: Text(
                                  'Cerrar sesión / Ingresar con clave',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

