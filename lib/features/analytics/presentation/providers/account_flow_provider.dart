import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/data/models/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../data/models/account_flow.dart';
import 'filtered_transactions_provider.dart';

enum FlowViewMode { byCategory, byAccount }

final flowViewModeProvider = StateProvider<FlowViewMode>((ref) => FlowViewMode.byCategory);

final accountFlowDataProvider = Provider<AccountFlowData>((ref) {
  final transactions = ref.watch(filteredAnalyticsTransactionsProvider);
  final accountsAsync = ref.watch(accountsProvider);
  final categoriesAsync = ref.watch(categoriesProvider);
  final colorIntensity = ref.watch(colorIntensityProvider);
  final viewMode = ref.watch(flowViewModeProvider);

  final accounts = accountsAsync.valueOrNull;
  final categories = categoriesAsync.valueOrNull;

  if (transactions.isEmpty || accounts == null || categories == null) {
    return const AccountFlowData(
      incomeNodes: [],
      expenseNodes: [],
      totalIncome: 0,
      totalExpense: 0,
    );
  }

  final incomeTransactions = transactions.where((tx) => tx.type == TransactionType.income).toList();
  final expenseTransactions = transactions.where((tx) => tx.type == TransactionType.expense).toList();

  final totalIncome = incomeTransactions.fold<double>(0, (s, tx) => s + tx.amount);
  final totalExpense = expenseTransactions.fold<double>(0, (s, tx) => s + tx.amount);

  final incomeNodes = _buildNodes(
    transactions: incomeTransactions,
    total: totalIncome,
    accounts: accounts,
    categories: categories,
    colorIntensity: colorIntensity,
    viewMode: viewMode,
    isIncome: true,
  );

  final expenseNodes = _buildNodes(
    transactions: expenseTransactions,
    total: totalExpense,
    accounts: accounts,
    categories: categories,
    colorIntensity: colorIntensity,
    viewMode: viewMode,
    isIncome: false,
  );

  return AccountFlowData(
    incomeNodes: incomeNodes,
    expenseNodes: expenseNodes,
    totalIncome: totalIncome,
    totalExpense: totalExpense,
  );
});

List<FlowNode> _buildNodes({
  required List<Transaction> transactions,
  required double total,
  required List<Account> accounts,
  required List<Category> categories,
  required ColorIntensity colorIntensity,
  required FlowViewMode viewMode,
  required bool isIncome,
}) {
  if (total == 0) return [];

  // For expense side, always group by category.
  // For income side, group by viewMode choice.
  final bool groupByCategory = !isIncome || viewMode == FlowViewMode.byCategory;

  final Map<String, double> amounts = {};
  for (final tx in transactions) {
    final key = groupByCategory ? tx.categoryId : tx.accountId;
    amounts[key] = (amounts[key] ?? 0) + tx.amount;
  }

  // Sort descending
  final sorted = amounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

  // Cap at 8 + Other
  final maxItems = 8;
  final topEntries = sorted.take(maxItems).toList();
  final otherAmount = sorted.skip(maxItems).fold<double>(0, (s, e) => s + e.value);

  final categoryMap = {for (final c in categories) c.id: c};
  final accountMap = {for (final a in accounts) a.id: a};
  final accentColors = AppColors.getAccentOptions(colorIntensity);

  List<FlowNode> nodes = [];
  for (var i = 0; i < topEntries.length; i++) {
    final entry = topEntries[i];
    if (groupByCategory) {
      final cat = categoryMap[entry.key];
      nodes.add(FlowNode(
        id: entry.key,
        label: cat?.name ?? 'Unknown',
        icon: cat?.icon,
        color: AppColors.getAccentColor(cat?.colorIndex ?? i, colorIntensity),
        amount: entry.value,
        percentage: entry.value / total * 100,
      ));
    } else {
      final acc = accountMap[entry.key];
      nodes.add(FlowNode(
        id: entry.key,
        label: acc?.name ?? 'Unknown',
        icon: acc?.customIcon,
        color: acc?.getColorWithIntensity(colorIntensity) ??
            accentColors[i % accentColors.length],
        amount: entry.value,
        percentage: entry.value / total * 100,
      ));
    }
  }

  if (otherAmount > 0) {
    nodes.add(FlowNode(
      id: 'other',
      label: 'Other',
      color: AppColors.textTertiary,
      amount: otherAmount,
      percentage: otherAmount / total * 100,
    ));
  }

  return nodes;
}
