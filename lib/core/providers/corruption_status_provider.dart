import 'dart:async';

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
  final int bills;
  final int tags;

  const CorruptionStatus({
    this.transactions = 0,
    this.accounts = 0,
    this.categories = 0,
    this.recurringRules = 0,
    this.savingsGoals = 0,
    this.assets = 0,
    this.templates = 0,
    this.bills = 0,
    this.tags = 0,
  });

  int get total =>
      transactions +
      accounts +
      categories +
      recurringRules +
      savingsGoals +
      assets +
      templates +
      bills +
      tags;

  bool get hasCorruption => total > 0;
}

/// Reactive provider that aggregates corruption counts from all repositories.
///
/// Listens to each repository's corruption stream so the UI updates
/// whenever new corruption is detected (not just on first load).
/// Events are debounced by 100ms to avoid rapid rebuilds during startup
/// when multiple repositories report corruption counts simultaneously.
final corruptionStatusProvider = StreamProvider<CorruptionStatus>((ref) {
  final repos = [
    ref.watch(transactionRepositoryProvider),
    ref.watch(accountRepositoryProvider),
    ref.watch(categoryRepositoryProvider),
    ref.watch(recurringRuleRepositoryProvider),
    ref.watch(savingsGoalRepositoryProvider),
    ref.watch(assetRepositoryProvider),
    ref.watch(transactionTemplateRepositoryProvider),
    ref.watch(billRepositoryProvider),
    ref.watch(tagRepositoryProvider),
  ];

  // Build initial status from current counts
  CorruptionStatus buildStatus() => CorruptionStatus(
        transactions: repos[0].lastCorruptedCount,
        accounts: repos[1].lastCorruptedCount,
        categories: repos[2].lastCorruptedCount,
        recurringRules: repos[3].lastCorruptedCount,
        savingsGoals: repos[4].lastCorruptedCount,
        assets: repos[5].lastCorruptedCount,
        templates: repos[6].lastCorruptedCount,
        bills: repos[7].lastCorruptedCount,
        tags: repos[8].lastCorruptedCount,
      );

  // Merge all corruption streams into one, rebuilding status on any change
  final controller = StreamController<CorruptionStatus>();
  Timer? debounceTimer;

  final subscriptions = <StreamSubscription<int>>[];
  for (final repo in repos) {
    subscriptions.add(repo.corruptionCountStream.listen((_) {
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 100), () {
        controller.add(buildStatus());
      });
    }));
  }

  // Emit initial status
  controller.add(buildStatus());

  ref.onDispose(() {
    debounceTimer?.cancel();
    for (final sub in subscriptions) {
      sub.cancel();
    }
    controller.close();
  });

  return controller.stream;
});
