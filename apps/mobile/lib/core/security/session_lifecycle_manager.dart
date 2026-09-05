import 'dart:async';
import 'package:flutter/widgets.dart';
import 'biometric_auth_service.dart';

/// Gestor del ciclo de vida de la sesión (Inactividad y Segundo Plano).
///
/// Implementa el estándar de seguridad:
/// 1. Inactividad (5 minutos sin tocar la pantalla).
/// 2. Segundo plano (30 segundos de gracia al cambiar de app).
/// 3. Al cumplirse cualquiera, solicita autenticación directamente al sensor de Android
///    sobre la pantalla actual, o redirige a LoginScreen en caso de cancelación.
class SessionLifecycleManager with WidgetsBindingObserver {
  static final SessionLifecycleManager instance = SessionLifecycleManager._internal();

  SessionLifecycleManager._internal();

  static const Duration inactivityTimeout = Duration(minutes: 5);
  static const Duration backgroundGracePeriod = Duration(seconds: 30);

  DateTime? _pausedAt;
  Timer? _inactivityTimer;
  bool _isInitialized = false;
  bool _isAuthenticating = false;

  Future<void> Function()? onReauthenticateRequired;

  /// Inicializa el observador de ciclo de vida global
  void init({Future<void> Function()? onReauthenticateRequired}) {
    if (onReauthenticateRequired != null) {
      this.onReauthenticateRequired = onReauthenticateRequired;
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

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityTimeout, () async {
      final isBioEnabled = await BiometricAuthService.instance.isBiometricsEnabled();
      if (isBioEnabled) {
        debugPrint('[SessionLifecycleManager] Inactividad (5 min): solicitando huella');
        triggerReauthentication();
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
      debugPrint('[SessionLifecycleManager] Retorno de segundo plano ($secondsInBackground seg): solicitando huella');
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
          localizedReason: 'Escanea tu huella dactilar para continuar en Cívica Pago',
        );
        if (success) {
          recordUserActivity();
        }
      }
    } finally {
      _isAuthenticating = false;
    }
  }
}
