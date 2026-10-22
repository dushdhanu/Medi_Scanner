import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static const String _prefKeyBiometricEnabled = 'mediscan_biometric_lock_enabled';
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check if the device hardware supports biometric authentication
  static Future<bool> isBiometricsSupported() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Check if the user has enabled biometric lock in app settings
  static Future<bool> isLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyBiometricEnabled) ?? false;
  }

  /// Toggle biometric lock preference
  static Future<void> setLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyBiometricEnabled, enabled);
  }

  /// Prompt fingerprint / face unlock authentication
  static Future<bool> authenticate({String? localizedReason}) async {
    try {
      final isSupported = await isBiometricsSupported();
      if (!isSupported) return true; // If device has no biometric hardware, don't block user

      return await _auth.authenticate(
        localizedReason: localizedReason ?? 'Scan your fingerprint or face to unlock your Medicine Cabinet',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException catch (_) {
      return false;
    }
  }
}
