import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/analytics/data/models/income_expense_summary.dart';

IncomeExpenseSummary _makeSummary({
  DateTime? periodStart,
  DateTime? periodEnd,
  double totalIncome = 0,
  double totalExpense = 0,
  int incomeCount = 0,
  int expenseCount = 0,
  double previousTotalIncome = 0,
  double previousTotalExpense = 0,
}) {
  return IncomeExpenseSummary(
    periodStart: periodStart ?? DateTime(2026, 1, 1),
    periodEnd: periodEnd ?? DateTime(2026, 1, 31),
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    incomeCount: incomeCount,
    expenseCount: expenseCount,
    previousTotalIncome: previousTotalIncome,
    previousTotalExpense: previousTotalExpense,
  );
}

void main() {
  group('IncomeExpenseSummary computed properties', () {
    test('netAmount = income - expense', () {
      final s = _makeSummary(totalIncome: 5000, totalExpense: 3000);
      expect(s.netAmount, 2000);
    });

    test('netAmount is negative when expenses exceed income', () {
      final s = _makeSummary(totalIncome: 1000, totalExpense: 3000);
      expect(s.netAmount, -2000);
    });

    test('totalCount sums income and expense counts', () {
      final s = _makeSummary(incomeCount: 3, expenseCount: 7);
      expect(s.totalCount, 10);
    });

    test('dayCount calculates difference', () {
      final s = _makeSummary(
        periodStart: DateTime(2026, 1, 1),
        periodEnd: DateTime(2026, 1, 31),
      );
      expect(s.dayCount, 30);
    });

    test('dayCount returns 1 for same-day period', () {
      final s = _makeSummary(
        periodStart: DateTime(2026, 3, 15),
        periodEnd: DateTime(2026, 3, 15),
      );
      expect(s.dayCount, 1);
    });
  });

  group('IncomeExpenseSummary daily averages', () {
    test('averageDailyExpense divides by dayCount', () {
      final s = _makeSummary(
        periodStart: DateTime(2026, 1, 1),
        periodEnd: DateTime(2026, 1, 11),
        totalExpense: 100,
      );
      expect(s.averageDailyExpense, 10.0);
    });

    test('averageDailyIncome divides by dayCount', () {
      final s = _makeSummary(
        periodStart: DateTime(2026, 1, 1),
        periodEnd: DateTime(2026, 1, 11),
        totalIncome: 300,
      );
      expect(s.averageDailyIncome, 30.0);
    });

    test('averageDailyNet = net / dayCount', () {
      final s = _makeSummary(
        periodStart: DateTime(2026, 1, 1),
        periodEnd: DateTime(2026, 1, 11),
        totalIncome: 300,
        totalExpense: 100,
      );
      expect(s.averageDailyNet, 20.0);
    });
  });

  group('IncomeExpenseSummary.savingsRate', () {
    test('calculates rate correctly', () {
      final s = _makeSummary(totalIncome: 5000, totalExpense: 4000);
      expect(s.savingsRate, 20.0);
    });

    test('returns 0 when income is 0', () {
      final s = _makeSummary(totalIncome: 0, totalExpense: 100);
      expect(s.savingsRate, 0);
    });

    test('clamps at -100 for extreme negative', () {
      final s = _makeSummary(totalIncome: 100, totalExpense: 10000);
      expect(s.savingsRate, -100);
    });

    test('clamps at 100 for extreme positive', () {
      // Can't realistically exceed 100% savings rate with positive expense,
      // but with zero expense it's 100%
      final s = _makeSummary(totalIncome: 5000, totalExpense: 0);
      expect(s.savingsRate, 100);
    });

    test('50% savings rate', () {
      final s = _makeSummary(totalIncome: 1000, totalExpense: 500);
      expect(s.savingsRate, 50.0);
    });
  });

  group('IncomeExpenseSummary change percentages', () {
    test('incomeChangePercent with previous data', () {
      final s = _makeSummary(
        totalIncome: 6000,
        previousTotalIncome: 5000,
      );
      expect(s.incomeChangePercent, 20.0);
    });

    test('incomeChangePercent returns 100 when previous is 0 and current > 0', () {
      final s = _makeSummary(totalIncome: 1000, previousTotalIncome: 0);
      expect(s.incomeChangePercent, 100);
    });

    test('incomeChangePercent returns 0 when both are 0', () {
      final s = _makeSummary(totalIncome: 0, previousTotalIncome: 0);
      expect(s.incomeChangePercent, 0);
    });

    test('expenseChangePercent with previous data', () {
      final s = _makeSummary(
        totalExpense: 3000,
        previousTotalExpense: 4000,
      );
      expect(s.expenseChangePercent, -25.0);
    });

    test('expenseChangePercent returns 100 when previous is 0 and current > 0', () {
      final s = _makeSummary(totalExpense: 500, previousTotalExpense: 0);
      expect(s.expenseChangePercent, 100);
    });

    test('netChangePercent with positive previous net', () {
      final s = _makeSummary(
        totalIncome: 6000,
        totalExpense: 3000,
        previousTotalIncome: 5000,
        previousTotalExpense: 3000,
      );
      // net = 3000, prevNet = 2000, change = (3000-2000)/2000*100 = 50%
      expect(s.netChangePercent, 50.0);
    });

    test('netChangePercent uses abs for negative previous net', () {
      final s = _makeSummary(
        totalIncome: 2000,
        totalExpense: 1000,
        previousTotalIncome: 1000,
        previousTotalExpense: 2000,
      );
      // net = 1000, prevNet = -1000, change = (1000 - (-1000)) / 1000 * 100 = 200%
      expect(s.netChangePercent, 200.0);
    });

    test('netChangePercent returns 100 when previous is 0 and current > 0', () {
      final s = _makeSummary(totalIncome: 1000, totalExpense: 0);
      expect(s.netChangePercent, 100);
    });

    test('netChangePercent returns -100 when previous is 0 and current < 0', () {
      final s = _makeSummary(totalIncome: 0, totalExpense: 1000);
      expect(s.netChangePercent, -100);
    });

    test('netChangePercent returns 0 when both are 0', () {
      final s = _makeSummary();
      expect(s.netChangePercent, 0);
    });
  });

  group('IncomeExpenseSummary.empty factory', () {
    test('creates summary with all zeros', () {
      final s = IncomeExpenseSummary.empty(
        periodStart: DateTime(2026, 1, 1),
        periodEnd: DateTime(2026, 1, 31),
      );
      expect(s.totalIncome, 0);
      expect(s.totalExpense, 0);
      expect(s.incomeCount, 0);
      expect(s.expenseCount, 0);
    });
  });

  group('PeriodSummary', () {
    test('net = income - expense', () {
      final s = PeriodSummary(
        periodStart: DateTime(2026, 1, 1),
        periodEnd: DateTime(2026, 1, 31),
        label: 'Jan',
        income: 5000,
        expense: 3000,
      );
      expect(s.net, 2000);
    });

    test('net is negative when expense > income', () {
      final s = PeriodSummary(
        periodStart: DateTime(2026, 1, 1),
        periodEnd: DateTime(2026, 1, 31),
        label: 'Jan',
        income: 1000,
        expense: 3000,
      );
      expect(s.net, -2000);
    });
  });
}
