import 'package:cachium/features/settings/presentation/providers/app_lock_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLockStateNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('starts locked', () {
      expect(container.read(appLockStateProvider), true);
    });

    test('unlock clears state and timestamp', () {
      final notifier = container.read(appLockStateProvider.notifier);
      notifier.unlock();
      expect(container.read(appLockStateProvider), false);
    });

    test('lock() clears timestamp so re-background starts fresh', () {
      final notifier = container.read(appLockStateProvider.notifier);
      notifier.unlock();
      notifier.onBackground();
      notifier.lock();
      expect(container.read(appLockStateProvider), true);
      // After an explicit lock, a subsequent foreground should not reuse the
      // old timestamp.
      notifier.unlock();
      notifier.onForeground(
        timeoutDuration: const Duration(minutes: 5),
        isImmediate: false,
        isNever: false,
      );
      expect(container.read(appLockStateProvider), false);
    });

    test('immediate timeout locks on foreground', () {
      final notifier = container.read(appLockStateProvider.notifier);
      notifier.unlock();
      notifier.onBackground();
      notifier.onForeground(
        timeoutDuration: Duration.zero,
        isImmediate: true,
        isNever: false,
      );
      expect(container.read(appLockStateProvider), true);
    });

    test('never timeout keeps unlocked on foreground', () {
      final notifier = container.read(appLockStateProvider.notifier);
      notifier.unlock();
      notifier.onBackground();
      notifier.onForeground(
        timeoutDuration: null,
        isImmediate: false,
        isNever: true,
      );
      expect(container.read(appLockStateProvider), false);
    });

    test('timeout not elapsed keeps unlocked', () {
      final notifier = container.read(appLockStateProvider.notifier);
      notifier.unlock();
      notifier.onBackground();
      // A long timeout with an immediate foreground should not trigger a lock.
      notifier.onForeground(
        timeoutDuration: const Duration(hours: 1),
        isImmediate: false,
        isNever: false,
      );
      expect(container.read(appLockStateProvider), false);
    });

    test('rapid background/foreground cycles preserve earliest timestamp',
        () async {
      final notifier = container.read(appLockStateProvider.notifier);
      notifier.unlock();
      notifier.onBackground();
      // Simulate elapsed time via a small real delay; we assert the timeout
      // logic with a very short duration to avoid slow tests.
      await Future<void>.delayed(const Duration(milliseconds: 60));
      // Second background call must NOT reset the timestamp.
      notifier.onBackground();
      notifier.onForeground(
        timeoutDuration: const Duration(milliseconds: 50),
        isImmediate: false,
        isNever: false,
      );
      expect(container.read(appLockStateProvider), true,
          reason:
              'earliest background timestamp must win so the timer still fires');
    });

    test('foreground while already locked clears timestamp', () {
      final notifier = container.read(appLockStateProvider.notifier);
      // Start locked (default), simulate background then foreground.
      notifier.onBackground();
      notifier.onForeground(
        timeoutDuration: const Duration(minutes: 5),
        isImmediate: false,
        isNever: false,
      );
      // Still locked; subsequent unlock should work normally.
      expect(container.read(appLockStateProvider), true);
      notifier.unlock();
      expect(container.read(appLockStateProvider), false);
    });
  });
}
