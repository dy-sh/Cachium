import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/financial_insight.dart';

final recurringDetectionProvider = Provider<List<FinancialInsight>>((ref) {
  final transactionsAsync = ref.watch(transactionsProvider);
  final categoriesAsync = ref.watch(categoriesProvider);

  final transactions = transactionsAsync.valueOrNull;
  final categories = categoriesAsync.valueOrNull;
  if (transactions == null || categories == null || transactions.length < 3) return [];

  final insights = <FinancialInsight>[];

  // Group by (rounded amount to nearest integer, categoryId)
  final groups = <String, List<Transaction>>{};
  for (final tx in transactions) {
    final key = '${tx.amount.round()}_${tx.categoryId}';
    groups.putIfAbsent(key, () => []).add(tx);
  }

  for (final entry in groups.entries) {
    final txs = entry.value;
    if (txs.length < 3) continue;

    // Sort by date
    txs.sort((a, b) => a.date.compareTo(b.date));

    // Check for regular intervals
    final intervals = <int>[];
    for (int i = 1; i < txs.length; i++) {
      intervals.add(txs[i].date.difference(txs[i - 1].date).inDays);
    }

    if (intervals.isEmpty) continue;

    final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;

    // Check if intervals are consistent (within ±3 days of average)
    final isRegular = intervals.every((i) => (i - avgInterval).abs() <= 3);
    if (!isRegular) continue;

    // Determine frequency
    String frequency;
    if (avgInterval >= 5 && avgInterval <= 9) {
      frequency = 'weekly';
    } else if (avgInterval >= 25 && avgInterval <= 35) {
      frequency = 'monthly';
    } else if (avgInterval >= 350 && avgInterval <= 380) {
      frequency = 'yearly';
    } else {
      continue;
    }

    final cat = categories.firstWhere(
      (c) => c.id == txs.first.categoryId,
      orElse: () => Category(
        id: txs.first.categoryId,
        name: 'Unknown',
        icon: const IconData(0),
        colorIndex: 0,
        type: CategoryType.expense,
      ),
    );

    final amount = txs.first.amount;
    insights.add(FinancialInsight(
      message: '${cat.name}: ${amount.toStringAsFixed(0)} appears $frequency',
      type: InsightType.recurring,
      sentiment: InsightSentiment.neutral,
      icon: LucideIcons.repeat,
      priority: InsightPriority.medium,
      value: amount,
      categoryId: txs.first.categoryId,
    ));

    if (insights.length >= 3) break;
  }

  return insights;
});
