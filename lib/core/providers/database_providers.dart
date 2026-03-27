import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/account_repository.dart';
import '../../data/repositories/asset_repository.dart';
import '../../data/repositories/asset_category_repository.dart';
import '../../data/repositories/bill_repository.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/net_worth_snapshot_repository.dart';
import '../../data/repositories/recurring_rule_repository.dart';
import '../../data/repositories/savings_goal_repository.dart';
import '../../data/repositories/attachment_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/tag_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/transaction_template_repository.dart';
import '../database/app_database.dart';
import '../database/services/encryption_service.dart';
import '../database/services/key_provider.dart';
import '../database/services/secure_key_provider.dart';

/// Provider for the encryption key source.
///
/// Uses SecureKeyProvider backed by platform-specific secure storage
/// (Keychain on iOS, Keystore on Android).
final keyProviderProvider = Provider<KeyProvider>((ref) {
  return SecureKeyProvider();
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

/// Provider for the asset category repository.
final assetCategoryRepositoryProvider = Provider<AssetCategoryRepository>((ref) {
  return AssetCategoryRepository(
    database: ref.watch(databaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
});

/// Provider for the recurring rule repository.
final recurringRuleRepositoryProvider = Provider<RecurringRuleRepository>((ref) {
  return RecurringRuleRepository(
    database: ref.watch(databaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
});

/// Provider for the savings goal repository.
final savingsGoalRepositoryProvider = Provider<SavingsGoalRepository>((ref) {
  return SavingsGoalRepository(
    database: ref.watch(databaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
});

/// Provider for the transaction template repository.
final transactionTemplateRepositoryProvider = Provider<TransactionTemplateRepository>((ref) {
  return TransactionTemplateRepository(
    database: ref.watch(databaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
});

/// Provider for the attachment repository.
final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  return AttachmentRepository(
    database: ref.watch(databaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
});

/// Provider for the bill repository.
final billRepositoryProvider = Provider<BillRepository>((ref) {
  return BillRepository(
    database: ref.watch(databaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
});

/// Provider for the tag repository.
final tagRepositoryProvider = Provider<TagRepository>((ref) {
  return TagRepository(
    database: ref.watch(databaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
});

/// Provider for the net worth snapshot repository.
final netWorthSnapshotRepositoryProvider = Provider<NetWorthSnapshotRepository>((ref) {
  return NetWorthSnapshotRepository(
    database: ref.watch(databaseProvider),
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
