import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/auth_cubit.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/app_theme.dart';
import 'biometric_auth_service.dart';

/// App Lifecycle Biometric Lock (estilo Nequi / Banca Móvil).
///
/// Protege la aplicación cuando pasa a segundo plano.
/// Si la biometría está habilitada y el usuario tiene sesión activa,
/// al reabrir la aplicación se solicita la huella dactilar para desbloquear.
class BiometricLifecycleLock extends StatefulWidget {
  final Widget child;

  const BiometricLifecycleLock({super.key, required this.child});

  @override
  State<BiometricLifecycleLock> createState() => _BiometricLifecycleLockState();
}

class _BiometricLifecycleLockState extends State<BiometricLifecycleLock>
    with WidgetsBindingObserver {
  DateTime? _pausedAt;
  bool _isLocked = false;
  bool _isAuthenticating = false;

  // Umbral en segundos para bloquear tras estar en segundo plano
  static const int _lockThresholdSeconds = 4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _checkResumeLock();
    }
  }

  Future<void> _checkResumeLock() async {
    final pausedTime = _pausedAt;
    _pausedAt = null;

    if (pausedTime == null) return;

    final secondsInBackground = DateTime.now().difference(pausedTime).inSeconds;
    if (secondsInBackground < _lockThresholdSeconds) return;

    final isBioEnabled = await BiometricAuthService.instance.isBiometricsEnabled();
    if (!mounted) return;

    final isAuthenticated = context.read<AuthCubit>().state.isAuthenticated;
    if (isBioEnabled && isAuthenticated) {
      setState(() => _isLocked = true);
      _unlockWithBiometrics();
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
      setState(() => _isLocked = false);
    }
  }

  void _handleLogout() {
    setState(() => _isLocked = false);
    context.read<AuthCubit>().logout();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isLocked)
          Positioned.fill(
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
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.fingerprint_rounded,
                              size: 52,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Sesión Protegida',
                            style: AppTypography.subtitle.copyWith(
                              fontSize: 22,
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Usa tu huella dactilar para reanudar el acceso',
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
          ),
      ],
    );
  }
}
