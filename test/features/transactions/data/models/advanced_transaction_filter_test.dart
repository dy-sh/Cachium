import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/transactions/data/models/advanced_transaction_filter.dart';

void main() {
  group('AdvancedTransactionFilter.isActive', () {
    test('false when all defaults', () {
      const filter = AdvancedTransactionFilter();
      expect(filter.isActive, isFalse);
    });

    test('true when minAmount is set', () {
      const filter = AdvancedTransactionFilter(minAmount: 10.0);
      expect(filter.isActive, isTrue);
    });

    test('true when maxAmount is set', () {
      const filter = AdvancedTransactionFilter(maxAmount: 100.0);
      expect(filter.isActive, isTrue);
    });

    test('true when startDate is set', () {
      final filter = AdvancedTransactionFilter(
        startDate: DateTime(2026, 1, 1),
      );
      expect(filter.isActive, isTrue);
    });

    test('true when endDate is set', () {
      final filter = AdvancedTransactionFilter(
        endDate: DateTime(2026, 12, 31),
      );
      expect(filter.isActive, isTrue);
    });

    test('true when selectedCategoryIds is non-empty', () {
      const filter = AdvancedTransactionFilter(
        selectedCategoryIds: {'cat-1'},
      );
      expect(filter.isActive, isTrue);
    });

    test('true when selectedAccountIds is non-empty', () {
      const filter = AdvancedTransactionFilter(
        selectedAccountIds: {'acc-1'},
      );
      expect(filter.isActive, isTrue);
    });
  });

  group('AdvancedTransactionFilter.activeFilterCount', () {
    test('0 when all defaults', () {
      const filter = AdvancedTransactionFilter();
      expect(filter.activeFilterCount, 0);
    });

    test('1 for amount filters only (min or max counts as 1)', () {
      const filter = AdvancedTransactionFilter(minAmount: 10.0);
      expect(filter.activeFilterCount, 1);
    });

    test('1 for both min and max amount', () {
      const filter = AdvancedTransactionFilter(
        minAmount: 10.0,
        maxAmount: 100.0,
      );
      expect(filter.activeFilterCount, 1);
    });

    test('1 for date filters only', () {
      final filter = AdvancedTransactionFilter(
        startDate: DateTime(2026, 1, 1),
      );
      expect(filter.activeFilterCount, 1);
    });

    test('1 for both start and end date', () {
      final filter = AdvancedTransactionFilter(
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
      );
      expect(filter.activeFilterCount, 1);
    });

    test('1 for category filter only', () {
      const filter = AdvancedTransactionFilter(
        selectedCategoryIds: {'cat-1', 'cat-2'},
      );
      expect(filter.activeFilterCount, 1);
    });

    test('1 for account filter only', () {
      const filter = AdvancedTransactionFilter(
        selectedAccountIds: {'acc-1'},
      );
      expect(filter.activeFilterCount, 1);
    });

    test('4 when all filter types are set', () {
      final filter = AdvancedTransactionFilter(
        minAmount: 10.0,
        startDate: DateTime(2026, 1, 1),
        selectedCategoryIds: const {'cat-1'},
        selectedAccountIds: const {'acc-1'},
      );
      expect(filter.activeFilterCount, 4);
    });

    test('2 for amount and category filters', () {
      const filter = AdvancedTransactionFilter(
        maxAmount: 500.0,
        selectedCategoryIds: {'cat-1'},
      );
      expect(filter.activeFilterCount, 2);
    });
  });

  group('AdvancedTransactionFilter.copyWith', () {
    test('updates specified fields', () {
      const filter = AdvancedTransactionFilter();
      final copy = filter.copyWith(minAmount: 50.0, maxAmount: 200.0);
      expect(copy.minAmount, 50.0);
      expect(copy.maxAmount, 200.0);
    });

    test('clearMinAmount sets to null', () {
      const filter = AdvancedTransactionFilter(minAmount: 50.0);
      final copy = filter.copyWith(clearMinAmount: true);
      expect(copy.minAmount, isNull);
    });

    test('clearMaxAmount sets to null', () {
      const filter = AdvancedTransactionFilter(maxAmount: 200.0);
      final copy = filter.copyWith(clearMaxAmount: true);
      expect(copy.maxAmount, isNull);
    });

    test('clearStartDate sets to null', () {
      final filter = AdvancedTransactionFilter(
        startDate: DateTime(2026, 1, 1),
      );
      final copy = filter.copyWith(clearStartDate: true);
      expect(copy.startDate, isNull);
    });

    test('clearEndDate sets to null', () {
      final filter = AdvancedTransactionFilter(
        endDate: DateTime(2026, 12, 31),
      );
      final copy = filter.copyWith(clearEndDate: true);
      expect(copy.endDate, isNull);
    });

    test('preserves unmodified fields', () {
      const filter = AdvancedTransactionFilter(
        minAmount: 10.0,
        selectedCategoryIds: {'cat-1'},
      );
      final copy = filter.copyWith(maxAmount: 500.0);
      expect(copy.minAmount, 10.0);
      expect(copy.selectedCategoryIds, {'cat-1'});
      expect(copy.maxAmount, 500.0);
    });
  });
}
