import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/analytics/data/models/streak.dart';

void main() {
  group('StreakType extensions', () {
    test('displayName returns correct values', () {
      expect(StreakType.noSpend.displayName, 'No-Spend Days');
      expect(StreakType.underBudget.displayName, 'Under Budget');
      expect(StreakType.savings.displayName, 'Saving Streak');
      expect(StreakType.dailyLogging.displayName, 'Daily Logging');
    });

    test('description returns non-empty strings', () {
      for (final type in StreakType.values) {
        expect(type.description, isNotEmpty);
      }
    });
  });

  group('Streak.progress', () {
    test('calculates ratio correctly', () {
      const s = Streak(
        type: StreakType.noSpend,
        currentCount: 5,
        bestCount: 10,
      );
      expect(s.progress, 0.5);
    });

    test('returns 0 when bestCount is 0', () {
      const s = Streak(
        type: StreakType.noSpend,
        currentCount: 5,
        bestCount: 0,
      );
      expect(s.progress, 0);
    });

    test('returns 1.0 when current equals best', () {
      const s = Streak(
        type: StreakType.savings,
        currentCount: 7,
        bestCount: 7,
      );
      expect(s.progress, 1.0);
    });

    test('can exceed 1.0 when current > best', () {
      const s = Streak(
        type: StreakType.dailyLogging,
        currentCount: 15,
        bestCount: 10,
      );
      expect(s.progress, 1.5);
    });
  });
}
