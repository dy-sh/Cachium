import '../../../data/repositories/account_repository.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/recurring_rule_repository.dart';
import '../../../data/repositories/savings_goal_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/transaction_template_repository.dart';
import '../../../features/settings/data/models/database_consistency.dart';
import '../../../features/transactions/data/models/transaction.dart';
import '../../utils/balance_calculation.dart';

/// Service for checking database consistency.
///
/// Validates that all foreign key references are valid and that
/// calculated values (like account balances) match their expected values.
class DatabaseConsistencyService {
  final TransactionRepository transactionRepository;
  final AccountRepository accountRepository;
  final CategoryRepository categoryRepository;
  final BudgetRepository budgetRepository;
  final SavingsGoalRepository savingsGoalRepository;
  final RecurringRuleRepository recurringRuleRepository;
  final TransactionTemplateRepository transactionTemplateRepository;

  DatabaseConsistencyService({
    required this.transactionRepository,
    required this.accountRepository,
    required this.categoryRepository,
    required this.budgetRepository,
    required this.savingsGoalRepository,
    required this.recurringRuleRepository,
    required this.transactionTemplateRepository,
  });

  /// Performs all consistency checks and returns the results.
  Future<DatabaseConsistency> checkConsistency() async {
    // Get all records (already decrypted by repositories)
    final transactions = await transactionRepository.getAllTransactions();
    final accounts = await accountRepository.getAllAccounts();
    final categories = await categoryRepository.getAllCategories();
    final budgets = await budgetRepository.getAllBudgets();
    final savingsGoals = await savingsGoalRepository.getAllGoals();
    final rules = await recurringRuleRepository.getAllRules();
    final templates = await transactionTemplateRepository.getAllTemplates();

    // Build valid ID sets
    final validAccountIds = accounts.map((a) => a.id).toSet();
    final validCategoryIds = categories.map((c) => c.id).toSet();

    // Count transactions with invalid category
    int transactionsWithInvalidCategory = 0;
    for (final tx in transactions) {
      if (tx.isTransfer || tx.categoryId.isEmpty) continue;
      if (!validCategoryIds.contains(tx.categoryId)) {
        transactionsWithInvalidCategory++;
      }
    }

    // Count transactions with invalid account
    int transactionsWithInvalidAccount = 0;
    for (final tx in transactions) {
      if (!validAccountIds.contains(tx.accountId)) {
        transactionsWithInvalidAccount++;
      }
    }

    // Count categories with invalid parent
    int categoriesWithInvalidParent = 0;
    for (final category in categories) {
      if (category.parentId != null &&
          !validCategoryIds.contains(category.parentId)) {
        categoriesWithInvalidParent++;
      }
    }

    // Count duplicate transactions (same date/time and amount)
    final Map<String, int> transactionKeys = {};
    for (final tx in transactions) {
      // Key is combination of date (milliseconds) and amount
      final key = '${tx.date.millisecondsSinceEpoch}_${tx.amount}';
      transactionKeys[key] = (transactionKeys[key] ?? 0) + 1;
    }
    // Count transactions that are duplicates (appear more than once)
    int duplicateTransactions = 0;
    for (final count in transactionKeys.values) {
      if (count > 1) {
        duplicateTransactions += count;
      }
    }

    // Count accounts with incorrect balance (handles income, expense, and transfers)
    final accountDeltas = calculateAccountDeltas(transactions);

    int accountsWithIncorrectBalance = 0;
    for (final account in accounts) {
      final transactionDelta = accountDeltas[account.id] ?? 0;
      final expectedBalance = account.initialBalance + transactionDelta;
      final hasIncorrectBalance =
          (account.balance - expectedBalance).abs() > 0.001;
      if (hasIncorrectBalance) {
        accountsWithIncorrectBalance++;
      }
    }

    // Count budgets with invalid category
    int budgetsWithInvalidCategory = 0;
    for (final budget in budgets) {
      if (!validCategoryIds.contains(budget.categoryId)) {
        budgetsWithInvalidCategory++;
      }
    }

    // Count savings goals with invalid linked account
    int savingsGoalsWithInvalidAccount = 0;
    for (final goal in savingsGoals) {
      if (goal.linkedAccountId != null &&
          !validAccountIds.contains(goal.linkedAccountId)) {
        savingsGoalsWithInvalidAccount++;
      }
    }

    // Count recurring rules with invalid references
    int rulesWithInvalidReferences = 0;
    for (final rule in rules) {
      if (!validAccountIds.contains(rule.accountId) ||
          !validCategoryIds.contains(rule.categoryId) ||
          (rule.type == TransactionType.transfer &&
              rule.destinationAccountId != null &&
              !validAccountIds.contains(rule.destinationAccountId))) {
        rulesWithInvalidReferences++;
      }
    }

    // Count templates with invalid references
    int templatesWithInvalidReferences = 0;
    for (final template in templates) {
      if ((template.accountId != null &&
              !validAccountIds.contains(template.accountId)) ||
          (template.categoryId != null &&
              !validCategoryIds.contains(template.categoryId)) ||
          (template.destinationAccountId != null &&
              !validAccountIds.contains(template.destinationAccountId))) {
        templatesWithInvalidReferences++;
      }
    }

    return DatabaseConsistency(
      transactionsWithInvalidCategory: transactionsWithInvalidCategory,
      transactionsWithInvalidAccount: transactionsWithInvalidAccount,
      categoriesWithInvalidParent: categoriesWithInvalidParent,
      accountsWithIncorrectBalance: accountsWithIncorrectBalance,
      duplicateTransactions: duplicateTransactions,
      budgetsWithInvalidCategory: budgetsWithInvalidCategory,
      savingsGoalsWithInvalidAccount: savingsGoalsWithInvalidAccount,
      rulesWithInvalidReferences: rulesWithInvalidReferences,
      templatesWithInvalidReferences: templatesWithInvalidReferences,
    );
  }
}
