import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/search_result.dart';

final globalSearchQueryProvider = StateProvider<String>((ref) => '');

final globalSearchResultsProvider =
    Provider<List<GlobalSearchResult>>((ref) {
  final query = ref.watch(globalSearchQueryProvider).trim().toLowerCase();
  if (query.isEmpty) return [];

  final intensity = ref.watch(colorIntensityProvider);
  final transactions =
      ref.watch(transactionsProvider).valueOrNull ?? [];
  final accounts =
      ref.watch(accountsProvider).valueOrNull ?? [];
  final categories =
      ref.watch(categoriesProvider).valueOrNull ?? [];

  final results = <GlobalSearchResult>[];

  // Search accounts
  for (final account in accounts) {
    if (account.name.toLowerCase().contains(query)) {
      results.add(GlobalSearchResult(
        id: account.id,
        title: account.name,
        subtitle: '${account.type.displayName} \u2022 ${CurrencyFormatter.format(account.balance)}',
        type: SearchResultType.account,
        icon: account.icon,
        color: account.getColorWithIntensity(intensity),
        route: '/account/${account.id}',
      ));
    }
  }

  // Search categories
  for (final category in categories) {
    if (category.name.toLowerCase().contains(query)) {
      results.add(GlobalSearchResult(
        id: category.id,
        title: category.name,
        subtitle: category.type == CategoryType.income ? 'Income' : 'Expense',
        type: SearchResultType.category,
        icon: category.icon,
        color: category.getColor(intensity),
      ));
    }
  }

  // Search transactions (limit to 50 results for performance)
  var txCount = 0;
  for (final tx in transactions) {
    if (txCount >= 50) break;

    final note = tx.note?.toLowerCase() ?? '';
    final merchant = tx.merchant?.toLowerCase() ?? '';
    final amount = CurrencyFormatter.format(tx.amount).toLowerCase();

    if (note.contains(query) ||
        merchant.contains(query) ||
        amount.contains(query)) {
      final category =
          categories.where((c) => c.id == tx.categoryId).firstOrNull;
      final account =
          accounts.where((a) => a.id == tx.accountId).firstOrNull;

      final isTransfer = tx.type == TransactionType.transfer;
      final color =
          AppColors.getTransactionColor(tx.type.name, intensity);

      results.add(GlobalSearchResult(
        id: tx.id,
        title: isTransfer
            ? 'Transfer'
            : (merchant.isNotEmpty
                ? tx.merchant!
                : (category?.name ?? 'Unknown')),
        subtitle:
            '${CurrencyFormatter.formatWithSign(tx.amount, tx.type.name)} \u2022 ${account?.name ?? 'Unknown'} \u2022 ${DateFormatter.formatRelative(tx.date)}',
        type: SearchResultType.transaction,
        icon: isTransfer
            ? LucideIcons.arrowLeftRight
            : (category?.icon ?? LucideIcons.receipt),
        color: color,
        route: '/transaction/${tx.id}',
      ));
      txCount++;
    }
  }

  return results;
});
