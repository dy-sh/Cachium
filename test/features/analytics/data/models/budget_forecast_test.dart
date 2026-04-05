import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:cachium/features/analytics/data/models/budget_forecast.dart';

BudgetForecast _makeForecast({
  double currentSpending = 0,
  double projectedSpending = 0,
  double budgetAmount = 1000,
  double overage = 0,
  double dailyRate = 0,
  int daysRemaining = 0,
}) {
  return BudgetForecast(
    categoryId: 'cat-1',
    categoryName: 'Test',
    categoryColor: Colors.blue,
    currentSpending: currentSpending,
    projectedSpending: projectedSpending,
    budgetAmount: budgetAmount,
    overage: overage,
    dailyRate: dailyRate,
    daysRemaining: daysRemaining,
  );
}

void main() {
  group('BudgetForecast.overagePercent', () {
    test('calculates percentage correctly', () {
      final f = _makeForecast(overage: 200, budgetAmount: 1000);
      expect(f.overagePercent, 20.0);
    });

    test('returns 0 when budgetAmount is 0', () {
      final f = _makeForecast(overage: 100, budgetAmount: 0);
      expect(f.overagePercent, 0);
    });

    test('handles large overage', () {
      final f = _makeForecast(overage: 2000, budgetAmount: 1000);
      expect(f.overagePercent, 200.0);
    });

    test('handles zero overage', () {
      final f = _makeForecast(overage: 0, budgetAmount: 1000);
      expect(f.overagePercent, 0);
    });
  });

  group('BudgetForecast.isOverBudget', () {
    test('true when overage > 0', () {
      final f = _makeForecast(overage: 100);
      expect(f.isOverBudget, isTrue);
    });

    test('false when overage is 0', () {
      final f = _makeForecast(overage: 0);
      expect(f.isOverBudget, isFalse);
    });

    test('false when overage is negative', () {
      final f = _makeForecast(overage: -50);
      expect(f.isOverBudget, isFalse);
    });
  });

  group('BudgetForecast equality', () {
    test('forecasts with same categoryId are equal', () {
      final f1 = _makeForecast(currentSpending: 100);
      final f2 = _makeForecast(currentSpending: 200);
      expect(f1, equals(f2));
    });
  });
}
