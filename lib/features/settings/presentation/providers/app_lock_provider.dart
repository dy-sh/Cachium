import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// Service for managing biometric authentication.
class AppLockService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if the device supports biometric authentication.
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck || isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Get the list of available biometric types.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Authenticate using biometrics or device PIN.
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to access Cachium',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}

/// Provider for the app lock service.
final appLockServiceProvider = Provider<AppLockService>((ref) {
  return AppLockService();
});

/// Whether biometric auth is available on this device.
final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(appLockServiceProvider);
  return service.isBiometricAvailable();
});

/// Tracks whether the app is currently locked.
class AppLockStateNotifier extends Notifier<bool> {
  @override
  bool build() {
    return true; // Start locked if app lock is enabled
  }

  void lock() => state = true;
  void unlock() => state = false;
}

final appLockStateProvider =
    NotifierProvider<AppLockStateNotifier, bool>(AppLockStateNotifier.new);
