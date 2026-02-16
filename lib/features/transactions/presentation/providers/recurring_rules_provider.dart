import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_providers.dart';
import '../../data/models/recurring_rule.dart';
import 'transactions_provider.dart';

class RecurringRulesNotifier extends AsyncNotifier<List<RecurringRule>> {
  @override
  Future<List<RecurringRule>> build() async {
    final repository = ref.watch(recurringRuleRepositoryProvider);
    return repository.getAllRules();
  }

  Future<void> addRule(RecurringRule rule) async {
    final repository = ref.read(recurringRuleRepositoryProvider);
    await repository.createRule(rule);
    ref.invalidateSelf();
  }

  Future<void> updateRule(RecurringRule rule) async {
    final repository = ref.read(recurringRuleRepositoryProvider);
    await repository.updateRule(rule);
    ref.invalidateSelf();
  }

  Future<void> deleteRule(String id) async {
    final repository = ref.read(recurringRuleRepositoryProvider);
    await repository.deleteRule(id);
    ref.invalidateSelf();
  }

  Future<void> toggleActive(String id) async {
    final rules = state.valueOrNull ?? [];
    final rule = rules.firstWhere((r) => r.id == id);
    await updateRule(rule.copyWith(isActive: !rule.isActive));
  }

  /// Generate pending transactions for active recurring rules.
  /// When [ruleIds] is provided, only generate for those specific rules.
  /// When null, generate for all active rules.
  Future<int> generatePendingTransactions({List<String>? ruleIds}) async {
    final rules = state.valueOrNull ?? [];
    final transactionsNotifier = ref.read(transactionsProvider.notifier);
    final repository = ref.read(recurringRuleRepositoryProvider);
    var count = 0;

    for (final rule in rules) {
      if (!rule.isActive) continue;
      if (ruleIds != null && !ruleIds.contains(rule.id)) continue;

      var lastGenerated = rule.lastGeneratedDate;
      var nextDate = rule.frequency.nextDate(lastGenerated);
      final now = DateTime.now();

      while (!nextDate.isAfter(now)) {
        // Check if we've passed the end date
        if (rule.endDate != null && nextDate.isAfter(rule.endDate!)) break;

        // Create the transaction
        await transactionsNotifier.addTransaction(
          amount: rule.amount,
          type: rule.type,
          categoryId: rule.categoryId,
          accountId: rule.accountId,
          destinationAccountId: rule.destinationAccountId,
          date: nextDate,
          note: rule.note,
          merchant: rule.merchant,
        );
        count++;
        lastGenerated = nextDate;
        nextDate = rule.frequency.nextDate(lastGenerated);
      }

      // Update lastGeneratedDate if we generated any
      if (lastGenerated != rule.lastGeneratedDate) {
        await repository.updateRule(
          rule.copyWith(lastGeneratedDate: lastGenerated),
        );
      }
    }

    if (count > 0) {
      ref.invalidateSelf();
    }

    return count;
  }
}

final recurringRulesProvider =
    AsyncNotifierProvider<RecurringRulesNotifier, List<RecurringRule>>(
  RecurringRulesNotifier.new,
);

/// Provider that returns the count of active recurring rules.
final activeRecurringRulesCountProvider = Provider<int>((ref) {
  final rules = ref.watch(recurringRulesProvider).valueOrNull ?? [];
  return rules.where((r) => r.isActive).length;
});
