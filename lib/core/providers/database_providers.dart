import 'dart:io' show Platform;

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
import '../database/services/file_key_provider.dart';
import '../database/services/key_provider.dart';
import '../database/services/secure_key_provider.dart';

/// Provider for the encryption key source.
///
/// Uses SecureKeyProvider (Keychain/Keystore) on iOS/Android.
/// Falls back to FileKeyProvider on desktop platforms where
/// secure storage may not work (e.g. macOS debug builds).
final keyProviderProvider = Provider<KeyProvider>((ref) {
  if (Platform.isIOS || Platform.isAndroid) {
    return SecureKeyProvider();
  }
  return FileKeyProvider();
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
  final repo = TransactionRepository(
    database: ref.watch(databaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
  ref.onDispose(() => repo.disposeCorruptionTracker());
  return repo;
});

/// Provider for the account repository.
///
/// Combines database operations with encryption/decryption.
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final repo = AccountRepository(
    database: ref.watch(databaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
  ref.onDispose(() => repo.disposeCorruptionTracker());
  return repo;
});

/// Provider for the category repository.
///
/// Combines database operations with encryption/decryption.
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final repo = CategoryRepository(
    database: ref.watch(databaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
  ref.onDispose(() => repo.disposeCorruptionTracker());
  return repo;
});

/// Provider for the budget repository.
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final repo = BudgetRepository(
    database: ref.watch(databaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
  ref.onDispose(() => repo.disposeCorruptionTracker());
  return repo;
});

/// Provider for the asset repository.
final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  final repo = AssetRepository(
    database: ref.watch(databaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
  ref.onDispose(() => repo.disposeCorruptionTracker());
  return repo;
});

/// Provider for the asset category repository.
final assetCategoryRepositoryProvider = Provider<AssetCategoryRepository>((ref) {
  final repo = AssetCategoryRepository(
    database: ref.watch(databaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
  ref.onDispose(() => repo.disposeCorruptionTracker());
  return repo;
});

/// Provider for the recurring rule repository.
final recurringRuleRepositoryProvider = Provider<RecurringRuleRepository>((ref) {
  final repo = RecurringRuleRepository(
    database: ref.watch(databaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
  ref.onDispose(() => repo.disposeCorruptionTracker());
  return repo;
});

/// Provider for the savings goal repository.
final savingsGoalRepositoryProvider = Provider<SavingsGoalRepository>((ref) {
  final repo = SavingsGoalRepository(
    database: ref.watch(databaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
  ref.onDispose(() => repo.disposeCorruptionTracker());
  return repo;
});

/// Provider for the transaction template repository.
final transactionTemplateRepositoryProvider = Provider<TransactionTemplateRepository>((ref) {
  final repo = TransactionTemplateRepository(
    database: ref.watch(databaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
  ref.onDispose(() => repo.disposeCorruptionTracker());
  return repo;
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
  final repo = BillRepository(
    database: ref.watch(databaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
  ref.onDispose(() => repo.disposeCorruptionTracker());
  return repo;
});

/// Provider for the tag repository.
final tagRepositoryProvider = Provider<TagRepository>((ref) {
  final repo = TagRepository(
    database: ref.watch(databaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
  ref.onDispose(() => repo.disposeCorruptionTracker());
  return repo;
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

/// Startup error message to display to the user (e.g., key corruption, migration failure).
/// Null means no error.
final startupErrorProvider = StateProvider<String?>((ref) => null);

/// Whether the encryption key is corrupted (fatal — app cannot decrypt data).
final encryptionKeyCorruptedProvider = StateProvider<bool>((ref) => false);
