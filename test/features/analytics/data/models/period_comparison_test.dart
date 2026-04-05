import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/analytics/data/models/period_comparison.dart';

void main() {
  group('PeriodMetrics', () {
    test('net = income - expense', () {
      const m = PeriodMetrics(
        label: 'Jan',
        income: 5000,
        expense: 3000,
        transactionCount: 10,
      );
      expect(m.net, 2000);
    });

    test('net is negative when expense > income', () {
      const m = PeriodMetrics(
        label: 'Feb',
        income: 1000,
        expense: 4000,
        transactionCount: 5,
      );
      expect(m.net, -3000);
    });
  });

  group('CategoryComparisonItem.changePercent', () {
    test('calculates positive change', () {
      const item = CategoryComparisonItem(
        categoryId: 'cat-1',
        name: 'Food',
        amountA: 100,
        amountB: 150,
      );
      expect(item.changePercent, 50.0);
    });

    test('calculates negative change', () {
      const item = CategoryComparisonItem(
        categoryId: 'cat-1',
        name: 'Food',
        amountA: 200,
        amountB: 100,
      );
      expect(item.changePercent, -50.0);
    });

    test('returns 100 when amountA is 0 and amountB > 0', () {
      const item = CategoryComparisonItem(
        categoryId: 'cat-1',
        name: 'New',
        amountA: 0,
        amountB: 500,
      );
      expect(item.changePercent, 100);
    });

    test('returns 0 when both amounts are 0', () {
      const item = CategoryComparisonItem(
        categoryId: 'cat-1',
        name: 'Empty',
        amountA: 0,
        amountB: 0,
      );
      expect(item.changePercent, 0);
    });

    test('returns 0 when no change', () {
      const item = CategoryComparisonItem(
        categoryId: 'cat-1',
        name: 'Stable',
        amountA: 100,
        amountB: 100,
      );
      expect(item.changePercent, 0);
    });
  });

  group('PeriodComparisonData.isEmpty', () {
    test('true when both periods have 0 transactions', () {
      const data = PeriodComparisonData(
        periodA: PeriodMetrics(
          label: 'A',
          income: 0,
          expense: 0,
          transactionCount: 0,
        ),
        periodB: PeriodMetrics(
          label: 'B',
          income: 0,
          expense: 0,
          transactionCount: 0,
        ),
        categoryComparison: [],
      );
      expect(data.isEmpty, isTrue);
    });

    test('false when periodA has transactions', () {
      const data = PeriodComparisonData(
        periodA: PeriodMetrics(
          label: 'A',
          income: 100,
          expense: 50,
          transactionCount: 3,
        ),
        periodB: PeriodMetrics(
          label: 'B',
          income: 0,
          expense: 0,
          transactionCount: 0,
        ),
        categoryComparison: [],
      );
      expect(data.isEmpty, isFalse);
    });
  });
}
