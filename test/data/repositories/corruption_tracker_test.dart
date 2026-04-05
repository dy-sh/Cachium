import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/data/repositories/corruption_tracker.dart';

class TestTracker with CorruptionTracker {}

void main() {
  group('CorruptionTracker', () {
    late TestTracker tracker;

    setUp(() {
      tracker = TestTracker();
    });

    tearDown(() {
      tracker.disposeCorruptionTracker();
    });

    test('initial count is 0', () {
      expect(tracker.lastCorruptedCount, 0);
    });

    test('updateCorruptedCount updates lastCorruptedCount', () {
      tracker.updateCorruptedCount(5);
      expect(tracker.lastCorruptedCount, 5);
    });

    test('emits on stream when count changes', () async {
      final future = tracker.corruptionCountStream.first;
      tracker.updateCorruptedCount(3);
      expect(await future, 3);
    });

    test('does not emit when count is the same', () async {
      tracker.updateCorruptedCount(5);

      // Listen for any new emissions
      var emitted = false;
      final sub = tracker.corruptionCountStream.listen((_) {
        emitted = true;
      });

      // Set same count again
      tracker.updateCorruptedCount(5);

      // Give stream a chance to emit
      await Future.delayed(Duration.zero);
      expect(emitted, isFalse);

      await sub.cancel();
    });

    test('emits multiple times for different counts', () async {
      final counts = <int>[];
      final sub = tracker.corruptionCountStream.listen(counts.add);

      tracker.updateCorruptedCount(1);
      tracker.updateCorruptedCount(3);
      tracker.updateCorruptedCount(0);

      await Future.delayed(Duration.zero);
      expect(counts, [1, 3, 0]);

      await sub.cancel();
    });

    test('broadcast stream supports multiple listeners', () async {
      final countsA = <int>[];
      final countsB = <int>[];
      final subA = tracker.corruptionCountStream.listen(countsA.add);
      final subB = tracker.corruptionCountStream.listen(countsB.add);

      tracker.updateCorruptedCount(2);
      await Future.delayed(Duration.zero);

      expect(countsA, [2]);
      expect(countsB, [2]);

      await subA.cancel();
      await subB.cancel();
    });
  });
}
