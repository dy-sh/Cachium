import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/budgets/data/models/budget.dart';
import 'package:cachium/features/budgets/data/models/budget_progress.dart';
import 'package:cachium/features/budgets/presentation/providers/budget_provider.dart';
import 'package:cachium/features/transactions/data/models/transaction.dart';

const _categoryId = 'cat-food';
const _otherCategoryId = 'cat-other';
final _createdAt = DateTime(2024, 1, 1);

Budget _budget({
  required int year,
  required int month,
  double amount = 100.0,
  bool rolloverEnabled = true,
  String categoryId = _categoryId,
}) {
  return Budget(
    id: 'budget-$categoryId-$year-$month',
    categoryId: categoryId,
    amount: amount,
    year: year,
    month: month,
    rolloverEnabled: rolloverEnabled,
    createdAt: _createdAt,
  );
}

Transaction _expense({
  required int year,
  required int month,
  required double amount,
  String categoryId = _categoryId,
  int day = 15,
  String id = 'tx',
}) {
  return Transaction(
    id: '$id-$year-$month-$day',
    amount: amount,
    type: TransactionType.expense,
    categoryId: categoryId,
    accountId: 'acc-1',
    date: DateTime(year, month, day),
    createdAt: _createdAt,
  );
}

void main() {
  group('calculateRollover', () {
    test('returns 0 when there is no prior month budget', () {
      final result = calculateRollover(
        allBudgets: [_budget(year: 2024, month: 5)],
        allTransactions: const [],
        categoryId: _categoryId,
        year: 2024,
        month: 5,
      );
      expect(result, 0);
    });

    test('one prior month underspent by 50 → rollover is 50', () {
      final budgets = [
        _budget(year: 2024, month: 4, amount: 100),
        _budget(year: 2024, month: 5, amount: 100),
      ];
      final txs = [_expense(year: 2024, month: 4, amount: 50)];

      final result = calculateRollover(
        allBudgets: budgets,
        allTransactions: txs,
        categoryId: _categoryId,
        year: 2024,
        month: 5,
      );
      expect(result, 50);
    });

    test('overspending in prior month is clamped to 0', () {
      final budgets = [
        _budget(year: 2024, month: 4, amount: 100),
        _budget(year: 2024, month: 5, amount: 100),
      ];
      final txs = [_expense(year: 2024, month: 4, amount: 130)];

      final result = calculateRollover(
        allBudgets: budgets,
        allTransactions: txs,
        categoryId: _categoryId,
        year: 2024,
        month: 5,
      );
      expect(result, 0);
    });

    test('three prior months mixed: only underspent months contribute', () {
      final budgets = [
        _budget(year: 2024, month: 2, amount: 100),
        _budget(year: 2024, month: 3, amount: 100),
        _budget(year: 2024, month: 4, amount: 100),
        _budget(year: 2024, month: 5, amount: 100),
      ];
      final txs = [
        _expense(year: 2024, month: 2, amount: 60, id: 'a'), // unused 40
        _expense(year: 2024, month: 3, amount: 150, id: 'b'), // overspent → 0
        _expense(year: 2024, month: 4, amount: 25, id: 'c'), // unused 75
      ];

      final result = calculateRollover(
        allBudgets: budgets,
        allTransactions: txs,
        categoryId: _categoryId,
        year: 2024,
        month: 5,
      );
      expect(result, 115);
    });

    test('twelve consecutive prior months underspent → all twelve sum', () {
      final budgets = <Budget>[
        for (int m = 1; m <= 12; m++)
          _budget(year: 2023, month: m, amount: 100),
        _budget(year: 2024, month: 1, amount: 100),
      ];
      final txs = <Transaction>[
        for (int m = 1; m <= 12; m++)
          _expense(year: 2023, month: m, amount: 90, id: 'm$m'),
      ];

      final result = calculateRollover(
        allBudgets: budgets,
        allTransactions: txs,
        categoryId: _categoryId,
        year: 2024,
        month: 1,
      );
      expect(result, 12 * 10);
    });

    test('lookback stops at maxLookback months even if more exist', () {
      // 13 prior months underspent, but only 12 should count.
      final budgets = <Budget>[
        for (int m = 1; m <= 12; m++)
          _budget(year: 2023, month: m, amount: 100),
        _budget(year: 2024, month: 1, amount: 100), // 13th prior month
        _budget(year: 2024, month: 2, amount: 100), // current month
      ];
      final txs = <Transaction>[
        for (int m = 1; m <= 12; m++)
          _expense(year: 2023, month: m, amount: 90, id: 'a$m'),
        _expense(year: 2024, month: 1, amount: 90, id: 'b1'),
      ];

      final result = calculateRollover(
        allBudgets: budgets,
        allTransactions: txs,
        categoryId: _categoryId,
        year: 2024,
        month: 2,
      );
      // Expect 12 months × 10 unused = 120 (not 130)
      expect(result, 120);
    });

    test('lookback breaks at first month without rollover-enabled budget', () {
      // Months back: 4 (enabled), 3 (disabled), 2 (enabled). Should stop at 3.
      final budgets = [
        _budget(year: 2024, month: 2, amount: 100),
        _budget(year: 2024, month: 3, amount: 100, rolloverEnabled: false),
        _budget(year: 2024, month: 4, amount: 100),
        _budget(year: 2024, month: 5, amount: 100),
      ];
      final txs = [
        _expense(year: 2024, month: 2, amount: 50, id: 'a'),
        _expense(year: 2024, month: 3, amount: 50, id: 'b'),
        _expense(year: 2024, month: 4, amount: 50, id: 'c'),
      ];

      final result = calculateRollover(
        allBudgets: budgets,
        allTransactions: txs,
        categoryId: _categoryId,
        year: 2024,
        month: 5,
      );
      // Only month 4 contributes (50). Month 3 disabled stops cascade.
      expect(result, 50);
    });

    test('year wrap: month=1 looks back to December of previous year', () {
      final budgets = [
        _budget(year: 2023, month: 12, amount: 100),
        _budget(year: 2024, month: 1, amount: 100),
      ];
      final txs = [_expense(year: 2023, month: 12, amount: 30)];

      final result = calculateRollover(
        allBudgets: budgets,
        allTransactions: txs,
        categoryId: _categoryId,
        year: 2024,
        month: 1,
      );
      expect(result, 70);
    });

    test('budgets for other categories in prior months do not leak', () {
      final budgets = [
        _budget(year: 2024, month: 4, amount: 100),
        _budget(
            year: 2024,
            month: 4,
            amount: 500,
            categoryId: _otherCategoryId),
        _budget(year: 2024, month: 5, amount: 100),
      ];
      final txs = [
        _expense(year: 2024, month: 4, amount: 80, id: 'a'),
        _expense(
            year: 2024,
            month: 4,
            amount: 10,
            categoryId: _otherCategoryId,
            id: 'b'),
      ];

      final result = calculateRollover(
        allBudgets: budgets,
        allTransactions: txs,
        categoryId: _categoryId,
        year: 2024,
        month: 5,
      );
      // Only category food: 100 - 80 = 20
      expect(result, 20);
    });

    test('transactions from other categories are excluded from spent', () {
      final budgets = [
        _budget(year: 2024, month: 4, amount: 100),
        _budget(year: 2024, month: 5, amount: 100),
      ];
      final txs = [
        _expense(year: 2024, month: 4, amount: 30, id: 'a'),
        _expense(
            year: 2024,
            month: 4,
            amount: 1000,
            categoryId: _otherCategoryId,
            id: 'b'),
      ];

      final result = calculateRollover(
        allBudgets: budgets,
        allTransactions: txs,
        categoryId: _categoryId,
        year: 2024,
        month: 5,
      );
      expect(result, 70);
    });

    test('income transactions are excluded from spent', () {
      final budgets = [
        _budget(year: 2024, month: 4, amount: 100),
        _budget(year: 2024, month: 5, amount: 100),
      ];
      final txs = [
        _expense(year: 2024, month: 4, amount: 30, id: 'a'),
        Transaction(
          id: 'income-1',
          amount: 500,
          type: TransactionType.income,
          categoryId: _categoryId,
          accountId: 'acc-1',
          date: DateTime(2024, 4, 10),
          createdAt: _createdAt,
        ),
      ];

      final result = calculateRollover(
        allBudgets: budgets,
        allTransactions: txs,
        categoryId: _categoryId,
        year: 2024,
        month: 5,
      );
      expect(result, 70);
    });

    test('transactions outside the prior month window are excluded', () {
      // Transaction on the last second of March should not count toward April.
      final budgets = [
        _budget(year: 2024, month: 4, amount: 100),
        _budget(year: 2024, month: 5, amount: 100),
      ];
      final txs = [
        Transaction(
          id: 'tx-late-march',
          amount: 90,
          type: TransactionType.expense,
          categoryId: _categoryId,
          accountId: 'acc-1',
          date: DateTime(2024, 3, 31, 23, 59, 59),
          createdAt: _createdAt,
        ),
      ];

      final result = calculateRollover(
        allBudgets: budgets,
        allTransactions: txs,
        categoryId: _categoryId,
        year: 2024,
        month: 5,
      );
      // April had no spending → 100 unused. March is outside lookback chain
      // (no April budget transaction), so only April's full 100 cascades.
      expect(result, 100);
    });
  });

  group('BudgetProgress effective budget math', () {
    test('effectiveBudget = amount + rollover; remaining and percentage follow',
        () {
      final budget = _budget(year: 2024, month: 5, amount: 200);
      const spent = 50.0;
      const rollover = 100.0;
      final effective = budget.amount + rollover;

      final progress = BudgetProgress(
        budget: budget,
        categoryName: 'Food',
        categoryIcon: Icons.restaurant,
        categoryColor: const Color(0xFF000000),
        spent: spent,
        remaining: effective - spent,
        percentage: spent / effective * 100,
        isOverBudget: spent > effective,
        rolloverAmount: rollover,
        effectiveBudget: effective,
      );

      expect(progress.effectiveBudget, 300);
      expect(progress.remaining, 250);
      expect(progress.percentage, closeTo(16.666, 0.01));
      expect(progress.isOverBudget, isFalse);
    });

    test('isOverBudget is true when spent exceeds effective budget', () {
      final budget = _budget(year: 2024, month: 5, amount: 100);
      const spent = 150.0;
      const rollover = 30.0;
      final effective = budget.amount + rollover;

      final progress = BudgetProgress(
        budget: budget,
        categoryName: 'Food',
        categoryIcon: Icons.restaurant,
        categoryColor: const Color(0xFF000000),
        spent: spent,
        remaining: effective - spent,
        percentage: spent / effective * 100,
        isOverBudget: spent > effective,
        rolloverAmount: rollover,
        effectiveBudget: effective,
      );

      expect(progress.effectiveBudget, 130);
      expect(progress.remaining, -20);
      expect(progress.isOverBudget, isTrue);
      expect(progress.percentage, closeTo(115.384, 0.01));
    });

    test('rollover lifts a would-be-overspent budget back into safety', () {
      final budget = _budget(year: 2024, month: 5, amount: 100);
      const spent = 120.0;
      const rollover = 50.0;
      final effective = budget.amount + rollover; // 150

      final progress = BudgetProgress(
        budget: budget,
        categoryName: 'Food',
        categoryIcon: Icons.restaurant,
        categoryColor: const Color(0xFF000000),
        spent: spent,
        remaining: effective - spent,
        percentage: spent / effective * 100,
        isOverBudget: spent > effective,
        rolloverAmount: rollover,
        effectiveBudget: effective,
      );

      expect(progress.isOverBudget, isFalse);
      expect(progress.remaining, 30);
    });
  });
}
