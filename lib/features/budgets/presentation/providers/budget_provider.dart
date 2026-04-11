import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/providers/optimistic_notifier.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/budget.dart';
import '../../data/models/budget_progress.dart';

class BudgetsNotifier extends AsyncNotifier<List<Budget>>
    with OptimisticAsyncNotifier<Budget> {
  @override
  Future<List<Budget>> build() async {
    final repo = ref.watch(budgetRepositoryProvider);
    return repo.getAllBudgets();
  }

  Future<void> addBudget(Budget budget) => runOptimistic(
        update: (budgets) => [...budgets, budget],
        action: () => ref.read(budgetRepositoryProvider).createBudget(budget),
        onError: (e) =>
            RepositoryException.create(entityType: 'Budget', cause: e),
      );

  Future<void> updateBudget(Budget budget) => runOptimistic(
        update: (budgets) =>
            budgets.map((b) => b.id == budget.id ? budget : b).toList(),
        action: () => ref.read(budgetRepositoryProvider).updateBudget(budget),
        onError: (e) => RepositoryException.update(
            entityType: 'Budget', entityId: budget.id, cause: e),
      );

  Future<void> deleteBudget(String id) => runOptimistic(
        update: (budgets) => budgets.where((b) => b.id != id).toList(),
        action: () => ref.read(budgetRepositoryProvider).deleteBudget(id),
        onError: (e) => RepositoryException.delete(
            entityType: 'Budget', entityId: id, cause: e),
      );

  Future<void> refresh() async {
    try {
      final repo = ref.read(budgetRepositoryProvider);
      state = AsyncData(await repo.getAllBudgets());
    } catch (e, st) {
      state = AsyncError(
        e is AppException
            ? e
            : RepositoryException.fetch(entityType: 'Budget', cause: e),
        st,
      );
    }
  }
}

final budgetsProvider = AsyncNotifierProvider<BudgetsNotifier, List<Budget>>(() {
  return BudgetsNotifier();
});

/// Calculate expenses for a given category in a given month from a list of transactions.
double _spentInMonth(List<Transaction> transactions, String categoryId, int year, int month) {
  final monthStart = DateTime(year, month, 1);
  final monthEnd = DateTime(year, month + 1, 0, 23, 59, 59);

  double total = 0;
  for (final tx in transactions) {
    if (tx.type == TransactionType.expense &&
        tx.categoryId == categoryId &&
        !tx.date.isBefore(monthStart) &&
        !tx.date.isAfter(monthEnd)) {
      total += tx.amount;
    }
  }
  return total;
}

/// Calculate cascading rollover for a budget.
/// Looks back up to 12 months. For each prior month, rollover = max(0, budget - spent) + prior rollover.
@visibleForTesting
double calculateRollover({
  required List<Budget> allBudgets,
  required List<Transaction> allTransactions,
  required String categoryId,
  required int year,
  required int month,
  int maxLookback = 12,
}) {
  double rollover = 0;

  int curYear = year;
  int curMonth = month;

  for (int i = 0; i < maxLookback; i++) {
    // Go to previous month
    curMonth--;
    if (curMonth < 1) {
      curMonth = 12;
      curYear--;
    }

    // Find budget for this category in the previous month
    final prevBudget = allBudgets.where(
      (b) => b.categoryId == categoryId && b.year == curYear && b.month == curMonth && b.rolloverEnabled,
    );

    if (prevBudget.isEmpty) break; // No rollover-enabled budget in prior month, stop cascading

    final budgetAmount = prevBudget.first.amount;
    final spent = _spentInMonth(allTransactions, categoryId, curYear, curMonth);
    // Clamp: no negative rollover from overspending
    final unused = (budgetAmount - spent).clamp(0.0, double.infinity);
    rollover += unused;
  }

  return rollover;
}

final budgetProgressProvider = Provider.family<List<BudgetProgress>, ({int year, int month})>((ref, params) {
  final budgetsAsync = ref.watch(budgetsProvider);
  final transactionsAsync = ref.watch(transactionsProvider);
  final categoriesAsync = ref.watch(categoriesProvider);
  final colorIntensity = ref.watch(colorIntensityProvider);

  final budgets = budgetsAsync.valueOrNull;
  final transactions = transactionsAsync.valueOrNull;
  final categories = categoriesAsync.valueOrNull;

  if (budgets == null || transactions == null || categories == null) return [];

  final monthBudgets = budgets.where(
    (b) => b.year == params.year && b.month == params.month,
  );

  final monthStart = DateTime(params.year, params.month, 1);
  final monthEnd = DateTime(params.year, params.month + 1, 0, 23, 59, 59);

  final monthExpenses = transactions.where((tx) =>
    tx.type == TransactionType.expense &&
    !tx.date.isBefore(monthStart) &&
    !tx.date.isAfter(monthEnd),
  );

  // Sum expenses per category
  final Map<String, double> spentByCategory = {};
  for (final tx in monthExpenses) {
    spentByCategory[tx.categoryId] =
        (spentByCategory[tx.categoryId] ?? 0) + tx.amount;
  }

  return monthBudgets.map((budget) {
    final spent = spentByCategory[budget.categoryId] ?? 0;

    // Calculate rollover if enabled
    final rolloverAmount = budget.rolloverEnabled
        ? calculateRollover(
            allBudgets: budgets,
            allTransactions: transactions,
            categoryId: budget.categoryId,
            year: params.year,
            month: params.month,
          )
        : 0.0;

    final effectiveBudget = budget.amount + rolloverAmount;
    final remaining = effectiveBudget - spent;
    final percentage = effectiveBudget > 0 ? (spent / effectiveBudget * 100) : 0;

    final category = categories.firstWhere(
      (c) => c.id == budget.categoryId,
      orElse: () => Category(
        id: budget.categoryId,
        name: 'Unknown',
        icon: Icons.category,
        colorIndex: 0,
        type: CategoryType.expense,
      ),
    );

    return BudgetProgress(
      budget: budget,
      categoryName: category.name,
      categoryIcon: category.icon,
      categoryColor: category.getColor(colorIntensity),
      spent: spent,
      remaining: remaining,
      percentage: percentage.toDouble(),
      isOverBudget: spent > effectiveBudget,
      rolloverAmount: rolloverAmount,
      effectiveBudget: effectiveBudget,
    );
  }).toList()
    ..sort((a, b) => b.percentage.compareTo(a.percentage));
});
