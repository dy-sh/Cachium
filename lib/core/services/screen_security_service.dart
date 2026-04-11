import 'dart:io';

import 'package:flutter/services.dart';

import '../utils/app_logger.dart';

const _log = AppLogger('ScreenSecurity');

/// Controls OS-level screen capture protection.
///
/// On Android this wires up FLAG_SECURE via a MethodChannel to [MainActivity].
/// iOS does not expose an equivalent per-activity flag — sensitive data
/// blurring on app-switcher snapshots has to be handled at the widget layer
/// instead, so this service is a no-op on iOS.
// TODO(ios): blur-overlay on app background for iOS screen-capture parity.
class ScreenSecurityService {
  static const _channel = MethodChannel('cachium/security');

  const ScreenSecurityService();

  Future<void> setSecure(bool enabled) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('setSecure', {'enabled': enabled});
    } on PlatformException catch (e) {
      _log.warning('setSecure($enabled) failed: ${e.message}');
    }
  }
}
