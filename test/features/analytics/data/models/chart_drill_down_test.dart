import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/analytics/data/models/chart_drill_down.dart';

void main() {
  group('ChartDrillDown.toQueryParameters', () {
    test('returns empty map when all null', () {
      const dd = ChartDrillDown();
      expect(dd.toQueryParameters(), isEmpty);
    });

    test('includes categoryId', () {
      const dd = ChartDrillDown(categoryId: 'cat-1');
      final params = dd.toQueryParameters();
      expect(params['categoryId'], 'cat-1');
      expect(params.length, 1);
    });

    test('includes accountId', () {
      const dd = ChartDrillDown(accountId: 'acc-1');
      expect(dd.toQueryParameters()['accountId'], 'acc-1');
    });

    test('includes startDate as ISO8601', () {
      final date = DateTime(2026, 3, 15, 10, 30);
      final dd = ChartDrillDown(startDate: date);
      final params = dd.toQueryParameters();
      expect(params['startDate'], date.toIso8601String());
    });

    test('includes endDate as ISO8601', () {
      final date = DateTime(2026, 6, 30);
      final dd = ChartDrillDown(endDate: date);
      expect(dd.toQueryParameters()['endDate'], date.toIso8601String());
    });

    test('includes transactionType as type', () {
      const dd = ChartDrillDown(transactionType: 'expense');
      expect(dd.toQueryParameters()['type'], 'expense');
    });

    test('includes all fields when all set', () {
      final dd = ChartDrillDown(
        categoryId: 'cat-1',
        accountId: 'acc-1',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
        transactionType: 'income',
      );
      final params = dd.toQueryParameters();
      expect(params.length, 5);
      expect(params['categoryId'], 'cat-1');
      expect(params['accountId'], 'acc-1');
      expect(params['type'], 'income');
    });
  });
}
