import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/analytics/data/models/analytics_filter.dart';
import 'package:cachium/features/analytics/data/models/date_range_preset.dart';
import 'package:cachium/features/transactions/data/models/transaction.dart';

void main() {
  group('AnalyticsTypeFilter.matches', () {
    test('all matches everything', () {
      expect(AnalyticsTypeFilter.all.matches(TransactionType.income), isTrue);
      expect(AnalyticsTypeFilter.all.matches(TransactionType.expense), isTrue);
      expect(AnalyticsTypeFilter.all.matches(TransactionType.transfer), isTrue);
    });

    test('income matches only income', () {
      expect(AnalyticsTypeFilter.income.matches(TransactionType.income), isTrue);
      expect(AnalyticsTypeFilter.income.matches(TransactionType.expense), isFalse);
      expect(AnalyticsTypeFilter.income.matches(TransactionType.transfer), isFalse);
    });

    test('expense matches only expense', () {
      expect(AnalyticsTypeFilter.expense.matches(TransactionType.expense), isTrue);
      expect(AnalyticsTypeFilter.expense.matches(TransactionType.income), isFalse);
      expect(AnalyticsTypeFilter.expense.matches(TransactionType.transfer), isFalse);
    });
  });

  group('AnalyticsTypeFilter.displayName', () {
    test('returns correct names', () {
      expect(AnalyticsTypeFilter.all.displayName, 'All');
      expect(AnalyticsTypeFilter.income.displayName, 'Income');
      expect(AnalyticsTypeFilter.expense.displayName, 'Expense');
    });
  });

  group('AnalyticsFilter', () {
    test('hasAccountFilter true when accounts selected', () {
      final filter = AnalyticsFilter(
        dateRange: DateRange(
          start: DateTime(2026, 1, 1),
          end: DateTime(2026, 1, 31),
        ),
        selectedAccountIds: const {'acc-1'},
      );
      expect(filter.hasAccountFilter, isTrue);
    });

    test('hasAccountFilter false when empty', () {
      final filter = AnalyticsFilter(
        dateRange: DateRange(
          start: DateTime(2026, 1, 1),
          end: DateTime(2026, 1, 31),
        ),
      );
      expect(filter.hasAccountFilter, isFalse);
    });

    test('hasCategoryFilter true when categories selected', () {
      final filter = AnalyticsFilter(
        dateRange: DateRange(
          start: DateTime(2026, 1, 1),
          end: DateTime(2026, 1, 31),
        ),
        selectedCategoryIds: const {'cat-1'},
      );
      expect(filter.hasCategoryFilter, isTrue);
    });

    test('hasCategoryFilter false when empty', () {
      final filter = AnalyticsFilter(
        dateRange: DateRange(
          start: DateTime(2026, 1, 1),
          end: DateTime(2026, 1, 31),
        ),
      );
      expect(filter.hasCategoryFilter, isFalse);
    });
  });

  group('AnalyticsFilter equality', () {
    test('equal filters are equal', () {
      final range = DateRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31),
      );
      final a = AnalyticsFilter(
        dateRange: range,
        selectedAccountIds: const {'acc-1', 'acc-2'},
      );
      final b = AnalyticsFilter(
        dateRange: range,
        selectedAccountIds: const {'acc-2', 'acc-1'},
      );
      expect(a, equals(b));
    });

    test('different account sets are not equal', () {
      final range = DateRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31),
      );
      final a = AnalyticsFilter(
        dateRange: range,
        selectedAccountIds: const {'acc-1'},
      );
      final b = AnalyticsFilter(
        dateRange: range,
        selectedAccountIds: const {'acc-2'},
      );
      expect(a, isNot(equals(b)));
    });

    test('different type filters are not equal', () {
      final range = DateRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 1, 31),
      );
      final a = AnalyticsFilter(
        dateRange: range,
        typeFilter: AnalyticsTypeFilter.income,
      );
      final b = AnalyticsFilter(
        dateRange: range,
        typeFilter: AnalyticsTypeFilter.expense,
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('AnalyticsFilter.initial', () {
    test('uses last30Days preset', () {
      final filter = AnalyticsFilter.initial();
      expect(filter.preset, DateRangePreset.last30Days);
      expect(filter.typeFilter, AnalyticsTypeFilter.all);
      expect(filter.selectedAccountIds, isEmpty);
      expect(filter.selectedCategoryIds, isEmpty);
    });
  });
}
