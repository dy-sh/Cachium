import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/utils/credential_hasher.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../data/models/app_settings.dart';

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final repo = ref.watch(settingsRepositoryProvider);

    // Load existing settings from database
    final settings = await repo.loadSettings();

    if (settings != null) {
      return settings;
    }

    // First run - return defaults and save them
    const defaultSettings = AppSettings();
    await repo.saveSettings(defaultSettings);
    return defaultSettings;
  }

  Future<void> _saveAndUpdate(AppSettings newSettings) async {
    final previousState = state;
    try {
      final repo = ref.read(settingsRepositoryProvider);
      state = AsyncData(newSettings);
      await repo.saveSettings(newSettings);
    } catch (e, st) {
      state = previousState;
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> _update(AppSettings Function(AppSettings s) updater) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(updater(current));
  }

  // Appearance
  Future<void> setThemeMode(ThemeModeOption v) => _update((s) => s.copyWith(themeMode: v));
  Future<void> setColorIntensity(ColorIntensity v) => _update((s) => s.copyWith(colorIntensity: v));
  Future<void> setAccentColorIndex(int v) => _update((s) => s.copyWith(accentColorIndex: v));
  Future<void> setAccountCardStyle(AccountCardStyle v) => _update((s) => s.copyWith(accountCardStyle: v));
  Future<void> setTabTransitionsEnabled(bool v) => _update((s) => s.copyWith(tabTransitionsEnabled: v));
  Future<void> setFormAnimationsEnabled(bool v) => _update((s) => s.copyWith(formAnimationsEnabled: v));
  Future<void> setBalanceCountersEnabled(bool v) => _update((s) => s.copyWith(balanceCountersEnabled: v));

  // Formats
  Future<void> setDateFormat(DateFormatOption v) => _update((s) => s.copyWith(dateFormat: v));
  Future<void> setMainCurrencyCode(String v) => _update((s) => s.copyWith(mainCurrencyCode: v));
  Future<void> setExchangeRateApiOption(ExchangeRateApiOption v) => _update((s) => s.copyWith(exchangeRateApiOption: v));
  Future<void> setLastRateFetchTimestamp(int v) => _update((s) => s.copyWith(lastRateFetchTimestamp: v));
  Future<void> setFirstDayOfWeek(FirstDayOfWeek v) => _update((s) => s.copyWith(firstDayOfWeek: v));

  Future<void> setCachedExchangeRates(String? json) async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (json == null) {
      await _saveAndUpdate(current.copyWith(clearCachedExchangeRates: true));
    } else {
      await _saveAndUpdate(current.copyWith(cachedExchangeRates: json));
    }
  }

  // Preferences
  Future<void> setHapticFeedbackEnabled(bool v) => _update((s) => s.copyWith(hapticFeedbackEnabled: v));
  Future<void> setStartScreen(StartScreen v) => _update((s) => s.copyWith(startScreen: v));
  Future<void> setLastUsedAccountId(String? v) => _update((s) => s.copyWith(lastUsedAccountId: v));

  // Transactions
  Future<void> setSelectLastCategory(bool v) => _update((s) => s.copyWith(selectLastCategory: v));
  Future<void> setSelectLastAccount(bool v) => _update((s) => s.copyWith(selectLastAccount: v));
  Future<void> setAccountsFoldedCount(int v) => _update((s) => s.copyWith(accountsFoldedCount: v));
  Future<void> setCategoriesFoldedCount(int v) => _update((s) => s.copyWith(categoriesFoldedCount: v));
  Future<void> setCategorySortOption(CategorySortOption v) => _update((s) => s.copyWith(categorySortOption: v));
  Future<void> setShowAddAccountButton(bool v) => _update((s) => s.copyWith(showAddAccountButton: v));
  Future<void> setShowAddCategoryButton(bool v) => _update((s) => s.copyWith(showAddCategoryButton: v));
  Future<void> setDefaultTransactionType(TransactionType v) => _update((s) => s.copyWith(defaultTransactionType: v));
  Future<void> setAllowZeroAmount(bool v) => _update((s) => s.copyWith(allowZeroAmount: v));
  Future<void> setTransactionAmountSize(AmountDisplaySize v) => _update((s) => s.copyWith(transactionAmountSize: v));
  Future<void> setAllowSelectParentCategory(bool v) => _update((s) => s.copyWith(allowSelectParentCategory: v));

  Future<void> setLastUsedCategoryId(TransactionType type, String? categoryId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (type == TransactionType.income) {
      await _saveAndUpdate(current.copyWith(lastUsedIncomeCategoryId: categoryId));
    } else {
      await _saveAndUpdate(current.copyWith(lastUsedExpenseCategoryId: categoryId));
    }
  }

  // Assets
  Future<void> setAssetsFoldedCount(int v) => _update((s) => s.copyWith(assetsFoldedCount: v));
  Future<void> setShowAddAssetButton(bool v) => _update((s) => s.copyWith(showAddAssetButton: v));
  Future<void> setAssetSortOption(AssetSortOption v) => _update((s) => s.copyWith(assetSortOption: v));
  Future<void> setShowAssetSelector(bool v) => _update((s) => s.copyWith(showAssetSelector: v));

  // Home Page
  Future<void> setHomeShowAccountsList(bool v) => _update((s) => s.copyWith(homeShowAccountsList: v));
  Future<void> setHomeShowTotalBalance(bool v) => _update((s) => s.copyWith(homeShowTotalBalance: v));
  Future<void> setHomeShowQuickActions(bool v) => _update((s) => s.copyWith(homeShowQuickActions: v));
  Future<void> setHomeShowRecentTransactions(bool v) => _update((s) => s.copyWith(homeShowRecentTransactions: v));
  Future<void> setHomeShowBudgetProgress(bool v) => _update((s) => s.copyWith(homeShowBudgetProgress: v));
  Future<void> setHomeSectionOrder(List<String> v) => _update((s) => s.copyWith(homeSectionOrder: v));
  Future<void> setHomeAccountsTextSize(AmountDisplaySize v) => _update((s) => s.copyWith(homeAccountsTextSize: v));
  Future<void> setHomeTotalBalanceTextSize(AmountDisplaySize v) => _update((s) => s.copyWith(homeTotalBalanceTextSize: v));
  Future<void> setHomeBalancesHiddenByDefault(bool v) => _update((s) => s.copyWith(homeBalancesHiddenByDefault: v));

  // Notifications
  Future<void> setNotificationsEnabled(bool v) => _update((s) => s.copyWith(notificationsEnabled: v));
  Future<void> setBudgetAlertThresholds(List<int> v) => _update((s) => s.copyWith(budgetAlertThresholds: v));
  Future<void> setRecurringRemindersEnabled(bool v) => _update((s) => s.copyWith(recurringRemindersEnabled: v));
  Future<void> setRecurringReminderAdvanceDays(int v) => _update((s) => s.copyWith(recurringReminderAdvanceDays: v));
  Future<void> setWeeklySpendingSummaryEnabled(bool v) => _update((s) => s.copyWith(weeklySpendingSummaryEnabled: v));
  Future<void> setWeeklySpendingSummaryDay(int v) => _update((s) => s.copyWith(weeklySpendingSummaryDay: v));

  // Security
  Future<void> setAppLockEnabled(bool v) => _update((s) => s.copyWith(appLockEnabled: v));
  Future<void> setAutoLockTimeout(AutoLockTimeout v) => _update((s) => s.copyWith(autoLockTimeout: v));
  Future<void> setBiometricUnlockEnabled(bool v) => _update((s) => s.copyWith(biometricUnlockEnabled: v));

  Future<void> setAppPinCode(String? pin) async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (pin == null) {
      await _saveAndUpdate(current.copyWith(clearAppPinCode: true));
    } else {
      final hashed = await CredentialHasher.hash(pin);
      await _saveAndUpdate(current.copyWith(appPinCode: hashed));
    }
  }

  Future<void> setAppPassword(String? password) async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (password == null) {
      await _saveAndUpdate(current.copyWith(clearAppPassword: true));
    } else {
      final hashed = await CredentialHasher.hash(password);
      await _saveAndUpdate(current.copyWith(appPassword: hashed));
    }
  }

  /// Re-hash a credential to PBKDF2 after successful verification.
  /// Called from lock screen when the raw credential is available.
  Future<void> upgradeCredentialIfNeeded({
    String? rawPin,
    String? rawPassword,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;

    var needsSave = false;
    var updated = current;

    if (rawPin != null &&
        current.appPinCode != null &&
        CredentialHasher.needsUpgrade(current.appPinCode!)) {
      final hashed = await CredentialHasher.hash(rawPin);
      updated = updated.copyWith(appPinCode: hashed);
      needsSave = true;
    }

    if (rawPassword != null &&
        current.appPassword != null &&
        CredentialHasher.needsUpgrade(current.appPassword!)) {
      final hashed = await CredentialHasher.hash(rawPassword);
      updated = updated.copyWith(appPassword: hashed);
      needsSave = true;
    }

    if (needsSave) {
      try {
        await _saveAndUpdate(updated);
      } catch (_) {
        // Silent failure — old format still works
      }
    }
  }

  /// Migrate credentials to current hashing format (PBKDF2).
  /// Handles: plaintext → PBKDF2, sha256 → PBKDF2.
  /// Called once on app startup if needed.
  Future<void> migrateCredentialsIfNeeded() async {
    final current = state.valueOrNull;
    if (current == null) return;

    var needsSave = false;
    var updated = current;

    if (current.appPinCode != null && !CredentialHasher.isPbkdf2(current.appPinCode!)) {
      if (CredentialHasher.isHashed(current.appPinCode!)) {
        // sha256 format — we can't reverse the hash, so credential must be
        // re-entered by the user. Skip migration for sha256 (it still verifies).
      } else {
        // Plaintext — migrate to PBKDF2
        final hashed = await CredentialHasher.hash(current.appPinCode!);
        updated = updated.copyWith(appPinCode: hashed);
        needsSave = true;
      }
    }

    if (current.appPassword != null && !CredentialHasher.isPbkdf2(current.appPassword!)) {
      if (CredentialHasher.isHashed(current.appPassword!)) {
        // sha256 format — can't reverse, skip (still verifies correctly)
      } else {
        // Plaintext — migrate to PBKDF2
        final hashed = await CredentialHasher.hash(current.appPassword!);
        updated = updated.copyWith(appPassword: hashed);
        needsSave = true;
      }
    }

    if (needsSave) {
      await _saveAndUpdate(updated);
    }
  }

  // Onboarding
  Future<void> setTutorialCompleted(bool v) => _update((s) => s.copyWith(tutorialCompleted: v));

  Future<void> setOnboardingCompleted(bool completed) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(onboardingCompleted: completed));
  }

  /// Refresh settings from database
  Future<void> refresh() async {
    final repo = ref.read(settingsRepositoryProvider);
    final settings = await repo.loadSettings();
    state = AsyncData(settings ?? const AppSettings());
  }

  /// Reset settings to defaults
  Future<void> reset() async {
    const defaultSettings = AppSettings();
    await _saveAndUpdate(defaultSettings);
  }

  /// Reset only settings section (Appearance, Formats, Preferences, Transactions)
  /// Preserves onboardingCompleted
  Future<void> resetSettingsSection() async {
    final current = state.valueOrNull;
    if (current == null) return;

    const defaults = AppSettings();
    final resetSettings = AppSettings(
      // Reset Appearance
      themeMode: defaults.themeMode,
      colorIntensity: defaults.colorIntensity,
      accentColorIndex: defaults.accentColorIndex,
      accountCardStyle: defaults.accountCardStyle,
      tabTransitionsEnabled: defaults.tabTransitionsEnabled,
      formAnimationsEnabled: defaults.formAnimationsEnabled,
      balanceCountersEnabled: defaults.balanceCountersEnabled,
      // Reset Formats
      dateFormat: defaults.dateFormat,
      mainCurrencyCode: defaults.mainCurrencyCode,
      exchangeRateApiOption: defaults.exchangeRateApiOption,
      cachedExchangeRates: defaults.cachedExchangeRates,
      lastRateFetchTimestamp: defaults.lastRateFetchTimestamp,
      firstDayOfWeek: defaults.firstDayOfWeek,
      // Reset Preferences
      hapticFeedbackEnabled: defaults.hapticFeedbackEnabled,
      startScreen: defaults.startScreen,
      lastUsedAccountId: defaults.lastUsedAccountId,
      // Reset Transactions
      selectLastCategory: defaults.selectLastCategory,
      selectLastAccount: defaults.selectLastAccount,
      accountsFoldedCount: defaults.accountsFoldedCount,
      categoriesFoldedCount: defaults.categoriesFoldedCount,
      showAddAccountButton: defaults.showAddAccountButton,
      showAddCategoryButton: defaults.showAddCategoryButton,
      defaultTransactionType: defaults.defaultTransactionType,
      allowZeroAmount: defaults.allowZeroAmount,
      categorySortOption: defaults.categorySortOption,
      lastUsedIncomeCategoryId: defaults.lastUsedIncomeCategoryId,
      lastUsedExpenseCategoryId: defaults.lastUsedExpenseCategoryId,
      transactionAmountSize: defaults.transactionAmountSize,
      allowSelectParentCategory: defaults.allowSelectParentCategory,
      // Reset Assets
      assetsFoldedCount: defaults.assetsFoldedCount,
      showAddAssetButton: defaults.showAddAssetButton,
      assetSortOption: defaults.assetSortOption,
      showAssetSelector: defaults.showAssetSelector,
      // Reset Home Page
      homeShowAccountsList: defaults.homeShowAccountsList,
      homeShowTotalBalance: defaults.homeShowTotalBalance,
      homeShowQuickActions: defaults.homeShowQuickActions,
      homeShowRecentTransactions: defaults.homeShowRecentTransactions,
      homeShowBudgetProgress: defaults.homeShowBudgetProgress,
      homeSectionOrder: defaults.homeSectionOrder,
      homeAccountsTextSize: defaults.homeAccountsTextSize,
      homeTotalBalanceTextSize: defaults.homeTotalBalanceTextSize,
      homeBalancesHiddenByDefault: defaults.homeBalancesHiddenByDefault,
      // Reset Security
      appLockEnabled: defaults.appLockEnabled,
      appPinCode: defaults.appPinCode,
      appPassword: defaults.appPassword,
      autoLockTimeout: defaults.autoLockTimeout,
      biometricUnlockEnabled: defaults.biometricUnlockEnabled,
      // Preserve onboarding
      onboardingCompleted: current.onboardingCompleted,
      tutorialCompleted: current.tutorialCompleted,
    );
    await _saveAndUpdate(resetSettings);
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});

// Convenience providers
final themeModeProvider = Provider<ThemeModeOption>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.themeMode ?? ThemeModeOption.dark;
});

final colorIntensityProvider = Provider<ColorIntensity>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.colorIntensity ?? ColorIntensity.prism;
});

final accentColorProvider = Provider<Color>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.accentColor ?? const AppSettings().accentColor;
});

final accountCardStyleProvider = Provider<AccountCardStyle>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.accountCardStyle ?? AccountCardStyle.dim;
});

final dateFormatProvider = Provider<DateFormatOption>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.dateFormat ?? DateFormatOption.mmddyyyy;
});

final mainCurrencyCodeProvider = Provider<String>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.mainCurrencyCode ?? 'USD';
});

final exchangeRateApiOptionProvider = Provider<ExchangeRateApiOption>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.exchangeRateApiOption ?? ExchangeRateApiOption.frankfurter;
});

final firstDayOfWeekProvider = Provider<FirstDayOfWeek>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.firstDayOfWeek ?? FirstDayOfWeek.sunday;
});

final hapticEnabledProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.hapticFeedbackEnabled ?? true;
});

final tabTransitionsEnabledProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.tabTransitionsEnabled ?? true;
});

final formAnimationsEnabledProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.formAnimationsEnabled ?? true;
});

final balanceCountersEnabledProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.balanceCountersEnabled ?? true;
});

final startScreenProvider = Provider<StartScreen>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.startScreen ?? StartScreen.home;
});

final lastUsedAccountIdProvider = Provider<String?>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.lastUsedAccountId;
});

final onboardingCompletedProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.onboardingCompleted ?? false;
});

final tutorialCompletedProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.tutorialCompleted ?? false;
});

// Transaction settings providers
final selectLastCategoryProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.selectLastCategory ?? false;
});

final selectLastAccountProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.selectLastAccount ?? true;
});

final accountsFoldedCountProvider = Provider<int>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.accountsFoldedCount ?? 3;
});

final categoriesFoldedCountProvider = Provider<int>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.categoriesFoldedCount ?? 5;
});

final categorySortOptionProvider = Provider<CategorySortOption>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.categorySortOption ?? CategorySortOption.lastUsed;
});

final showAddAccountButtonProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.showAddAccountButton ?? true;
});

final showAddCategoryButtonProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.showAddCategoryButton ?? true;
});

final defaultTransactionTypeProvider = Provider<TransactionType>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.defaultTransactionType ?? TransactionType.expense;
});

final allowZeroAmountProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.allowZeroAmount ?? true;
});

final lastUsedIncomeCategoryIdProvider = Provider<String?>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.lastUsedIncomeCategoryId;
});

final lastUsedExpenseCategoryIdProvider = Provider<String?>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.lastUsedExpenseCategoryId;
});

final transactionAmountSizeProvider = Provider<AmountDisplaySize>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.transactionAmountSize ?? AmountDisplaySize.large;
});

final allowSelectParentCategoryProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.allowSelectParentCategory ?? true;
});

// Home Page providers
final homeShowAccountsListProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.homeShowAccountsList ?? true;
});

final homeShowTotalBalanceProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.homeShowTotalBalance ?? true;
});

final homeShowQuickActionsProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.homeShowQuickActions ?? true;
});

final homeShowRecentTransactionsProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.homeShowRecentTransactions ?? true;
});

final homeAccountsTextSizeProvider = Provider<AmountDisplaySize>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.homeAccountsTextSize ?? AmountDisplaySize.large;
});

final homeTotalBalanceTextSizeProvider = Provider<AmountDisplaySize>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.homeTotalBalanceTextSize ?? AmountDisplaySize.large;
});

final homeBalancesHiddenByDefaultProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.homeBalancesHiddenByDefault ?? false;
});

// Asset settings providers
final assetsFoldedCountProvider = Provider<int>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.assetsFoldedCount ?? 5;
});

final showAddAssetButtonProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.showAddAssetButton ?? true;
});

final assetSortOptionProvider = Provider<AssetSortOption>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.assetSortOption ?? AssetSortOption.lastUsed;
});

final showAssetSelectorProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.showAssetSelector ?? true;
});

// Security providers
final appLockEnabledProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.appLockEnabled ?? false;
});

final appPinCodeProvider = Provider<String?>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.appPinCode;
});

final appPasswordProvider = Provider<String?>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.appPassword;
});

final autoLockTimeoutProvider = Provider<AutoLockTimeout>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.autoLockTimeout ?? AutoLockTimeout.immediate;
});

final biometricUnlockEnabledProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.biometricUnlockEnabled ?? true;
});

final homeShowBudgetProgressProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.homeShowBudgetProgress ?? true;
});

final homeSectionOrderProvider = Provider<List<String>>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.homeSectionOrder ??
      const ['accounts', 'totalBalance', 'quickActions', 'budgetProgress', 'recentTransactions'];
});
