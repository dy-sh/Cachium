import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/providers/exchange_rate_provider.dart';
import '../../../../core/providers/optimistic_notifier.dart';
import '../../../../core/utils/currency_conversion.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart' show mainCurrencyCodeProvider;
import '../../data/models/recurring_rule.dart';
import '../../data/models/transaction.dart';
import 'transactions_provider.dart';

class RecurringRulesNotifier extends AsyncNotifier<List<RecurringRule>>
    with OptimisticAsyncNotifier<RecurringRule> {
  @override
  Future<List<RecurringRule>> build() async {
    final repository = ref.watch(recurringRuleRepositoryProvider);
    return repository.getAllRules();
  }

  Future<void> addRule(RecurringRule rule) => runOptimistic(
        update: (rules) => [...rules, rule],
        action: () =>
            ref.read(recurringRuleRepositoryProvider).createRule(rule),
        onError: (e) =>
            RepositoryException.create(entityType: 'RecurringRule', cause: e),
      );

  Future<void> updateRule(RecurringRule rule) => runOptimistic(
        update: (rules) =>
            rules.map((r) => r.id == rule.id ? rule : r).toList(),
        action: () =>
            ref.read(recurringRuleRepositoryProvider).updateRule(rule),
        onError: (e) => RepositoryException.update(
            entityType: 'RecurringRule', entityId: rule.id, cause: e),
      );

  Future<void> deleteRule(String id) => runOptimistic(
        update: (rules) => rules.where((r) => r.id != id).toList(),
        action: () =>
            ref.read(recurringRuleRepositoryProvider).deleteRule(id),
        onError: (e) => RepositoryException.delete(
            entityType: 'RecurringRule', entityId: id, cause: e),
      );

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

      // Validate that referenced entities still exist
      final accountExists = ref.read(accountByIdProvider(rule.accountId)) != null;
      final categoryExists = ref.read(categoryByIdProvider(rule.categoryId)) != null;
      final destAccountValid = rule.type != TransactionType.transfer ||
          rule.destinationAccountId == null ||
          ref.read(accountByIdProvider(rule.destinationAccountId!)) != null;

      if (!accountExists || !categoryExists || !destAccountValid) {
        // Deactivate rules with invalid references
        await repository.updateRule(rule.copyWith(isActive: false));
        continue;
      }

      var lastGenerated = rule.lastGeneratedDate;
      var nextDate = rule.frequency.nextDate(lastGenerated);
      final now = DateTime.now();

      while (!nextDate.isAfter(now)) {
        // Check if we've passed the end date
        if (rule.endDate != null && nextDate.isAfter(rule.endDate!)) break;

        // Compute currency fields
        final mainCurrency = ref.read(mainCurrencyCodeProvider);
        final rates = ref.read(exchangeRatesProvider).valueOrNull ?? {};
        double conversionRate = 1.0;
        if (rule.currencyCode != mainCurrency) {
          final fromRate = rates[rule.currencyCode];
          if (fromRate != null && fromRate > 0) {
            conversionRate = 1.0 / fromRate;
          }
        }
        final mainCurrencyAmount = rule.currencyCode == mainCurrency
            ? rule.amount
            : roundCurrency(rule.amount * conversionRate);

        // Create the transaction
        await transactionsNotifier.addTransaction(
          amount: rule.amount,
          type: rule.type,
          categoryId: rule.categoryId,
          accountId: rule.accountId,
          destinationAccountId: rule.destinationAccountId,
          currencyCode: rule.currencyCode,
          conversionRate: conversionRate,
          destinationAmount: rule.destinationAmount,
          mainCurrencyCode: mainCurrency,
          mainCurrencyAmount: mainCurrencyAmount,
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
