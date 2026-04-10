import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/utils/app_logger.dart';

const _log = AppLogger('AppLock');

/// Service for managing biometric authentication.
class AppLockService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if the device supports biometric authentication.
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck || isDeviceSupported;
    } catch (e) {
      _log.debug('Biometric availability check failed: $e');
      return false;
    }
  }

  /// Get the list of available biometric types.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      _log.debug('getAvailableBiometrics failed: $e');
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
    } catch (e) {
      _log.warning('Biometric authentication failed: $e');
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

/// Tracks whether the app is currently locked, with auto-lock timeout support.
class AppLockStateNotifier extends Notifier<bool> {
  DateTime? _backgroundedAt;

  @override
  bool build() {
    return true; // Start locked if app lock is enabled
  }

  void lock() => state = true;
  void unlock() {
    _backgroundedAt = null;
    state = false;
  }

  /// Called when the app goes to background.
  void onBackground() {
    _backgroundedAt = DateTime.now();
  }

  /// Called when the app comes to foreground.
  /// Returns whether the app should be locked based on the configured timeout.
  void onForeground({required Duration? timeoutDuration, required bool isImmediate, required bool isNever}) {
    if (state) return; // Already locked

    if (isImmediate) {
      lock();
      return;
    }

    if (isNever) {
      // Don't auto-lock on foreground
      _backgroundedAt = null;
      return;
    }

    if (_backgroundedAt != null && timeoutDuration != null) {
      final elapsed = DateTime.now().difference(_backgroundedAt!);
      if (elapsed >= timeoutDuration) {
        lock();
      }
    }
    _backgroundedAt = null;
  }
}

final appLockStateProvider =
    NotifierProvider<AppLockStateNotifier, bool>(AppLockStateNotifier.new);
