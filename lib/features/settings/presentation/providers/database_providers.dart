import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/services/database_consistency_service.dart';
import '../../../../core/database/services/database_export_service.dart';
import '../../../../core/database/services/database_import_service.dart';
import '../../../../core/database/services/database_metrics_service.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../data/demo/demo_data.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/app_settings.dart';
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
      debugPrint('Export to SQLite failed: $e');
      debugPrint('Stack trace: $st');
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
      debugPrint('Export to CSV failed: $e');
      debugPrint('Stack trace: $st');
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

  Future<void> importFromSqlite() async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(databaseImportServiceProvider);
      final result = await service.pickAndImportSqlite();
      state = AsyncValue.data(result);

      // Invalidate all data providers to refresh UI
      ref.invalidate(accountsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(settingsProvider);
      ref.invalidate(databaseMetricsProvider);
      ref.invalidate(databaseConsistencyProvider);
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
      ref.invalidate(accountsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(settingsProvider);
      ref.invalidate(databaseMetricsProvider);
      ref.invalidate(databaseConsistencyProvider);
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
        ref.read(settingsProvider.notifier).reset();
      }

      // Invalidate all related providers to refresh UI
      ref.invalidate(accountsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(databaseMetricsProvider);
      ref.invalidate(databaseConsistencyProvider);

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

      // Wrap all database operations in a transaction to prevent locking
      await db.transaction(() async {
        // Delete existing data first
        await db.deleteAllTransactions();
        await db.deleteAllAccounts();
        await db.deleteAllCategories();

        // Seed accounts (use upsert to handle duplicates)
        for (final account in DemoData.accounts) {
          await accountRepo.upsertAccount(account);
        }

        // Seed categories (default categories - uses upsert internally)
        await categoryRepo.seedDefaultCategories();

        // Seed transactions (use upsert to handle duplicates)
        for (final transaction in DemoData.transactions) {
          await transactionRepo.upsertTransaction(transaction);
        }
      });

      // Invalidate all related providers to refresh UI
      ref.invalidate(accountsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(databaseMetricsProvider);
      ref.invalidate(databaseConsistencyProvider);

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

      // Wrap all database operations in a single transaction
      await db.transaction(() async {
        // Delete all entity data
        await db.deleteAllTransactions();
        await db.deleteAllAccounts();
        await db.deleteAllCategories();

        if (resetSettings) {
          await db.deleteAllSettings();
        }
      });

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
      ref.invalidate(accountsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(settingsProvider);
      ref.invalidate(databaseMetricsProvider);
      ref.invalidate(databaseConsistencyProvider);
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
  final double oldBalance;
  final double newBalance;
  final double initialBalance;
  final double transactionDelta;

  const BalanceChange({
    required this.accountId,
    required this.accountName,
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

      // Group transactions by account
      final Map<String, double> accountDeltas = {};
      for (final tx in transactions) {
        final delta = tx.type.name == 'income' ? tx.amount : -tx.amount;
        accountDeltas[tx.accountId] = (accountDeltas[tx.accountId] ?? 0) + delta;
      }

      // Calculate changes for each account
      final changes = <BalanceChange>[];
      for (final account in accounts) {
        final transactionDelta = accountDeltas[account.id] ?? 0;
        final newBalance = account.initialBalance + transactionDelta;

        changes.add(BalanceChange(
          accountId: account.id,
          accountName: account.name,
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
      int updatedCount = 0;

      for (final change in preview.changedAccounts) {
        final account = (await accountRepo.getAllAccounts())
            .firstWhere((a) => a.id == change.accountId);
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
  final isEmpty = metrics.accountCount == 0 &&
      metrics.categoryCount == 0 &&
      metrics.transactionCount == 0;

  return isEmpty;
});
