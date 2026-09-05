import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/auth_cubit.dart';
import 'biometric_auth_service.dart';
import 'session_lifecycle_manager.dart';

/// Detector global de actividad e inactividad biométrica.
///
/// Protege la privacidad visual con desenfoque (blur) cuando se requiere autenticación:
/// - Al ocurrir inactividad (>5 min) o retorno de segundo plano (>30 seg),
///   desenfoca el contenido sensible de la pantalla con un velo translúcido claro
///   y activa directamente el sensor nativo de huella dactilar de Android.
/// - Si el usuario verifica la huella, el desenfoque se retira al instante y continúa en su pantalla.
/// - Si cancela o falla, se redirige limpiamente a la pantalla de Login.
class BiometricLifecycleLock extends StatefulWidget {
  final Widget child;

  const BiometricLifecycleLock({super.key, required this.child});

  @override
  State<BiometricLifecycleLock> createState() => _BiometricLifecycleLockState();
}

class _BiometricLifecycleLockState extends State<BiometricLifecycleLock> {
  bool _isBlurred = false;

  @override
  void initState() {
    super.initState();
    SessionLifecycleManager.instance.init(
      onReauthenticateRequired: _handleReauthentication,
    );
  }

  Future<void> _handleReauthentication() async {
    final authCubit = context.read<AuthCubit>();
    final authState = authCubit.state;
    if (!authState.isAuthenticated) return;

    if (mounted) {
      setState(() => _isBlurred = true);
    }

    final success = await BiometricAuthService.instance.authenticate(
      localizedReason: 'Escanea tu huella dactilar para continuar en Cívica Pago',
    );

    if (!mounted) return;

    setState(() => _isBlurred = false);

    if (success) {
      SessionLifecycleManager.instance.recordUserActivity();
    } else {
      // Si canceló la huella o falló, redirige a LoginScreen
      authCubit.logout();
    }
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
          if (_isBlurred)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
