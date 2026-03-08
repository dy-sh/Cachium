import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database_providers.dart';

/// Aggregated corruption counts from all repositories.
class CorruptionStatus {
  final int transactions;
  final int accounts;
  final int categories;
  final int recurringRules;
  final int savingsGoals;
  final int assets;
  final int templates;

  const CorruptionStatus({
    this.transactions = 0,
    this.accounts = 0,
    this.categories = 0,
    this.recurringRules = 0,
    this.savingsGoals = 0,
    this.assets = 0,
    this.templates = 0,
  });

  int get total =>
      transactions +
      accounts +
      categories +
      recurringRules +
      savingsGoals +
      assets +
      templates;

  bool get hasCorruption => total > 0;
}

/// Provider that aggregates corruption counts from all repositories.
final corruptionStatusProvider = Provider<CorruptionStatus>((ref) {
  return CorruptionStatus(
    transactions: ref.watch(transactionRepositoryProvider).lastCorruptedCount,
    accounts: ref.watch(accountRepositoryProvider).lastCorruptedCount,
    categories: ref.watch(categoryRepositoryProvider).lastCorruptedCount,
    recurringRules:
        ref.watch(recurringRuleRepositoryProvider).lastCorruptedCount,
    savingsGoals: ref.watch(savingsGoalRepositoryProvider).lastCorruptedCount,
    assets: ref.watch(assetRepositoryProvider).lastCorruptedCount,
    templates:
        ref.watch(transactionTemplateRepositoryProvider).lastCorruptedCount,
  );
});
