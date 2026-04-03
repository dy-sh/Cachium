import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_logger.dart';

import '../../../../core/database/services/database_consistency_service.dart';
import '../../../../core/database/services/database_export_service.dart';
import '../../../../core/database/services/database_import_service.dart';
import '../../../../core/database/services/database_metrics_service.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/providers/provider_utils.dart';
import '../../../../core/utils/balance_calculation.dart';
import '../../../../data/demo/demo_data.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/csv_import_preview.dart';
import '../../data/models/database_consistency.dart';
import '../../data/models/database_metrics.dart';
import '../../data/models/export_options.dart';
import 'settings_provider.dart';

/// Provider for the database metrics service.
final databaseMetricsServiceProvider = Provider<DatabaseMetricsService>((ref) {
  return DatabaseMetricsService(
    database: ref.watch(databaseProvider),
  );
});

/// Provider for the database export service.
final databaseExportServiceProvider = Provider<DatabaseExportService>((ref) {
  return DatabaseExportService(
    database: ref.watch(databaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
});

/// Provider for the database import service.
final databaseImportServiceProvider = Provider<DatabaseImportService>((ref) {
  return DatabaseImportService(
    database: ref.watch(databaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
});

/// Provider for database metrics.
/// This is a future provider that fetches metrics from the database.
final databaseMetricsProvider = FutureProvider<DatabaseMetrics>((ref) async {
  final service = ref.watch(databaseMetricsServiceProvider);
  return service.getMetrics();
});

/// Provider for the database consistency service.
final databaseConsistencyServiceProvider =
    Provider<DatabaseConsistencyService>((ref) {
  return DatabaseConsistencyService(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    accountRepository: ref.watch(accountRepositoryProvider),
    categoryRepository: ref.watch(categoryRepositoryProvider),
    budgetRepository: ref.watch(budgetRepositoryProvider),
    savingsGoalRepository: ref.watch(savingsGoalRepositoryProvider),
    recurringRuleRepository: ref.watch(recurringRuleRepositoryProvider),
    transactionTemplateRepository: ref.watch(transactionTemplateRepositoryProvider),
  );
});

/// Provider for database consistency checks.
/// This is a future provider that performs consistency checks on the database.
final databaseConsistencyProvider =
    FutureProvider<DatabaseConsistency>((ref) async {
  final service = ref.watch(databaseConsistencyServiceProvider);
  return service.checkConsistency();
});

/// Provider for export options state.
class ExportOptionsNotifier extends Notifier<ExportOptions> {
  @override
  ExportOptions build() {
    return const ExportOptions(encryptionEnabled: true);
  }

  void setEncryptionEnabled(bool enabled) {
    state = state.copyWith(encryptionEnabled: enabled);
  }

  void reset() {
    state = const ExportOptions(encryptionEnabled: true);
  }
}

const _log = AppLogger('DatabaseMgmt');

final exportOptionsProvider = NotifierProvider<ExportOptionsNotifier, ExportOptions>(() {
  return ExportOptionsNotifier();
});

/// Provider for tracking export operation state.
class ExportStateNotifier extends Notifier<AsyncValue<String?>> {
  @override
  AsyncValue<String?> build() {
    return const AsyncValue.data(null);
  }

  Future<void> exportToSqlite(ExportOptions options) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(databaseExportServiceProvider);
      final path = await service.exportToSqlite(options);
      await service.shareSqliteExport(path);
      state = AsyncValue.data(path);
    } catch (e, st) {
      _log.error('Export to SQLite failed: $e\n$st');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> exportToCsv(ExportOptions options) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(databaseExportServiceProvider);
      final paths = await service.exportToCsv(options);
      await service.shareCsvExport(paths);
      state = AsyncValue.data(paths.first);
    } catch (e, st) {
      _log.error('Export to CSV failed: $e\n$st');
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final exportStateProvider = NotifierProvider<ExportStateNotifier, AsyncValue<String?>>(() {
  return ExportStateNotifier();
});

/// Provider for tracking import operation state.
class ImportStateNotifier extends Notifier<AsyncValue<ImportResult?>> {
  @override
  AsyncValue<ImportResult?> build() {
    return const AsyncValue.data(null);
  }

  /// Pick a SQLite file and return the result.
  /// Returns FilePickResult with path, error, or cancelled state.
  Future<FilePickResult> pickSqliteFile() async {
    final service = ref.read(databaseImportServiceProvider);
    return service.pickSqliteFile();
  }

  /// Get metrics from an external SQLite file.
  DatabaseMetrics getMetricsFromFile(String path) {
    final service = ref.read(databaseImportServiceProvider);
    return service.getMetricsFromSqliteFile(path);
  }

  /// Clear all existing data and import from the given SQLite file path.
  Future<void> clearAndImportFromSqlite(String path) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(databaseImportServiceProvider);
      final result = await service.clearAndImportFromSqlite(path);
      state = AsyncValue.data(result);

      // Invalidate all data providers to refresh UI
      invalidateAllDataProviders(ref);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> importFromSqlite() async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(databaseImportServiceProvider);
      final result = await service.pickAndImportSqlite();
      state = AsyncValue.data(result);

      // Invalidate all data providers to refresh UI
      invalidateAllDataProviders(ref);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> importFromCsv() async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(databaseImportServiceProvider);
      final result = await service.pickAndImportCsv();
      state = AsyncValue.data(result);

      // Invalidate all data providers to refresh UI
      invalidateAllDataProviders(ref);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Pick CSV files and return the result.
  /// Returns FilePickResult with paths, error, or cancelled state.
  Future<FilePickResult> pickCsvFiles() async {
    final service = ref.read(databaseImportServiceProvider);
    return service.pickCsvFiles();
  }

  /// Generate a preview of what will be imported from CSV files.
  Future<CsvImportPreview?> generateCsvPreview(List<String> paths) async {
    try {
      final service = ref.read(databaseImportServiceProvider);
      return await service.generateCsvPreview(paths);
    } catch (e) {
      return null;
    }
  }

  /// Import from CSV files, skipping duplicate transactions.
  Future<void> importFromCsvWithPreview(List<String> paths) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(databaseImportServiceProvider);
      final result = await service.importFromCsvWithSkipDuplicates(paths);
      state = AsyncValue.data(result);

      // Invalidate all data providers to refresh UI
      invalidateAllDataProviders(ref);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final importStateProvider = NotifierProvider<ImportStateNotifier, AsyncValue<ImportResult?>>(() {
  return ImportStateNotifier();
});

/// Provider for database management operations (delete, seed demo).
class DatabaseManagementNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<bool> deleteAllData({bool resetSettings = false}) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseProvider);

      // Delete all data
      await db.deleteAllData(includeSettings: resetSettings);

      // Reset settings if requested
      if (resetSettings) {
        await ref.read(settingsProvider.notifier).reset();
      }

      // Invalidate all related providers to refresh UI
      invalidateEntityProviders(ref);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> createDemoDatabase() async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseProvider);
      final accountRepo = ref.read(accountRepositoryProvider);
      final categoryRepo = ref.read(categoryRepositoryProvider);
      final transactionRepo = ref.read(transactionRepositoryProvider);
      final assetRepo = ref.read(assetRepositoryProvider);
      final assetCategoryRepo = ref.read(assetCategoryRepositoryProvider);
      final billRepo = ref.read(billRepositoryProvider);
      final budgetRepo = ref.read(budgetRepositoryProvider);
      final templateRepo = ref.read(transactionTemplateRepositoryProvider);
      final savingsGoalRepo = ref.read(savingsGoalRepositoryProvider);
      final tagRepo = ref.read(tagRepositoryProvider);

      // Wrap all database operations in a transaction to prevent locking
      await db.transaction(() async {
        // Delete existing data first
        await db.deleteAllTransactions();
        await db.deleteAllTransactionTags();
        await db.deleteAllAccounts();
        await db.deleteAllCategories();
        await db.deleteAllAssets();
        await db.deleteAllAssetCategories();
        await db.deleteAllBills();
        await db.deleteAllBudgets();
        await db.deleteAllTransactionTemplates();
        await db.deleteAllSavingsGoals();
        await db.deleteAllTags();

        // Seed accounts
        for (final account in DemoData.accounts) {
          await accountRepo.upsertAccount(account);
        }

        // Seed categories (default categories - uses upsert internally)
        await categoryRepo.seedDefaultCategories();

        // Seed asset categories
        for (final category in DemoData.assetCategories) {
          await assetCategoryRepo.createCategory(category);
        }

        // Seed assets
        for (final asset in DemoData.assets) {
          await assetRepo.upsertAsset(asset);
        }

        // Seed tags
        for (final tag in DemoData.tags) {
          await tagRepo.upsertTag(tag);
        }

        // Seed transactions (triggers tag assignment map population)
        final transactions = DemoData.transactions;
        for (final transaction in transactions) {
          await transactionRepo.upsertTransaction(transaction);
        }

        // Seed transaction-tag assignments
        for (final entry in DemoData.transactionTagAssignments.entries) {
          await db.setTagsForTransaction(entry.key, entry.value);
        }

        // Seed bills
        for (final bill in DemoData.bills) {
          await billRepo.createBill(bill);
        }

        // Seed budgets
        for (final budget in DemoData.budgets) {
          await budgetRepo.createBudget(budget);
        }

        // Seed transaction templates
        for (final template in DemoData.transactionTemplates) {
          await templateRepo.createTemplate(template);
        }

        // Seed savings goals
        for (final goal in DemoData.savingsGoals) {
          await savingsGoalRepo.createGoal(goal);
        }
      });

      // Invalidate all related providers to refresh UI
      invalidateEntityProviders(ref);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Resets the database and returns to the welcome screen.
  /// This deletes all data and sets onboardingCompleted to false.
  Future<bool> resetDatabase({bool resetSettings = false}) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseProvider);
      final settingsRepo = ref.read(settingsRepositoryProvider);

      // Delete all entity data
      await db.deleteAllData(includeSettings: resetSettings);

      // Save settings with onboardingCompleted = false
      // Do this outside the transaction to avoid conflicts
      final currentSettings = await settingsRepo.loadSettings();
      final newSettings = (currentSettings ?? const AppSettings()).copyWith(
        onboardingCompleted: false,
      );
      await settingsRepo.saveSettings(
        resetSettings ? const AppSettings() : newSettings,
      );

      // Invalidate all related providers to refresh UI
      invalidateAllDataProviders(ref);
      ref.invalidate(shouldShowWelcomeProvider);

      // Signal reset AFTER invalidating providers - this triggers _AppGate rebuild
      // while shouldShowWelcomeProvider is in loading state
      ref.read(isResettingDatabaseProvider.notifier).state = true;

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      ref.read(isResettingDatabaseProvider.notifier).state = false;
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final databaseManagementProvider =
    NotifierProvider<DatabaseManagementNotifier, AsyncValue<void>>(() {
  return DatabaseManagementNotifier();
});

/// Result of balance recalculation for a single account.
class BalanceChange {
  final String accountId;
  final String accountName;
  final String currencyCode;
  final double oldBalance;
  final double newBalance;
  final double initialBalance;
  final double transactionDelta;

  const BalanceChange({
    required this.accountId,
    required this.accountName,
    this.currencyCode = 'USD',
    required this.oldBalance,
    required this.newBalance,
    required this.initialBalance,
    required this.transactionDelta,
  });

  double get difference => newBalance - oldBalance;
  bool get hasChanged => difference.abs() > 0.001;
}

/// Result of the recalculation preview.
class RecalculatePreview {
  final List<BalanceChange> changes;
  final int totalAccounts;

  const RecalculatePreview({
    required this.changes,
    required this.totalAccounts,
  });

  List<BalanceChange> get changedAccounts =>
      changes.where((c) => c.hasChanged).toList();
  int get changedCount => changedAccounts.length;
  bool get hasChanges => changedCount > 0;
}

/// Provider for recalculating account balances from transaction history.
class RecalculateBalancesNotifier extends Notifier<AsyncValue<RecalculatePreview?>> {
  @override
  AsyncValue<RecalculatePreview?> build() {
    return const AsyncValue.data(null);
  }

  /// Calculate what changes would be made without applying them.
  Future<RecalculatePreview?> calculatePreview() async {
    state = const AsyncValue.loading();
    try {
      final accountRepo = ref.read(accountRepositoryProvider);
      final transactionRepo = ref.read(transactionRepositoryProvider);

      // Get all accounts and transactions
      final accounts = await accountRepo.getAllAccounts();
      final transactions = await transactionRepo.getAllTransactions();

      // Group transactions by account (handles income, expense, and transfers)
      final accountDeltas = calculateAccountDeltas(transactions);

      // Calculate changes for each account
      final changes = <BalanceChange>[];
      for (final account in accounts) {
        final transactionDelta = accountDeltas[account.id] ?? 0;
        final newBalance = account.initialBalance + transactionDelta;

        changes.add(BalanceChange(
          accountId: account.id,
          accountName: account.name,
          currencyCode: account.currencyCode,
          oldBalance: account.balance,
          newBalance: newBalance,
          initialBalance: account.initialBalance,
          transactionDelta: transactionDelta,
        ));
      }

      final preview = RecalculatePreview(
        changes: changes,
        totalAccounts: accounts.length,
      );

      state = AsyncValue.data(preview);
      return preview;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Apply the calculated changes.
  Future<int> applyChanges() async {
    final preview = state.valueOrNull;
    if (preview == null) return 0;

    try {
      final accountRepo = ref.read(accountRepositoryProvider);
      final allAccounts = await accountRepo.getAllAccounts();
      final accountMap = {for (final a in allAccounts) a.id: a};
      int updatedCount = 0;

      for (final change in preview.changedAccounts) {
        final account = accountMap[change.accountId];
        if (account == null) continue;
        final updatedAccount = account.copyWith(balance: change.newBalance);
        await accountRepo.updateAccount(updatedAccount);
        updatedCount++;
      }

      // Refresh accounts provider
      ref.invalidate(accountsProvider);
      ref.invalidate(databaseMetricsProvider);
      ref.invalidate(databaseConsistencyProvider);

      state = const AsyncValue.data(null);
      return updatedCount;
    } catch (e) {
      return 0;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final recalculateBalancesProvider =
    NotifierProvider<RecalculateBalancesNotifier, AsyncValue<RecalculatePreview?>>(() {
  return RecalculateBalancesNotifier();
});

/// Tracks whether a database reset is in progress.
/// When true, _AppGate will wait for shouldShowWelcomeProvider to resolve
/// instead of using cached values.
final isResettingDatabaseProvider = StateProvider<bool>((ref) => false);

/// Provider to determine if the welcome screen should be shown.
/// Returns true if onboarding is not completed AND the database is empty.
final shouldShowWelcomeProvider = FutureProvider<bool>((ref) async {
  // Check if onboarding is completed
  final onboardingCompleted = ref.watch(onboardingCompletedProvider);
  if (onboardingCompleted) {
    return false;
  }

  // Check if database is empty
  final metrics = await ref.watch(databaseMetricsProvider.future);
  return metrics.isEmpty;
});
