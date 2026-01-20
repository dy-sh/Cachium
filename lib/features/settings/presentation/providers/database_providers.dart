import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/services/database_export_service.dart';
import '../../../../core/database/services/database_import_service.dart';
import '../../../../core/database/services/database_metrics_service.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../data/demo/demo_data.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
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
      // Refresh metrics after import
      ref.invalidate(databaseMetricsProvider);
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
      // Refresh metrics after import
      ref.invalidate(databaseMetricsProvider);
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

      // Delete existing data first
      await db.deleteAllData(includeSettings: false);

      // Seed accounts
      for (final account in DemoData.accounts) {
        await accountRepo.createAccount(account);
      }

      // Seed categories (default categories)
      await categoryRepo.seedDefaultCategories();

      // Seed transactions
      for (final transaction in DemoData.transactions) {
        await transactionRepo.createTransaction(transaction);
      }

      // Invalidate all related providers to refresh UI
      ref.invalidate(accountsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(databaseMetricsProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
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
