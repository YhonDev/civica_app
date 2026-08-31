import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enterprise Biometric Authentication Service (Fingerprint & Face ID).
class BiometricAuthService {
  static final BiometricAuthService instance = BiometricAuthService._internal();

  BiometricAuthService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  static const String _biometricEnabledKey = 'civica_biometrics_enabled';

  /// Checks if device supports biometric hardware authentication
  Future<bool> isHardwareSupported() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Returns available biometric types (e.g. fingerprint, face)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return [];
    }
  }

  /// Checks if user has enabled biometric login preference
  Future<bool> isBiometricsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  /// Sets user biometric login preference
  Future<void> setBiometricsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  /// Triggers native Android/iOS biometric authentication prompt
  Future<bool> authenticate({String? localizedReason}) async {
    try {
      final isSupported = await isHardwareSupported();
      if (!isSupported) return false;

      return await _auth.authenticate(
        localizedReason: localizedReason ?? 'Escanea tu huella dactilar o rostro para acceder a Cívica Pago',
      );
    } on PlatformException catch (_) {
      return false;
    }
  }
}
