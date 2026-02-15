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

class HoldingLiabilityBreakdown {
  final double totalHoldings;
  final double totalLiabilities;
  final double netWorth;
  final List<AccountBreakdownItem> holdings;
  final List<AccountBreakdownItem> liabilities;

  const HoldingLiabilityBreakdown({
    required this.totalHoldings,
    required this.totalLiabilities,
    required this.netWorth,
    required this.holdings,
    required this.liabilities,
  });

  static const empty = HoldingLiabilityBreakdown(
    totalHoldings: 0,
    totalLiabilities: 0,
    netWorth: 0,
    holdings: [],
    liabilities: [],
  );
}

final holdingLiabilityBreakdownProvider = Provider<HoldingLiabilityBreakdown>((ref) {
  final accountsAsync = ref.watch(accountsProvider);
  final filter = ref.watch(analyticsFilterProvider);
  final colorIntensity = ref.watch(colorIntensityProvider);

  final accounts = accountsAsync.valueOrNull;
  if (accounts == null || accounts.isEmpty) {
    return HoldingLiabilityBreakdown.empty;
  }

  // Filter accounts if needed
  final relevantAccounts = filter.hasAccountFilter
      ? accounts.where((a) => filter.selectedAccountIds.contains(a.id)).toList()
      : accounts;

  if (relevantAccounts.isEmpty) return HoldingLiabilityBreakdown.empty;

  // Separate and calculate totals
  double totalHoldings = 0;
  double totalLiabilities = 0;
  final holdingAccounts = <Account>[];
  final liabilityAccounts = <Account>[];

  for (final account in relevantAccounts) {
    if (account.type.isLiability) {
      totalLiabilities += account.balance.abs();
      liabilityAccounts.add(account);
    } else {
      totalHoldings += account.balance;
      holdingAccounts.add(account);
    }
  }

  // Build holding breakdown items
  final holdings = holdingAccounts.map((account) {
    final percentage = totalHoldings > 0 ? (account.balance / totalHoldings) * 100 : 0.0;
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
  holdings.sort((a, b) => b.balance.compareTo(a.balance));
  liabilities.sort((a, b) => b.balance.compareTo(a.balance));

  return HoldingLiabilityBreakdown(
    totalHoldings: totalHoldings,
    totalLiabilities: totalLiabilities,
    netWorth: totalHoldings - totalLiabilities,
    holdings: holdings,
    liabilities: liabilities,
  );
});
