import 'package:flutter/foundation.dart';

/// Lightweight structured logger with tag prefix and log levels.
///
/// All output is guarded by [kDebugMode] so nothing leaks in release builds.
/// Usage:
/// ```dart
/// static const _log = AppLogger('MyService');
/// _log.debug('loaded 42 items');
/// _log.warning('rate unavailable, using cached');
/// _log.error('save failed', e);
/// ```
class AppLogger {
  final String tag;

  const AppLogger(this.tag);

  void debug(String msg) {
    if (kDebugMode) debugPrint('[$tag] $msg');
  }

  void warning(String msg) {
    if (kDebugMode) debugPrint('[$tag] WARNING: $msg');
  }

  void error(String msg, [Object? error]) {
    if (kDebugMode) {
      debugPrint('[$tag] ERROR: $msg${error != null ? ' ($error)' : ''}');
    }
  }
}
