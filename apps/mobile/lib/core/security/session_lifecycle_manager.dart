import 'dart:async';
import 'package:flutter/widgets.dart';
import 'biometric_auth_service.dart';

/// Gestor del ciclo de vida de la sesión (Inactividad y Segundo Plano).
///
/// Implementa el estándar bancario:
/// 1. Timeout de inactividad (5 minutos sin tocar la pantalla).
/// 2. Timeout de segundo plano (30 segundos de gracia al cambiar de app).
/// 3. Bloqueo no destructivo: la sesión en el servidor se mantiene viva,
///    pero la interfaz se bloquea localmente hasta autenticar con huella o clave.
class SessionLifecycleManager with WidgetsBindingObserver {
  static final SessionLifecycleManager instance = SessionLifecycleManager._internal();

  SessionLifecycleManager._internal();

  // Notificador de estado de bloqueo (escuchado por el widget de overlay)
  final ValueNotifier<bool> isLockedNotifier = ValueNotifier<bool>(false);

  // Configuración de tiempos (grado bancario)
  static const Duration inactivityTimeout = Duration(minutes: 5);
  static const Duration backgroundGracePeriod = Duration(seconds: 30);

  DateTime? _pausedAt;
  Timer? _inactivityTimer;
  bool _isInitialized = false;

  /// Inicializa el observador de ciclo de vida global
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
    _resetInactivityTimer();

    // En Cold Start: si la biometría está habilitada, la interfaz arranca protegida
    final isBioEnabled = await BiometricAuthService.instance.isBiometricsEnabled();
    if (isBioEnabled) {
      debugPrint('[SessionLifecycleManager] Cold start con biometría activa: bloqueando interfaz');
      lock();
    }
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
    if (isLockedNotifier.value) return;

    _inactivityTimer = Timer(inactivityTimeout, () async {
      final isBioEnabled = await BiometricAuthService.instance.isBiometricsEnabled();
      if (isBioEnabled && !isLockedNotifier.value) {
        debugPrint('[SessionLifecycleManager] Sesión bloqueada por inactividad (5 min)');
        lock();
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
      debugPrint('[SessionLifecycleManager] Sesión bloqueada por segundo plano ($secondsInBackground seg)');
      lock();
    } else {
      recordUserActivity();
    }
  }

  /// Bloquea la interfaz de la aplicación
  void lock() {
    if (!isLockedNotifier.value) {
      isLockedNotifier.value = true;
      _inactivityTimer?.cancel();
    }
  }

  /// Desbloquea la interfaz tras autenticación exitosa
  void unlock() {
    if (isLockedNotifier.value) {
      isLockedNotifier.value = false;
      recordUserActivity();
    }
  }
}
