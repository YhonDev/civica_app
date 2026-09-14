import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter/widgets.dart';
import 'biometric_auth_service.dart';

/// Gestor del ciclo de vida de la sesión (Inactividad y Segundo Plano).
///
/// Implementa el estándar de seguridad y rendimiento de Cuentiva:
/// 1. Inactividad (3 minutos sin actividad táctil):
///    - Cierra la aplicación limpiamente con `SystemNavigator.pop()` para evitar
///      consumo innecesario de batería y recursos en segundo plano.
///    - Mantiene intactos los tokens de autenticación y la configuración biométrica.
/// 2. Segundo plano:
///    - Periodo de gracia de 30 segundos (ej. cambiar a otra app brevemente).
///    - Al retornar tras el periodo de gracia, solicita verificación biométrica.
///    - Si el usuario cancela o falla, cierra la aplicación limpiamente sin destruir la sesión.
class SessionLifecycleManager with WidgetsBindingObserver {
  static final SessionLifecycleManager instance = SessionLifecycleManager._internal();

  SessionLifecycleManager._internal();

  static const Duration inactivityTimeout = Duration(minutes: 3);
  static const Duration backgroundGracePeriod = Duration(seconds: 30);

  DateTime? _pausedAt;
  Timer? _inactivityTimer;
  bool _isInitialized = false;
  bool _isAuthenticating = false;

  Future<void> Function()? onReauthenticateRequired;
  Future<void> Function()? onCloseApp;

  /// Inicializa el observador de ciclo de vida global
  void init({
    Future<void> Function()? onReauthenticateRequired,
    Future<void> Function()? onCloseApp,
  }) {
    if (onReauthenticateRequired != null) {
      this.onReauthenticateRequired = onReauthenticateRequired;
    }
    if (onCloseApp != null) {
      this.onCloseApp = onCloseApp;
    }
    if (_isInitialized) return;
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
    _resetInactivityTimer();
  }

  /// Limpia recursos
  void dispose() {
    _inactivityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
  }

  /// Registra actividad táctil del usuario (llamado por el Listener global)
  void recordUserActivity() {
    _resetInactivityTimer();
  }

  /// Cierra la aplicación limpiamente a nivel del sistema operativo.
  Future<void> closeApp() async {
    _inactivityTimer?.cancel();
    if (onCloseApp != null) {
      await onCloseApp!();
    } else {
      await SystemNavigator.pop();
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityTimeout, () async {
      final isBioEnabled = await BiometricAuthService.instance.isBiometricsEnabled();
      if (kDebugMode) {
        debugPrint('[SessionLifecycleManager] Inactividad (3 min): cerrando app limpiamente');
      }
      if (isBioEnabled) {
        await closeApp();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
      _inactivityTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _handleAppResume();
    }
  }

  Future<void> _handleAppResume() async {
    final pausedTime = _pausedAt;
    _pausedAt = null;

    if (pausedTime == null) return;

    final secondsInBackground = DateTime.now().difference(pausedTime).inSeconds;
    final isBioEnabled = await BiometricAuthService.instance.isBiometricsEnabled();

    if (isBioEnabled && secondsInBackground >= backgroundGracePeriod.inSeconds) {
      if (kDebugMode) {
        debugPrint('[SessionLifecycleManager] Retorno de segundo plano ($secondsInBackground seg): solicitando huella');
      }
      triggerReauthentication();
    } else {
      recordUserActivity();
    }
  }

  Future<void> triggerReauthentication() async {
    if (_isAuthenticating) return;
    _isAuthenticating = true;

    try {
      if (onReauthenticateRequired != null) {
        await onReauthenticateRequired!();
      } else {
        final success = await BiometricAuthService.instance.authenticate(
          localizedReason: 'Escanea tu huella dactilar para continuar en Cuentiva',
        );
        if (success) {
          recordUserActivity();
        } else {
          await closeApp();
        }
      }
    } finally {
      _isAuthenticating = false;
    }
  }
}
