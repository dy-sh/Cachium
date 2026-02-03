import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/streak.dart';

/// Calculates user streaks based on transaction history
final streaksProvider = Provider<List<Streak>>((ref) {
  final transactionsAsync = ref.watch(transactionsProvider);
  final transactions = transactionsAsync.valueOrNull;

  if (transactions == null || transactions.isEmpty) {
    return [];
  }

  final streaks = <Streak>[];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Group transactions by date
  final txByDate = <DateTime, List<Transaction>>{};
  for (final tx in transactions) {
    final dateKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
    txByDate.putIfAbsent(dateKey, () => []).add(tx);
  }

  // Calculate no-spend streak
  int currentNoSpend = 0;
  int bestNoSpend = 0;
  DateTime? noSpendStart;
  var date = today;
  bool noSpendActive = true;

  for (int i = 0; i < 365; i++) {
    final dayTx = txByDate[date] ?? [];
    final hasExpense = dayTx.any((tx) => tx.type == TransactionType.expense);

    if (!hasExpense && noSpendActive) {
      currentNoSpend++;
      noSpendStart ??= date;
    } else if (hasExpense) {
      if (noSpendActive && i == 0) {
        // Today has expense, streak is 0
        noSpendActive = false;
        currentNoSpend = 0;
      } else if (noSpendActive) {
        noSpendActive = false;
      }
      // Track for best
      if (currentNoSpend > bestNoSpend) {
        bestNoSpend = currentNoSpend;
      }
    }

    date = date.subtract(const Duration(days: 1));
  }

  if (currentNoSpend > bestNoSpend) {
    bestNoSpend = currentNoSpend;
  }

  streaks.add(Streak(
    type: StreakType.noSpend,
    currentCount: noSpendActive ? currentNoSpend : 0,
    bestCount: bestNoSpend,
    startDate: noSpendStart,
    isActive: noSpendActive,
  ));

  // Calculate under-budget streak (spending less than daily average)
  final expenses = transactions.where((tx) => tx.type == TransactionType.expense).toList();
  if (expenses.isNotEmpty) {
    final totalExpense = expenses.fold<double>(0, (sum, tx) => sum + tx.amount);
    final firstExpenseDate = expenses.map((tx) => tx.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final daysSinceFirst = now.difference(firstExpenseDate).inDays + 1;
    final dailyAverage = totalExpense / daysSinceFirst;

    int currentUnderBudget = 0;
    int bestUnderBudget = 0;
    bool underBudgetActive = true;
    date = today;

    for (int i = 0; i < 90; i++) {
      final dayTx = txByDate[date] ?? [];
      final dayExpense = dayTx
          .where((tx) => tx.type == TransactionType.expense)
          .fold<double>(0, (sum, tx) => sum + tx.amount);

      if (dayExpense < dailyAverage && underBudgetActive) {
        currentUnderBudget++;
      } else if (dayExpense >= dailyAverage) {
        if (underBudgetActive && i == 0) {
          underBudgetActive = false;
          currentUnderBudget = 0;
        } else if (underBudgetActive) {
          underBudgetActive = false;
        }
        if (currentUnderBudget > bestUnderBudget) {
          bestUnderBudget = currentUnderBudget;
        }
      }

      date = date.subtract(const Duration(days: 1));
    }

    if (currentUnderBudget > bestUnderBudget) {
      bestUnderBudget = currentUnderBudget;
    }

    streaks.add(Streak(
      type: StreakType.underBudget,
      currentCount: underBudgetActive ? currentUnderBudget : 0,
      bestCount: bestUnderBudget,
      isActive: underBudgetActive,
    ));
  }

  // Calculate daily logging streak
  int currentLogging = 0;
  int bestLogging = 0;
  bool loggingActive = true;
  date = today;

  for (int i = 0; i < 365; i++) {
    final dayTx = txByDate[date] ?? [];

    if (dayTx.isNotEmpty && loggingActive) {
      currentLogging++;
    } else if (dayTx.isEmpty) {
      if (loggingActive && i == 0) {
        loggingActive = false;
        currentLogging = 0;
      } else if (loggingActive) {
        loggingActive = false;
      }
      if (currentLogging > bestLogging) {
        bestLogging = currentLogging;
      }
    }

    date = date.subtract(const Duration(days: 1));
  }

  if (currentLogging > bestLogging) {
    bestLogging = currentLogging;
  }

  streaks.add(Streak(
    type: StreakType.dailyLogging,
    currentCount: loggingActive ? currentLogging : 0,
    bestCount: bestLogging,
    isActive: loggingActive,
  ));

  return streaks;
});
