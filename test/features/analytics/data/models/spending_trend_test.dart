import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/analytics/data/models/spending_trend.dart';

void main() {
  group('OverallTrend.hasData', () {
    test('true when currentIncome > 0', () {
      const trend = OverallTrend(
        currentIncome: 100,
        previousIncome: 0,
        currentExpense: 0,
        previousExpense: 0,
        incomeChangePercent: 0,
        expenseChangePercent: 0,
        topCategoryChanges: [],
      );
      expect(trend.hasData, isTrue);
    });

    test('true when currentExpense > 0', () {
      const trend = OverallTrend(
        currentIncome: 0,
        previousIncome: 0,
        currentExpense: 50,
        previousExpense: 0,
        incomeChangePercent: 0,
        expenseChangePercent: 0,
        topCategoryChanges: [],
      );
      expect(trend.hasData, isTrue);
    });

    test('true when previousIncome > 0', () {
      const trend = OverallTrend(
        currentIncome: 0,
        previousIncome: 200,
        currentExpense: 0,
        previousExpense: 0,
        incomeChangePercent: 0,
        expenseChangePercent: 0,
        topCategoryChanges: [],
      );
      expect(trend.hasData, isTrue);
    });

    test('true when previousExpense > 0', () {
      const trend = OverallTrend(
        currentIncome: 0,
        previousIncome: 0,
        currentExpense: 0,
        previousExpense: 75,
        incomeChangePercent: 0,
        expenseChangePercent: 0,
        topCategoryChanges: [],
      );
      expect(trend.hasData, isTrue);
    });

    test('false when all values are 0', () {
      const trend = OverallTrend(
        currentIncome: 0,
        previousIncome: 0,
        currentExpense: 0,
        previousExpense: 0,
        incomeChangePercent: 0,
        expenseChangePercent: 0,
        topCategoryChanges: [],
      );
      expect(trend.hasData, isFalse);
    });
  });
}
