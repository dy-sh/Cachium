import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/budget.dart';
import '../../data/models/budget_progress.dart';

class BudgetsNotifier extends AsyncNotifier<List<Budget>> {
  @override
  Future<List<Budget>> build() async {
    final repo = ref.watch(budgetRepositoryProvider);
    return repo.getAllBudgets();
  }

  Future<void> addBudget(Budget budget) async {
    final previousState = state;
    try {
      final repo = ref.read(budgetRepositoryProvider);
      state = state.whenData((budgets) => [...budgets, budget]);
      await repo.createBudget(budget);
    } catch (e, st) {
      state = previousState;
      Error.throwWithStackTrace(
        e is AppException ? e : RepositoryException.create(entityType: 'Budget', cause: e),
        st,
      );
    }
  }

  Future<void> updateBudget(Budget budget) async {
    final previousState = state;
    try {
      final repo = ref.read(budgetRepositoryProvider);
      state = state.whenData(
        (budgets) => budgets.map((b) => b.id == budget.id ? budget : b).toList(),
      );
      await repo.updateBudget(budget);
    } catch (e, st) {
      state = previousState;
      Error.throwWithStackTrace(
        e is AppException ? e : RepositoryException.update(entityType: 'Budget', entityId: budget.id, cause: e),
        st,
      );
    }
  }

  Future<void> deleteBudget(String id) async {
    final previousState = state;
    try {
      final repo = ref.read(budgetRepositoryProvider);
      state = state.whenData(
        (budgets) => budgets.where((b) => b.id != id).toList(),
      );
      await repo.deleteBudget(id);
    } catch (e, st) {
      state = previousState;
      Error.throwWithStackTrace(
        e is AppException ? e : RepositoryException.delete(entityType: 'Budget', entityId: id, cause: e),
        st,
      );
    }
  }

  Future<void> refresh() async {
    try {
      final repo = ref.read(budgetRepositoryProvider);
      state = AsyncData(await repo.getAllBudgets());
    } catch (e, st) {
      state = AsyncError(
        e is AppException ? e : RepositoryException.fetch(entityType: 'Budget', cause: e),
        st,
      );
    }
  }
}

final budgetsProvider = AsyncNotifierProvider<BudgetsNotifier, List<Budget>>(() {
  return BudgetsNotifier();
});

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
    final remaining = budget.amount - spent;
    final percentage = budget.amount > 0 ? (spent / budget.amount * 100) : 0;

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
      isOverBudget: spent > budget.amount,
    );
  }).toList()
    ..sort((a, b) => b.percentage.compareTo(a.percentage));
});
