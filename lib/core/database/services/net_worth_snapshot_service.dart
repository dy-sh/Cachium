import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/repositories/net_worth_snapshot_repository.dart';
import '../../../features/accounts/data/models/account.dart';
import '../../../features/accounts/presentation/providers/accounts_provider.dart';
import '../../../features/analytics/data/models/net_worth_snapshot.dart';
import '../../../features/settings/presentation/providers/settings_provider.dart';
import '../../../features/transactions/data/models/transaction.dart';
import '../../../features/transactions/presentation/providers/transactions_provider.dart';
import '../../providers/database_providers.dart';

const _uuid = Uuid();

class NetWorthSnapshotService {
  /// Takes a snapshot for the current month if one doesn't already exist.
  static Future<void> takeSnapshotIfNeeded(ProviderContainer container) async {
    try {
      final repo = container.read(netWorthSnapshotRepositoryProvider);
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      final existing = await repo.getForMonth(monthStart);
      if (existing != null) return; // Already have this month's snapshot

      final accounts = container.read(accountsProvider).valueOrNull;
      if (accounts == null || accounts.isEmpty) return;

      final mainCurrency = container.read(mainCurrencyCodeProvider);

      unawaited(_takeSnapshot(repo, accounts, mainCurrency, monthStart));
    } catch (e) {
      debugPrint('NetWorthSnapshotService.takeSnapshotIfNeeded failed: $e');
    }
  }

  /// Backfills historical snapshots from transaction data if none exist.
  static Future<void> backfillIfNeeded(ProviderContainer container) async {
    try {
      final repo = container.read(netWorthSnapshotRepositoryProvider);
      final all = await repo.getAll();
      if (all.isNotEmpty) return; // Already have snapshots

      final accounts = container.read(accountsProvider).valueOrNull;
      final transactions = container.read(transactionsProvider).valueOrNull;
      if (accounts == null || accounts.isEmpty) return;
      if (transactions == null || transactions.isEmpty) return;

      final mainCurrency = container.read(mainCurrencyCodeProvider);

      // Find earliest transaction date
      DateTime earliest = transactions.first.date;
      for (final tx in transactions) {
        if (tx.date.isBefore(earliest)) earliest = tx.date;
      }

      // Build account type lookup
      final accountTypes = <String, AccountType>{};
      final currentBalances = <String, double>{};
      for (final account in accounts) {
        accountTypes[account.id] = account.type;
        currentBalances[account.id] = account.balance;
      }

      // Sort transactions by date descending for backward computation
      final sortedTx = List<Transaction>.from(transactions)
        ..sort((a, b) => b.date.compareTo(a.date));

      // Work backwards from current balances month by month
      final now = DateTime.now();
      var currentMonth = DateTime(now.year, now.month, 1);
      final earliestMonth = DateTime(earliest.year, earliest.month, 1);

      final runningBalances = Map<String, double>.from(currentBalances);
      int txIndex = 0;

      // Collect snapshots working backwards
      final snapshots = <NetWorthSnapshot>[];

      while (!currentMonth.isBefore(earliestMonth)) {
        // Reverse all transactions in months after currentMonth
        while (txIndex < sortedTx.length) {
          final tx = sortedTx[txIndex];
          final txMonth = DateTime(tx.date.year, tx.date.month, 1);

          if (txMonth.isAfter(currentMonth)) {
            // Reverse this transaction's effect
            _reverseTxEffect(tx, runningBalances);
            txIndex++;
          } else {
            break;
          }
        }

        // Take snapshot at this month
        double totalHoldings = 0;
        double totalLiabilities = 0;
        final balancesMap = <String, double>{};

        for (final entry in runningBalances.entries) {
          final accountType = accountTypes[entry.key];
          if (accountType == null) continue;
          balancesMap[entry.key] = entry.value;

          if (accountType.isLiability) {
            totalLiabilities += entry.value.abs();
          } else {
            totalHoldings += entry.value;
          }
        }

        snapshots.add(NetWorthSnapshot(
          id: _uuid.v4(),
          date: currentMonth,
          netWorth: totalHoldings - totalLiabilities,
          totalHoldings: totalHoldings,
          totalLiabilities: totalLiabilities,
          perAccountBalances: Map<String, double>.from(balancesMap),
          mainCurrencyCode: mainCurrency,
        ));

        // Move to previous month
        currentMonth = DateTime(
          currentMonth.month == 1 ? currentMonth.year - 1 : currentMonth.year,
          currentMonth.month == 1 ? 12 : currentMonth.month - 1,
          1,
        );

        // Safety: max 5 years of backfill
        if (snapshots.length >= 60) break;
      }

      // Save all snapshots
      for (final snapshot in snapshots) {
        await repo.save(snapshot);
      }

      debugPrint('NetWorthSnapshotService: backfilled ${snapshots.length} snapshots');
    } catch (e) {
      debugPrint('NetWorthSnapshotService.backfillIfNeeded failed: $e');
    }
  }

  static void _reverseTxEffect(Transaction tx, Map<String, double> balances) {
    final accountId = tx.accountId;
    if (!balances.containsKey(accountId)) return;

    if (tx.type == TransactionType.transfer) {
      balances[accountId] = balances[accountId]! + tx.amount;
      if (tx.destinationAccountId != null && balances.containsKey(tx.destinationAccountId!)) {
        balances[tx.destinationAccountId!] =
            balances[tx.destinationAccountId!]! - (tx.destinationAmount ?? tx.amount);
      }
    } else if (tx.type == TransactionType.income) {
      balances[accountId] = balances[accountId]! - tx.amount;
    } else {
      balances[accountId] = balances[accountId]! + tx.amount;
    }
  }

  static Future<void> _takeSnapshot(
    NetWorthSnapshotRepository repo,
    List<Account> accounts,
    String mainCurrency,
    DateTime monthStart,
  ) async {
    double totalHoldings = 0;
    double totalLiabilities = 0;
    final balancesMap = <String, double>{};

    for (final account in accounts) {
      balancesMap[account.id] = account.balance;
      if (account.type.isLiability) {
        totalLiabilities += account.balance.abs();
      } else {
        totalHoldings += account.balance;
      }
    }

    final snapshot = NetWorthSnapshot(
      id: _uuid.v4(),
      date: monthStart,
      netWorth: totalHoldings - totalLiabilities,
      totalHoldings: totalHoldings,
      totalLiabilities: totalLiabilities,
      perAccountBalances: balancesMap,
      mainCurrencyCode: mainCurrency,
    );

    await repo.save(snapshot);
  }
}
