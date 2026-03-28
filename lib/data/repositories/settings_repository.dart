import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/database/app_database.dart' as db;
import '../../features/settings/data/models/app_settings.dart' as ui;
import '../../features/transactions/data/models/transaction.dart';
import '../encryption/settings_data.dart';

/// Repository for managing app settings storage.
///
/// Converts between UI AppSettings and database records.
/// Settings are stored as unencrypted JSON. Security credentials
/// (PIN/password hashes) are stored in platform secure storage
/// (Keychain on iOS, Keystore on Android), not in the database.
class SettingsRepository {
  final db.AppDatabase database;
  final FlutterSecureStorage _secureStorage;

  /// Fixed ID for the single settings row
  static const String settingsId = 'app_settings';

  /// Secure storage keys for credentials
  static const String _pinKey = 'cachium_app_pin_code';
  static const String _passwordKey = 'cachium_app_password';

  SettingsRepository({
    required this.database,
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  /// Convert UI AppSettings to internal SettingsData for storage
  SettingsData _toData(ui.AppSettings settings) {
    return SettingsData(
      id: settingsId,
      themeMode: settings.themeMode.name,
      colorIntensity: settings.colorIntensity.name,
      accentColorIndex: settings.accentColorIndex,
      accountCardStyle: settings.accountCardStyle.name,
      tabTransitionsEnabled: settings.tabTransitionsEnabled,
      formAnimationsEnabled: settings.formAnimationsEnabled,
      balanceCountersEnabled: settings.balanceCountersEnabled,
      dateFormat: settings.dateFormat.name,
      mainCurrencyCode: settings.mainCurrencyCode,
      exchangeRateApiOption: settings.exchangeRateApiOption.name,
      cachedExchangeRates: settings.cachedExchangeRates,
      lastRateFetchTimestamp: settings.lastRateFetchTimestamp,
      firstDayOfWeek: settings.firstDayOfWeek.name,
      hapticFeedbackEnabled: settings.hapticFeedbackEnabled,
      startScreen: settings.startScreen.name,
      lastUsedAccountId: settings.lastUsedAccountId,
      autoCategorizeByMerchant: settings.autoCategorizeByMerchant,
      selectLastCategory: settings.selectLastCategory,
      selectLastAccount: settings.selectLastAccount,
      accountsFoldedCount: settings.accountsFoldedCount,
      categoriesFoldedCount: settings.categoriesFoldedCount,
      showAddAccountButton: settings.showAddAccountButton,
      showAddCategoryButton: settings.showAddCategoryButton,
      defaultTransactionType: settings.defaultTransactionType.name,
      allowZeroAmount: settings.allowZeroAmount,
      categorySortOption: settings.categorySortOption.name,
      lastUsedIncomeCategoryId: settings.lastUsedIncomeCategoryId,
      lastUsedExpenseCategoryId: settings.lastUsedExpenseCategoryId,
      appLockEnabled: settings.appLockEnabled,
      // Credentials stored in secure storage, not in database
      appPinCode: null,
      appPassword: null,
      autoLockTimeout: settings.autoLockTimeout.name,
      biometricUnlockEnabled: settings.biometricUnlockEnabled,
      notificationsEnabled: settings.notificationsEnabled,
      budgetAlertThresholds: settings.budgetAlertThresholds,
      recurringRemindersEnabled: settings.recurringRemindersEnabled,
      recurringReminderAdvanceDays: settings.recurringReminderAdvanceDays,
      weeklySpendingSummaryEnabled: settings.weeklySpendingSummaryEnabled,
      weeklySpendingSummaryDay: settings.weeklySpendingSummaryDay,
      encryptAttachments: settings.encryptAttachments,
      homeShowBudgetProgress: settings.homeShowBudgetProgress,
      homeSectionOrder: settings.homeSectionOrder,
      tutorialCompleted: settings.tutorialCompleted,
    );
  }

  /// Convert internal SettingsData to UI AppSettings
  ui.AppSettings _toSettings(SettingsData data) {
    return ui.AppSettings(
      themeMode: ui.ThemeModeOption.values.firstWhere(
        (e) => e.name == data.themeMode,
        orElse: () => ui.ThemeModeOption.dark,
      ),
      colorIntensity: ui.ColorIntensity.values.firstWhere(
        (e) => e.name == data.colorIntensity,
        orElse: () => ui.ColorIntensity.prism,
      ),
      accentColorIndex: data.accentColorIndex,
      accountCardStyle: ui.AccountCardStyle.values.firstWhere(
        (e) => e.name == data.accountCardStyle,
        orElse: () => ui.AccountCardStyle.dim,
      ),
      tabTransitionsEnabled: data.tabTransitionsEnabled,
      formAnimationsEnabled: data.formAnimationsEnabled,
      balanceCountersEnabled: data.balanceCountersEnabled,
      dateFormat: ui.DateFormatOption.values.firstWhere(
        (e) => e.name == data.dateFormat,
        orElse: () => ui.DateFormatOption.mmddyyyy,
      ),
      mainCurrencyCode: data.mainCurrencyCode,
      exchangeRateApiOption: ui.ExchangeRateApiOption.values.firstWhere(
        (e) => e.name == data.exchangeRateApiOption,
        orElse: () => ui.ExchangeRateApiOption.frankfurter,
      ),
      cachedExchangeRates: data.cachedExchangeRates,
      lastRateFetchTimestamp: data.lastRateFetchTimestamp,
      firstDayOfWeek: ui.FirstDayOfWeek.values.firstWhere(
        (e) => e.name == data.firstDayOfWeek,
        orElse: () => ui.FirstDayOfWeek.sunday,
      ),
      hapticFeedbackEnabled: data.hapticFeedbackEnabled,
      startScreen: ui.StartScreen.values.firstWhere(
        (e) => e.name == data.startScreen,
        orElse: () => ui.StartScreen.home,
      ),
      lastUsedAccountId: data.lastUsedAccountId,
      autoCategorizeByMerchant: data.autoCategorizeByMerchant,
      selectLastCategory: data.selectLastCategory,
      selectLastAccount: data.selectLastAccount,
      accountsFoldedCount: data.accountsFoldedCount,
      categoriesFoldedCount: data.categoriesFoldedCount,
      showAddAccountButton: data.showAddAccountButton,
      showAddCategoryButton: data.showAddCategoryButton,
      defaultTransactionType: TransactionType.values.firstWhere(
        (e) => e.name == data.defaultTransactionType,
        orElse: () => TransactionType.expense,
      ),
      allowZeroAmount: data.allowZeroAmount,
      categorySortOption: ui.CategorySortOption.values.firstWhere(
        (e) => e.name == data.categorySortOption,
        orElse: () => ui.CategorySortOption.lastUsed,
      ),
      lastUsedIncomeCategoryId: data.lastUsedIncomeCategoryId,
      lastUsedExpenseCategoryId: data.lastUsedExpenseCategoryId,
      appLockEnabled: data.appLockEnabled,
      // Credentials loaded from secure storage in loadSettings()
      appPinCode: null,
      appPassword: null,
      autoLockTimeout: ui.AutoLockTimeout.values.firstWhere(
        (e) => e.name == data.autoLockTimeout,
        orElse: () => ui.AutoLockTimeout.immediate,
      ),
      biometricUnlockEnabled: data.biometricUnlockEnabled,
      notificationsEnabled: data.notificationsEnabled,
      budgetAlertThresholds: data.budgetAlertThresholds,
      recurringRemindersEnabled: data.recurringRemindersEnabled,
      recurringReminderAdvanceDays: data.recurringReminderAdvanceDays,
      weeklySpendingSummaryEnabled: data.weeklySpendingSummaryEnabled,
      weeklySpendingSummaryDay: data.weeklySpendingSummaryDay,
      encryptAttachments: data.encryptAttachments,
      homeShowBudgetProgress: data.homeShowBudgetProgress,
      homeSectionOrder: data.homeSectionOrder,
      tutorialCompleted: data.tutorialCompleted,
    );
  }

  /// Save settings to database (insert or update).
  /// Credentials are saved to secure storage, not the database.
  Future<void> saveSettings(ui.AppSettings settings) async {
    final data = _toData(settings);
    final jsonData = jsonEncode(data.toJson());

    await database.upsertSettings(
      id: settingsId,
      lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      jsonData: jsonData,
    );

    // Save credentials to secure storage
    await _saveCredentials(settings.appPinCode, settings.appPassword);
  }

  /// Load settings from database.
  /// Credentials are loaded from secure storage and merged in.
  /// Returns null if no settings exist (first run).
  Future<ui.AppSettings?> loadSettings() async {
    final row = await database.getSettings(settingsId);
    if (row == null) return null;

    final json = jsonDecode(row.jsonData) as Map<String, dynamic>;
    final data = SettingsData.fromJson(json);

    // Migrate credentials from DB to secure storage if present
    await _migrateCredentialsFromDb(json);

    var settings = _toSettings(data);

    // Merge credentials from secure storage
    final pin = await _secureStorage.read(key: _pinKey);
    final password = await _secureStorage.read(key: _passwordKey);
    settings = settings.copyWith(
      appPinCode: pin,
      appPassword: password,
    );

    return settings;
  }

  /// One-time migration: move credentials from DB JSON to secure storage,
  /// then clear them from the database.
  Future<void> _migrateCredentialsFromDb(Map<String, dynamic> json) async {
    final dbPin = json['appPinCode'] as String?;
    final dbPassword = json['appPassword'] as String?;

    if (dbPin == null && dbPassword == null) return;

    // Only migrate if secure storage doesn't already have values
    final existingPin = await _secureStorage.read(key: _pinKey);
    final existingPassword = await _secureStorage.read(key: _passwordKey);

    bool pinMigrated = dbPin == null || existingPin != null;
    bool passwordMigrated = dbPassword == null || existingPassword != null;

    if (dbPin != null && existingPin == null) {
      try {
        await _secureStorage.write(key: _pinKey, value: dbPin);
        pinMigrated = true;
      } catch (_) {
        debugPrint('SettingsRepository: PIN migration to secure storage failed');
      }
    }

    if (dbPassword != null && existingPassword == null) {
      try {
        await _secureStorage.write(key: _passwordKey, value: dbPassword);
        passwordMigrated = true;
      } catch (_) {
        debugPrint('SettingsRepository: password migration to secure storage failed');
      }
    }

    // Only clear from DB the credentials that were successfully written
    if (pinMigrated) json.remove('appPinCode');
    if (passwordMigrated) json.remove('appPassword');

    if (pinMigrated || passwordMigrated) {
      try {
        final cleanJsonData = jsonEncode(json);
        await database.upsertSettings(
          id: settingsId,
          lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
          jsonData: cleanJsonData,
        );
        debugPrint('SettingsRepository: migrated credentials from DB to secure storage');
      } catch (_) {
        // DB update failed — credentials are duplicated but safe. Will retry next launch.
        debugPrint('SettingsRepository: DB cleanup after migration failed');
      }
    }
  }

  /// Save credentials to secure storage.
  Future<void> _saveCredentials(String? pin, String? password) async {
    if (pin != null) {
      await _secureStorage.write(key: _pinKey, value: pin);
    } else {
      await _secureStorage.delete(key: _pinKey);
    }
    if (password != null) {
      await _secureStorage.write(key: _passwordKey, value: password);
    } else {
      await _secureStorage.delete(key: _passwordKey);
    }
  }

  /// Check if settings exist in database
  Future<bool> hasSettings() async {
    return database.hasSettings(settingsId);
  }
}
