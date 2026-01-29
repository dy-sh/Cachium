import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import 'analytics_filter_provider.dart';

class AccountBreakdownItem {
  final String accountId;
  final String name;
  final AccountType type;
  final double balance;
  final Color color;
  final double percentage;

  const AccountBreakdownItem({
    required this.accountId,
    required this.name,
    required this.type,
    required this.balance,
    required this.color,
    required this.percentage,
  });
}

class AssetLiabilityBreakdown {
  final double totalAssets;
  final double totalLiabilities;
  final double netWorth;
  final List<AccountBreakdownItem> assets;
  final List<AccountBreakdownItem> liabilities;

  const AssetLiabilityBreakdown({
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netWorth,
    required this.assets,
    required this.liabilities,
  });

  static const empty = AssetLiabilityBreakdown(
    totalAssets: 0,
    totalLiabilities: 0,
    netWorth: 0,
    assets: [],
    liabilities: [],
  );
}

final assetLiabilityBreakdownProvider = Provider<AssetLiabilityBreakdown>((ref) {
  final accountsAsync = ref.watch(accountsProvider);
  final filter = ref.watch(analyticsFilterProvider);
  final colorIntensity = ref.watch(colorIntensityProvider);

  final accounts = accountsAsync.valueOrNull;
  if (accounts == null || accounts.isEmpty) {
    return AssetLiabilityBreakdown.empty;
  }

  // Filter accounts if needed
  final relevantAccounts = filter.hasAccountFilter
      ? accounts.where((a) => filter.selectedAccountIds.contains(a.id)).toList()
      : accounts;

  if (relevantAccounts.isEmpty) return AssetLiabilityBreakdown.empty;

  // Separate and calculate totals
  double totalAssets = 0;
  double totalLiabilities = 0;
  final assetAccounts = <Account>[];
  final liabilityAccounts = <Account>[];

  for (final account in relevantAccounts) {
    if (account.type.isLiability) {
      totalLiabilities += account.balance.abs();
      liabilityAccounts.add(account);
    } else {
      totalAssets += account.balance;
      assetAccounts.add(account);
    }
  }

  // Build asset breakdown items
  final assets = assetAccounts.map((account) {
    final percentage = totalAssets > 0 ? (account.balance / totalAssets) * 100 : 0.0;
    return AccountBreakdownItem(
      accountId: account.id,
      name: account.name,
      type: account.type,
      balance: account.balance,
      color: account.getColorWithIntensity(colorIntensity),
      percentage: percentage,
    );
  }).toList();

  // Build liability breakdown items
  final liabilities = liabilityAccounts.map((account) {
    final absBalance = account.balance.abs();
    final percentage = totalLiabilities > 0 ? (absBalance / totalLiabilities) * 100 : 0.0;
    return AccountBreakdownItem(
      accountId: account.id,
      name: account.name,
      type: account.type,
      balance: absBalance,
      color: account.getColorWithIntensity(colorIntensity),
      percentage: percentage,
    );
  }).toList();

  // Sort by balance descending
  assets.sort((a, b) => b.balance.compareTo(a.balance));
  liabilities.sort((a, b) => b.balance.compareTo(a.balance));

  return AssetLiabilityBreakdown(
    totalAssets: totalAssets,
    totalLiabilities: totalLiabilities,
    netWorth: totalAssets - totalLiabilities,
    assets: assets,
    liabilities: liabilities,
  );
});
