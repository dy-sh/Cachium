import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/accounts/presentation/providers/accounts_provider.dart';
import '../../features/categories/presentation/providers/categories_provider.dart';
import '../../features/settings/presentation/providers/database_management_providers.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';
import '../../features/transactions/presentation/providers/transactions_provider.dart';

/// Invalidates all data providers to refresh UI after database changes.
///
/// Use this after operations that modify multiple entities like:
/// - Import operations (SQLite/CSV)
/// - Database reset/delete
/// - Demo data creation
void invalidateAllDataProviders(Ref ref) {
  ref.invalidate(accountsProvider);
  ref.invalidate(transactionsProvider);
  ref.invalidate(categoriesProvider);
  ref.invalidate(settingsProvider);
  ref.invalidate(databaseMetricsProvider);
  ref.invalidate(databaseConsistencyProvider);
}

/// Invalidates entity data providers only (accounts, transactions, categories).
///
/// Use this after operations that modify entity data but not settings.
void invalidateEntityProviders(Ref ref) {
  ref.invalidate(accountsProvider);
  ref.invalidate(transactionsProvider);
  ref.invalidate(categoriesProvider);
  ref.invalidate(databaseMetricsProvider);
  ref.invalidate(databaseConsistencyProvider);
}
