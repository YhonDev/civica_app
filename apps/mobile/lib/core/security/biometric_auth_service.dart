import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enterprise Biometric Authentication Service (Fingerprint & Face ID).
class BiometricAuthService {
  static final BiometricAuthService instance = BiometricAuthService._internal();

  BiometricAuthService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _biometricEnabledKey = 'civica_biometrics_enabled';
  static const String _rememberUsernameKey = 'civica_remember_username';
  static const String _savedUsernameKey = 'civica_saved_username';
  static const String _bioUsernameKey = 'civica_bio_user';
  static const String _bioPasswordKey = 'civica_bio_password';

  /// Checks if device supports biometric hardware authentication
  Future<bool> isHardwareSupported() async {
    if (kIsWeb) return false;
    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!isMobile) return false;

    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException catch (e) {
      debugPrint('BiometricAuthService isHardwareSupported error: $e');
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Returns available biometric types (e.g. fingerprint, face)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('BiometricAuthService getAvailableBiometrics error: $e');
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
    if (!enabled) {
      await clearBiometricCredentials();
    }
  }

  /// Saves encrypted credentials for fast biometric re-login
  Future<void> saveBiometricCredentials(String username, String password) async {
    await _secureStorage.write(key: _bioUsernameKey, value: username);
    await _secureStorage.write(key: _bioPasswordKey, value: password);
  }

  /// Retrieves encrypted credentials for fast biometric re-login
  Future<Map<String, String>?> getBiometricCredentials() async {
    final user = await _secureStorage.read(key: _bioUsernameKey);
    final pass = await _secureStorage.read(key: _bioPasswordKey);
    if (user != null && pass != null && user.isNotEmpty && pass.isNotEmpty) {
      return {'username': user, 'password': pass};
    }
    return null;
  }

  /// Clears stored biometric credentials
  Future<void> clearBiometricCredentials() async {
    await _secureStorage.delete(key: _bioUsernameKey);
    await _secureStorage.delete(key: _bioPasswordKey);
  }

  /// Checks if "Recordar usuario" is active
  Future<bool> isRememberUsernameEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberUsernameKey) ?? false;
  }

  /// Gets the remembered username if enabled
  Future<String?> getRememberedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final isRemembered = prefs.getBool(_rememberUsernameKey) ?? false;
    if (isRemembered) {
      return prefs.getString(_savedUsernameKey);
    }
    return null;
  }

  /// Sets or clears remembered username
  Future<void> setRememberUsername({required bool remember, String? username}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberUsernameKey, remember);
    if (remember && username != null && username.isNotEmpty) {
      await prefs.setString(_savedUsernameKey, username);
    } else if (!remember) {
      await prefs.remove(_savedUsernameKey);
    }
  }

  /// Triggers native Android/iOS biometric authentication prompt
  Future<bool> authenticate({String? localizedReason}) async {
    try {
      final isSupported = await isHardwareSupported();
      if (!isSupported) {
        debugPrint('BiometricAuthService: Hardware or biometrics not supported on device');
        return false;
      }

      return await _auth.authenticate(
        localizedReason: localizedReason ?? 'Escanea tu huella dactilar para acceder a Cívica Pago',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (e) {
      if (e.code == LocalAuthExceptionCode.userCanceled || e.code.name == 'userCanceled') {
        debugPrint('BiometricAuthService: Autenticación cancelada por el usuario');
      } else {
        debugPrint('BiometricAuthService LocalAuthException: [${e.code}] ${e.description}');
      }
      return false;
    } on PlatformException catch (e) {
      debugPrint('BiometricAuthService authenticate PlatformException: [${e.code}] ${e.message}');
      return false;
    } catch (e) {
      debugPrint('BiometricAuthService authenticate unexpected error: $e');
      return false;
    }
  }
}



