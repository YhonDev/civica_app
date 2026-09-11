import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Monitorea la conectividad de red y expone un stream con cambios.
///
/// Uso:
/// ```dart
/// final detector = ConnectivityDetector();
/// detector.onStatusChanged.listen((online) => print(online));
/// print(detector.isOnline); // status actual
/// ```
class ConnectivityDetector {
  static ConnectivityDetector? _instance;

  final Connectivity _connectivity = Connectivity();

  final _statusController = StreamController<bool>.broadcast();

  /// Stream que emite `true` cuando hay conexión, `false` cuando se pierde.
  Stream<bool> get onStatusChanged => _statusController.stream;

  bool _isOnline = true; // asume online hasta que se pruebe lo contrario

  /// Estado actual de conectividad.
  bool get isOnline => _isOnline;

  ConnectivityDetector._() {
    _init();
  }

  /// Inicializa la instancia singleton y comienza a escuchar cambios.
  static ConnectivityDetector init() {
    _instance ??= ConnectivityDetector._();
    return _instance!;
  }

  /// Acceso a la instancia singleton.
  static ConnectivityDetector get instance {
    if (_instance == null) {
      throw StateError(
        'ConnectivityDetector no inicializado. Llama init() primero.',
      );
    }
    return _instance!;
  }

  /// Retorna el estado de conectividad actual de forma segura.
  /// Si el detector no ha sido inicializado (ej: tests o web), asume online.
  static bool get isCurrentOnline => _instance?.isOnline ?? true;

  Future<void> _init() async {
    try {
      // Verificar estado inicial
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);

      // Escuchar cambios
      _connectivity.onConnectivityChanged.listen(_updateStatus);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ConnectivityDetector] Error al inicializar: $e');
      }
      // Si falla, asumimos online para no bloquear la app
      _isOnline = true;
    }
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online != _isOnline) {
      _isOnline = online;
      _statusController.add(online);
      debugPrint('[ConnectivityDetector] Estado cambiado: ${online ? "ONLINE" : "OFFLINE"}');
    } else {
      _isOnline = online;
    }
  }

  /// Libera recursos.
  void dispose() {
    _statusController.close();
    _instance = null;
  }
}
