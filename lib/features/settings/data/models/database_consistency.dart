import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Result of a single consistency check.
class ConsistencyCheck {
  final String label;
  final int count;
  final IconData icon;

  const ConsistencyCheck({
    required this.label,
    required this.count,
    required this.icon,
  });

  bool get hasIssues => count > 0;
}

/// Results of database consistency checks.
class DatabaseConsistency {
  final int transactionsWithInvalidCategory;
  final int transactionsWithInvalidAccount;
  final int categoriesWithInvalidParent;
  final int accountsWithIncorrectBalance;

  const DatabaseConsistency({
    required this.transactionsWithInvalidCategory,
    required this.transactionsWithInvalidAccount,
    required this.categoriesWithInvalidParent,
    required this.accountsWithIncorrectBalance,
  });

  bool get isConsistent => totalIssues == 0;

  int get totalIssues =>
      transactionsWithInvalidCategory +
      transactionsWithInvalidAccount +
      categoriesWithInvalidParent +
      accountsWithIncorrectBalance;

  /// Returns all checks for display in the details popup.
  List<ConsistencyCheck> get allChecks => [
        ConsistencyCheck(
          label: 'Transactions with invalid category',
          count: transactionsWithInvalidCategory,
          icon: LucideIcons.tag,
        ),
        ConsistencyCheck(
          label: 'Transactions with invalid account',
          count: transactionsWithInvalidAccount,
          icon: LucideIcons.wallet,
        ),
        ConsistencyCheck(
          label: 'Categories with invalid parent',
          count: categoriesWithInvalidParent,
          icon: LucideIcons.folderTree,
        ),
        ConsistencyCheck(
          label: 'Accounts with incorrect balance',
          count: accountsWithIncorrectBalance,
          icon: LucideIcons.calculator,
        ),
      ];

  /// Returns only the checks that have issues (for expanded display).
  List<ConsistencyCheck> get issueChecks =>
      allChecks.where((check) => check.hasIssues).toList();
}
