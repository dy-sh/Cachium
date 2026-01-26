import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/database_providers.dart';
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
    final repo = ref.read(settingsRepositoryProvider);
    await repo.saveSettings(newSettings);
    state = AsyncData(newSettings);
  }

  // Appearance
  Future<void> setColorIntensity(ColorIntensity intensity) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(colorIntensity: intensity));
  }

  Future<void> setAccentColorIndex(int index) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(accentColorIndex: index));
  }

  Future<void> setAccountCardStyle(AccountCardStyle style) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(accountCardStyle: style));
  }

  Future<void> setTabTransitionsEnabled(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(tabTransitionsEnabled: enabled));
  }

  Future<void> setFormAnimationsEnabled(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(formAnimationsEnabled: enabled));
  }

  Future<void> setBalanceCountersEnabled(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(balanceCountersEnabled: enabled));
  }

  // Formats
  Future<void> setDateFormat(DateFormatOption format) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(dateFormat: format));
  }

  Future<void> setCurrencySymbol(CurrencySymbol symbol) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(currencySymbol: symbol));
  }

  Future<void> setCustomCurrencySymbol(String symbol) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(customCurrencySymbol: symbol));
  }

  Future<void> setFirstDayOfWeek(FirstDayOfWeek day) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(firstDayOfWeek: day));
  }

  // Preferences
  Future<void> setHapticFeedbackEnabled(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(hapticFeedbackEnabled: enabled));
  }

  Future<void> setStartScreen(StartScreen screen) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(startScreen: screen));
  }

  Future<void> setLastUsedAccountId(String? accountId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(lastUsedAccountId: accountId));
  }

  // Transactions
  Future<void> setSelectLastCategory(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(selectLastCategory: enabled));
  }

  Future<void> setSelectLastAccount(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(selectLastAccount: enabled));
  }

  Future<void> setAccountsFoldedCount(int count) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(accountsFoldedCount: count));
  }

  Future<void> setCategoriesFoldedCount(int count) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(categoriesFoldedCount: count));
  }

  Future<void> setCategorySortOption(CategorySortOption option) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(categorySortOption: option));
  }

  Future<void> setShowAddAccountButton(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(showAddAccountButton: enabled));
  }

  Future<void> setShowAddCategoryButton(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(showAddCategoryButton: enabled));
  }

  Future<void> setDefaultTransactionType(TransactionType type) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(defaultTransactionType: type));
  }

  Future<void> setAllowZeroAmount(bool allowed) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(allowZeroAmount: allowed));
  }

  Future<void> setLastUsedCategoryId(TransactionType type, String? categoryId) async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (type == TransactionType.income) {
      await _saveAndUpdate(current.copyWith(lastUsedIncomeCategoryId: categoryId));
    } else {
      await _saveAndUpdate(current.copyWith(lastUsedExpenseCategoryId: categoryId));
    }
  }

  Future<void> setTransactionAmountSize(AmountDisplaySize size) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(transactionAmountSize: size));
  }

  Future<void> setAllowSelectParentCategory(bool allowed) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(allowSelectParentCategory: allowed));
  }

  // Home Page
  Future<void> setHomeShowAccountsList(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(homeShowAccountsList: enabled));
  }

  Future<void> setHomeShowTotalBalance(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(homeShowTotalBalance: enabled));
  }

  Future<void> setHomeShowQuickActions(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(homeShowQuickActions: enabled));
  }

  Future<void> setHomeShowRecentTransactions(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(homeShowRecentTransactions: enabled));
  }

  Future<void> setHomeAccountsTextSize(AmountDisplaySize size) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(homeAccountsTextSize: size));
  }

  Future<void> setHomeTotalBalanceTextSize(AmountDisplaySize size) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(homeTotalBalanceTextSize: size));
  }

  Future<void> setHomeBalancesHiddenByDefault(bool hidden) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _saveAndUpdate(current.copyWith(homeBalancesHiddenByDefault: hidden));
  }

  // Onboarding
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
      colorIntensity: defaults.colorIntensity,
      accentColorIndex: defaults.accentColorIndex,
      accountCardStyle: defaults.accountCardStyle,
      tabTransitionsEnabled: defaults.tabTransitionsEnabled,
      formAnimationsEnabled: defaults.formAnimationsEnabled,
      balanceCountersEnabled: defaults.balanceCountersEnabled,
      // Reset Formats
      dateFormat: defaults.dateFormat,
      currencySymbol: defaults.currencySymbol,
      customCurrencySymbol: defaults.customCurrencySymbol,
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
      // Reset Home Page
      homeShowAccountsList: defaults.homeShowAccountsList,
      homeShowTotalBalance: defaults.homeShowTotalBalance,
      homeShowQuickActions: defaults.homeShowQuickActions,
      homeShowRecentTransactions: defaults.homeShowRecentTransactions,
      homeAccountsTextSize: defaults.homeAccountsTextSize,
      homeTotalBalanceTextSize: defaults.homeTotalBalanceTextSize,
      homeBalancesHiddenByDefault: defaults.homeBalancesHiddenByDefault,
      // Preserve onboarding
      onboardingCompleted: current.onboardingCompleted,
    );
    await _saveAndUpdate(resetSettings);
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});

// Convenience providers
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

final currencySymbolProvider = Provider<String>((ref) {
  final settingsAsync = ref.watch(settingsProvider);
  return settingsAsync.valueOrNull?.effectiveCurrencySymbol ?? '\$';
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
