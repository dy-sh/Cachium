import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../data/models/sankey_flow.dart';
import 'filtered_transactions_provider.dart';

final sankeyShowAccountsProvider = StateProvider<bool>((ref) => false);

final sankeyFlowDataProvider = Provider<SankeyData>((ref) {
  final transactions = ref.watch(filteredAnalyticsTransactionsProvider);
  final categoriesAsync = ref.watch(categoriesProvider);
  final accountsAsync = ref.watch(accountsProvider);
  final showAccounts = ref.watch(sankeyShowAccountsProvider);
  final colorIntensity = ref.watch(colorIntensityProvider);

  final categories = categoriesAsync.valueOrNull;
  final accounts = accountsAsync.valueOrNull;
  if (transactions.isEmpty || categories == null || accounts == null) {
    return const SankeyData(sourceNodes: [], targetNodes: [], links: []);
  }

  final catMap = <String, Category>{};
  for (final c in categories) {
    catMap[c.id] = c;
  }
  final acctMap = <String, Account>{};
  for (final a in accounts) {
    acctMap[a.id] = a;
  }

  // Aggregate income by category
  final Map<String, double> incomeByCategory = {};
  final Map<String, double> expenseByCategory = {};
  final Map<String, Map<String, double>> incomeToAccount = {};
  final Map<String, Map<String, double>> accountToExpense = {};

  for (final tx in transactions) {
    // Use parent category if exists
    final cat = catMap[tx.categoryId];
    final catId = cat?.parentId ?? tx.categoryId;

    if (tx.type == TransactionType.income) {
      incomeByCategory[catId] = (incomeByCategory[catId] ?? 0) + tx.amount;
      if (showAccounts) {
        incomeToAccount[catId] ??= {};
        incomeToAccount[catId]![tx.accountId] = (incomeToAccount[catId]![tx.accountId] ?? 0) + tx.amount;
      }
    } else {
      expenseByCategory[catId] = (expenseByCategory[catId] ?? 0) + tx.amount;
      if (showAccounts) {
        accountToExpense[tx.accountId] ??= {};
        accountToExpense[tx.accountId]![catId] = (accountToExpense[tx.accountId]![catId] ?? 0) + tx.amount;
      }
    }
  }

  final accentColors = AppColors.getAccentOptions(colorIntensity);

  // Build source nodes (income categories)
  final sourceNodes = incomeByCategory.entries.map((e) {
    final cat = catMap[e.key];
    final colorIdx = cat?.colorIndex ?? 0;
    return SankeyNode(
      id: 'income_${e.key}',
      label: cat?.name ?? 'Unknown',
      color: accentColors[colorIdx.clamp(0, accentColors.length - 1)],
      amount: e.value,
    );
  }).toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));

  // Build target nodes (expense categories)
  final targetNodes = expenseByCategory.entries.map((e) {
    final cat = catMap[e.key];
    final colorIdx = cat?.colorIndex ?? 0;
    return SankeyNode(
      id: 'expense_${e.key}',
      label: cat?.name ?? 'Unknown',
      color: accentColors[colorIdx.clamp(0, accentColors.length - 1)],
      amount: e.value,
    );
  }).toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));

  if (!showAccounts) {
    // Direct flow: income categories -> expense categories proportionally
    final totalIncome = incomeByCategory.values.fold(0.0, (s, v) => s + v);
    final totalExpense = expenseByCategory.values.fold(0.0, (s, v) => s + v);
    final flowTotal = totalIncome < totalExpense ? totalIncome : totalExpense;

    final links = <SankeyLink>[];
    for (final src in sourceNodes) {
      final srcProportion = totalIncome > 0 ? src.amount / totalIncome : 0.0;
      for (final tgt in targetNodes) {
        final tgtProportion = totalExpense > 0 ? tgt.amount / totalExpense : 0.0;
        final amount = flowTotal * srcProportion * tgtProportion;
        if (amount > 0) {
          links.add(SankeyLink(
            sourceId: src.id,
            targetId: tgt.id,
            amount: amount,
            color: src.color.withValues(alpha: 0.4),
          ));
        }
      }
    }

    return SankeyData(sourceNodes: sourceNodes, targetNodes: targetNodes, links: links);
  }

  // With accounts as middle nodes
  final usedAccountIds = <String>{};
  for (final m in incomeToAccount.values) {
    usedAccountIds.addAll(m.keys);
  }
  for (final m in accountToExpense.keys) {
    usedAccountIds.add(m);
  }

  final middleNodes = usedAccountIds.where((id) => acctMap.containsKey(id)).map((id) {
    final acct = acctMap[id]!;
    return SankeyNode(
      id: 'account_$id',
      label: acct.name,
      color: acct.color,
      amount: 0, // calculated from links
    );
  }).toList();

  final links = <SankeyLink>[];

  // Income -> Account links
  for (final entry in incomeToAccount.entries) {
    final srcColor = sourceNodes.firstWhere((n) => n.id == 'income_${entry.key}', orElse: () => sourceNodes.first).color;
    for (final acctEntry in entry.value.entries) {
      links.add(SankeyLink(
        sourceId: 'income_${entry.key}',
        targetId: 'account_${acctEntry.key}',
        amount: acctEntry.value,
        color: srcColor.withValues(alpha: 0.4),
      ));
    }
  }

  // Account -> Expense links
  for (final entry in accountToExpense.entries) {
    final acct = acctMap[entry.key];
    final acctColor = acct?.color ?? AppColors.textSecondary;
    for (final catEntry in entry.value.entries) {
      links.add(SankeyLink(
        sourceId: 'account_${entry.key}',
        targetId: 'expense_${catEntry.key}',
        amount: catEntry.value,
        color: acctColor.withValues(alpha: 0.4),
      ));
    }
  }

  return SankeyData(
    sourceNodes: sourceNodes,
    targetNodes: targetNodes,
    middleNodes: middleNodes,
    links: links,
  );
});
