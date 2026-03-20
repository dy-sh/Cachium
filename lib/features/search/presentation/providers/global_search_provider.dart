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
import '../../../tags/presentation/providers/tags_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/search_result.dart';

/// The raw text typed into the search field (updated on every keystroke).
final globalSearchQueryProvider = StateProvider<String>((ref) => '');

/// The debounced query that actually triggers search (300ms delay).
final _debouncedSearchQueryProvider = Provider<String>((ref) {
  final raw = ref.watch(globalSearchQueryProvider).trim().toLowerCase();

  // We use a simple keepAlive + timer approach via a Completer trick.
  // However, Riverpod doesn't have built-in debounce. Instead we implement
  // debounce at the UI level (see search screen) and use this provider directly.
  return raw;
});

/// Active filter for search results.
enum SearchFilter { all, transactions, accounts, categories, tags }

final searchFilterProvider = StateProvider<SearchFilter>((ref) => SearchFilter.all);

/// Provides search results filtered by the active filter.
final globalSearchResultsProvider =
    Provider<List<GlobalSearchResult>>((ref) {
  final query = ref.watch(_debouncedSearchQueryProvider);
  if (query.isEmpty) return [];

  final filter = ref.watch(searchFilterProvider);
  final intensity = ref.watch(colorIntensityProvider);
  final transactions =
      ref.watch(transactionsProvider).valueOrNull ?? [];
  final accounts =
      ref.watch(accountsProvider).valueOrNull ?? [];
  final categories =
      ref.watch(categoriesProvider).valueOrNull ?? [];
  final tags = ref.watch(tagsProvider).valueOrNull ?? [];

  final results = <GlobalSearchResult>[];

  // Search accounts
  if (filter == SearchFilter.all || filter == SearchFilter.accounts) {
    for (final account in accounts) {
      if (account.name.toLowerCase().contains(query)) {
        results.add(GlobalSearchResult(
          id: account.id,
          title: account.name,
          subtitle: '${account.type.displayName} \u2022 ${CurrencyFormatter.format(account.balance, currencyCode: account.currencyCode)}',
          type: SearchResultType.account,
          icon: account.icon,
          color: account.getColorWithIntensity(intensity),
          route: '/account/${account.id}',
          matchedField: 'name',
        ));
      }
    }
  }

  // Search categories
  if (filter == SearchFilter.all || filter == SearchFilter.categories) {
    for (final category in categories) {
      if (category.name.toLowerCase().contains(query)) {
        results.add(GlobalSearchResult(
          id: category.id,
          title: category.name,
          subtitle: category.type == CategoryType.income ? 'Income' : 'Expense',
          type: SearchResultType.category,
          icon: category.icon,
          color: category.getColor(intensity),
          matchedField: 'name',
        ));
      }
    }
  }

  // Search tags
  if (filter == SearchFilter.all || filter == SearchFilter.tags) {
    for (final tag in tags) {
      if (tag.name.toLowerCase().contains(query)) {
        results.add(GlobalSearchResult(
          id: tag.id,
          title: tag.name,
          subtitle: 'Tag',
          type: SearchResultType.tag,
          icon: tag.icon,
          color: tag.getColor(intensity),
          matchedField: 'name',
        ));
      }
    }
  }

  // Search transactions (limit to 50 results for performance)
  if (filter == SearchFilter.all || filter == SearchFilter.transactions) {
    var txCount = 0;
    for (final tx in transactions) {
      if (txCount >= 50) break;

      final note = tx.note?.toLowerCase() ?? '';
      final merchant = tx.merchant?.toLowerCase() ?? '';
      final amount = CurrencyFormatter.format(tx.amount, currencyCode: tx.currencyCode).toLowerCase();

      String? matchedField;
      if (merchant.contains(query)) {
        matchedField = 'merchant';
      } else if (note.contains(query)) {
        matchedField = 'note';
      } else if (amount.contains(query)) {
        matchedField = 'amount';
      }

      if (matchedField != null) {
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
              '${CurrencyFormatter.formatWithSign(tx.amount, tx.type.name, currencyCode: tx.currencyCode)} \u2022 ${account?.name ?? 'Unknown'} \u2022 ${DateFormatter.formatRelative(tx.date)}',
          type: SearchResultType.transaction,
          icon: isTransfer
              ? LucideIcons.arrowLeftRight
              : (category?.icon ?? LucideIcons.receipt),
          color: color,
          route: '/transaction/${tx.id}',
          matchedField: matchedField,
        ));
        txCount++;
      }
    }
  }

  return results;
});

/// Count of results per type, used by filter chips.
final searchResultCountsProvider =
    Provider<Map<SearchResultType, int>>((ref) {
  final results = ref.watch(globalSearchResultsProvider);
  final counts = <SearchResultType, int>{};
  for (final r in results) {
    counts[r.type] = (counts[r.type] ?? 0) + 1;
  }
  return counts;
});
