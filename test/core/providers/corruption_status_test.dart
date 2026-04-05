import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/core/providers/corruption_status_provider.dart';

void main() {
  group('CorruptionStatus.total', () {
    test('sums all entity counts', () {
      const status = CorruptionStatus(
        transactions: 1,
        accounts: 2,
        categories: 3,
        recurringRules: 4,
        savingsGoals: 5,
        assets: 6,
        templates: 7,
        bills: 8,
        tags: 9,
      );
      expect(status.total, 45);
    });

    test('returns 0 when all zero', () {
      const status = CorruptionStatus();
      expect(status.total, 0);
    });

    test('handles single non-zero field', () {
      const status = CorruptionStatus(transactions: 3);
      expect(status.total, 3);
    });
  });

  group('CorruptionStatus.hasCorruption', () {
    test('true when any count is non-zero', () {
      const status = CorruptionStatus(bills: 1);
      expect(status.hasCorruption, isTrue);
    });

    test('false when all zero', () {
      const status = CorruptionStatus();
      expect(status.hasCorruption, isFalse);
    });
  });
}
