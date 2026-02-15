import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/account_repository.dart';
import '../../data/repositories/asset_repository.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../database/app_database.dart';
import '../database/services/encryption_service.dart';
import '../database/services/key_provider.dart';

/// Provider for the encryption key source.
///
/// In Stage 1, this uses MockKeyProvider with a hardcoded key.
/// In Stage 2, this will be replaced with SecureKeyProvider.
final keyProviderProvider = Provider<KeyProvider>((ref) {
  return MockKeyProvider();
});

/// Provider for the encryption service.
///
/// Uses AES-256-GCM for encrypting transaction data before storage.
final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService(ref.watch(keyProviderProvider));
});

/// Provider for the main application database.
///
/// The database is created lazily on first access and closed when
/// the provider is disposed.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Provider for the transaction repository.
///
/// Combines database operations with encryption/decryption.
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(
    database: ref.watch(databaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
});

/// Provider for the account repository.
///
/// Combines database operations with encryption/decryption.
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(
    database: ref.watch(databaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
});

/// Provider for the category repository.
///
/// Combines database operations with encryption/decryption.
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(
    database: ref.watch(databaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
});

/// Provider for the budget repository.
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(
    database: ref.watch(databaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
});

/// Provider for the asset repository.
final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository(
    database: ref.watch(databaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
});

/// Provider for the settings repository.
///
/// Settings are stored as unencrypted JSON.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(
    database: ref.watch(databaseProvider),
  );
});
