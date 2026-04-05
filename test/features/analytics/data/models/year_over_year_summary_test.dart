import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/analytics/data/models/year_over_year_summary.dart';

void main() {
  group('YoYPeriodData', () {
    test('net = income - expense', () {
      const p = YoYPeriodData(
        periodIndex: 1,
        label: 'Jan',
        income: 5000,
        expense: 3000,
      );
      expect(p.net, 2000);
    });
  });

  group('YearOverYearSummary', () {
    test('totalIncome sums all periods', () {
      const summary = YearOverYearSummary(
        year: 2026,
        periods: [
          YoYPeriodData(periodIndex: 1, label: 'Jan', income: 1000, expense: 500),
          YoYPeriodData(periodIndex: 2, label: 'Feb', income: 2000, expense: 800),
          YoYPeriodData(periodIndex: 3, label: 'Mar', income: 1500, expense: 600),
        ],
      );
      expect(summary.totalIncome, 4500);
    });

    test('totalExpense sums all periods', () {
      const summary = YearOverYearSummary(
        year: 2026,
        periods: [
          YoYPeriodData(periodIndex: 1, label: 'Jan', income: 1000, expense: 500),
          YoYPeriodData(periodIndex: 2, label: 'Feb', income: 2000, expense: 800),
        ],
      );
      expect(summary.totalExpense, 1300);
    });

    test('totalNet = totalIncome - totalExpense', () {
      const summary = YearOverYearSummary(
        year: 2026,
        periods: [
          YoYPeriodData(periodIndex: 1, label: 'Jan', income: 3000, expense: 1000),
          YoYPeriodData(periodIndex: 2, label: 'Feb', income: 2000, expense: 1500),
        ],
      );
      expect(summary.totalNet, 2500);
    });

    test('empty periods return 0 totals', () {
      const summary = YearOverYearSummary(year: 2026, periods: []);
      expect(summary.totalIncome, 0);
      expect(summary.totalExpense, 0);
      expect(summary.totalNet, 0);
    });
  });
}
