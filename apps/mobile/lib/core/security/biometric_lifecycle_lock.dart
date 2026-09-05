import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/auth_cubit.dart';
import 'biometric_auth_service.dart';
import 'session_lifecycle_manager.dart';

/// Detector global de actividad e inactividad biométrica.
///
/// Si la sesión está activa y la biometría habilitada:
/// - Al ocurrir inactividad (>5 min) o retorno de segundo plano (>30 seg),
///   se activa directamente el diálogo nativo del sensor de huellas de Android
///   sobre la pantalla en la que el usuario estaba trabajando.
/// - Si el usuario verifica la huella, continúa en su pantalla sin interrupciones.
/// - Si cancela o falla, se redirige limpiamente a la pantalla de Login.
class BiometricLifecycleLock extends StatefulWidget {
  final Widget child;

  const BiometricLifecycleLock({super.key, required this.child});

  @override
  State<BiometricLifecycleLock> createState() => _BiometricLifecycleLockState();
}

class _BiometricLifecycleLockState extends State<BiometricLifecycleLock> {
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

    final success = await BiometricAuthService.instance.authenticate(
      localizedReason: 'Escanea tu huella dactilar para continuar en Cívica Pago',
    );

    if (!mounted) return;

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
      child: widget.child,
    );
  }
}
