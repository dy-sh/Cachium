import 'dart:async';

/// Mixin for repositories that track corrupted record counts.
///
/// Provides a reactive [corruptionCountStream] that emits whenever
/// the corruption count changes, enabling the UI to reactively
/// display warnings about data integrity issues.
mixin CorruptionTracker {
  int _lastCorruptedCount = 0;
  int get lastCorruptedCount => _lastCorruptedCount;

  final _corruptionController = StreamController<int>.broadcast();
  Stream<int> get corruptionCountStream => _corruptionController.stream;

  void updateCorruptedCount(int count) {
    if (count != _lastCorruptedCount) {
      _lastCorruptedCount = count;
      _corruptionController.add(count);
    }
  }

  /// Closes the corruption stream controller.
  /// Call when the repository is being disposed.
  void disposeCorruptionTracker() {
    _corruptionController.close();
  }
}
