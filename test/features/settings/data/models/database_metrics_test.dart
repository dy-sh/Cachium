import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/settings/data/models/database_metrics.dart';

void main() {
  group('DatabaseMetrics.totalRecords', () {
    test('sums all entity counts', () {
      const m = DatabaseMetrics(
        transactionCount: 10,
        categoryCount: 5,
        accountCount: 3,
        budgetCount: 2,
        assetCount: 4,
        recurringRuleCount: 1,
        savingsGoalCount: 2,
        templateCount: 3,
      );
      expect(m.totalRecords, 30);
    });

    test('returns 0 when all zero', () {
      const m = DatabaseMetrics(
        transactionCount: 0,
        categoryCount: 0,
        accountCount: 0,
      );
      expect(m.totalRecords, 0);
    });

    test('handles defaults for optional counts', () {
      const m = DatabaseMetrics(
        transactionCount: 10,
        categoryCount: 5,
        accountCount: 3,
      );
      // budgetCount, assetCount, etc. default to 0
      expect(m.totalRecords, 18);
    });
  });

  group('DatabaseMetrics.isEmpty', () {
    test('true when totalRecords is 0', () {
      const m = DatabaseMetrics(
        transactionCount: 0,
        categoryCount: 0,
        accountCount: 0,
      );
      expect(m.isEmpty, isTrue);
    });

    test('false when any count is non-zero', () {
      const m = DatabaseMetrics(
        transactionCount: 1,
        categoryCount: 0,
        accountCount: 0,
      );
      expect(m.isEmpty, isFalse);
    });
  });
}
