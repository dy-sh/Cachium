import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/analytics/data/models/what_if_result.dart';

void main() {
  group('WhatIfResult', () {
    test('netChange = projected - baseline', () {
      const r = WhatIfResult(
        baselineMonthlyNet: 1000,
        projectedMonthlyNet: 1500,
        baselineMonthlyExpense: 3000,
        projectedMonthlyExpense: 2500,
        baselineMonthlyIncome: 4000,
        categoryImpacts: [],
      );
      expect(r.netChange, 500);
    });

    test('netChange is negative when projected < baseline', () {
      const r = WhatIfResult(
        baselineMonthlyNet: 2000,
        projectedMonthlyNet: 1000,
        baselineMonthlyExpense: 3000,
        projectedMonthlyExpense: 4000,
        baselineMonthlyIncome: 5000,
        categoryImpacts: [],
      );
      expect(r.netChange, -1000);
    });

    test('netChangePercent calculates correctly', () {
      const r = WhatIfResult(
        baselineMonthlyNet: 1000,
        projectedMonthlyNet: 1500,
        baselineMonthlyExpense: 3000,
        projectedMonthlyExpense: 2500,
        baselineMonthlyIncome: 4000,
        categoryImpacts: [],
      );
      expect(r.netChangePercent, 50.0);
    });

    test('netChangePercent uses abs for negative baseline', () {
      const r = WhatIfResult(
        baselineMonthlyNet: -1000,
        projectedMonthlyNet: 500,
        baselineMonthlyExpense: 5000,
        projectedMonthlyExpense: 3500,
        baselineMonthlyIncome: 4000,
        categoryImpacts: [],
      );
      // netChange = 1500, abs(baseline) = 1000, percent = 150%
      expect(r.netChangePercent, 150.0);
    });

    test('netChangePercent returns 0 when baseline is 0', () {
      const r = WhatIfResult(
        baselineMonthlyNet: 0,
        projectedMonthlyNet: 500,
        baselineMonthlyExpense: 3000,
        projectedMonthlyExpense: 2500,
        baselineMonthlyIncome: 3000,
        categoryImpacts: [],
      );
      expect(r.netChangePercent, 0);
    });
  });

  group('WhatIfCategoryImpact', () {
    test('amountChange = adjusted - original', () {
      const impact = WhatIfCategoryImpact(
        categoryId: 'cat-1',
        categoryName: 'Food',
        originalAmount: 500,
        adjustedAmount: 400,
        percentChange: -20,
      );
      expect(impact.amountChange, -100);
    });

    test('amountChange is positive for increase', () {
      const impact = WhatIfCategoryImpact(
        categoryId: 'cat-1',
        categoryName: 'Food',
        originalAmount: 300,
        adjustedAmount: 450,
        percentChange: 50,
      );
      expect(impact.amountChange, 150);
    });
  });

  group('WhatIfAdjustment equality', () {
    test('equal by categoryId', () {
      const a = WhatIfAdjustment(
        categoryId: 'cat-1',
        categoryName: 'A',
        percentChange: 10,
      );
      const b = WhatIfAdjustment(
        categoryId: 'cat-1',
        categoryName: 'B',
        percentChange: 20,
      );
      expect(a, equals(b));
    });

    test('not equal with different categoryId', () {
      const a = WhatIfAdjustment(
        categoryId: 'cat-1',
        categoryName: 'A',
        percentChange: 10,
      );
      const b = WhatIfAdjustment(
        categoryId: 'cat-2',
        categoryName: 'A',
        percentChange: 10,
      );
      expect(a, isNot(equals(b)));
    });
  });
}
