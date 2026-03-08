import '../../../data/repositories/account_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../features/settings/data/models/database_consistency.dart';
import '../../utils/balance_calculation.dart';

/// Service for checking database consistency.
///
/// Validates that all foreign key references are valid and that
/// calculated values (like account balances) match their expected values.
class DatabaseConsistencyService {
  final TransactionRepository transactionRepository;
  final AccountRepository accountRepository;
  final CategoryRepository categoryRepository;

  DatabaseConsistencyService({
    required this.transactionRepository,
    required this.accountRepository,
    required this.categoryRepository,
  });

  /// Performs all consistency checks and returns the results.
  Future<DatabaseConsistency> checkConsistency() async {
    // Get all records (already decrypted by repositories)
    final transactions = await transactionRepository.getAllTransactions();
    final accounts = await accountRepository.getAllAccounts();
    final categories = await categoryRepository.getAllCategories();

    // Build valid ID sets
    final validAccountIds = accounts.map((a) => a.id).toSet();
    final validCategoryIds = categories.map((c) => c.id).toSet();

    // Count transactions with invalid category
    int transactionsWithInvalidCategory = 0;
    for (final tx in transactions) {
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

    return DatabaseConsistency(
      transactionsWithInvalidCategory: transactionsWithInvalidCategory,
      transactionsWithInvalidAccount: transactionsWithInvalidAccount,
      categoriesWithInvalidParent: categoriesWithInvalidParent,
      accountsWithIncorrectBalance: accountsWithIncorrectBalance,
      duplicateTransactions: duplicateTransactions,
    );
  }
}
