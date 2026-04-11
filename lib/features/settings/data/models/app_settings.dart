import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../transactions/data/models/transaction.dart';

enum DateFormatOption {
  mmddyyyy('MM/DD/YYYY', 'M/d/yyyy'),
  ddmmyyyy('DD/MM/YYYY', 'd/M/yyyy'),
  ddmmyyyyDot('DD.MM.YYYY', 'd.M.yyyy'),
  yyyymmdd('YYYY-MM-DD', 'yyyy-MM-dd');

  final String label;
  final String pattern;
  const DateFormatOption(this.label, this.pattern);
}

enum ColorIntensity {
  prism,
  zen,
  neon,
}

enum ThemeModeOption {
  dark,
  light,
  system;

  String get displayName {
    switch (this) {
      case ThemeModeOption.dark:
        return 'Dark';
      case ThemeModeOption.light:
        return 'Light';
      case ThemeModeOption.system:
        return 'System';
    }
  }
}

enum StartScreen {
  home('/'),
  transactions('/transactions'),
  accounts('/accounts');

  final String route;
  const StartScreen(this.route);
}

enum FirstDayOfWeek {
  sunday(DateTime.sunday),
  monday(DateTime.monday);

  final int value;
  const FirstDayOfWeek(this.value);
}

enum AccountCardStyle {
  dim,
  bright;
}

enum AmountDisplaySize {
  large,
  small;

  String get displayName {
    switch (this) {
      case AmountDisplaySize.large:
        return 'Large';
      case AmountDisplaySize.small:
        return 'Small';
    }
  }
}

enum CategorySortOption {
  lastUsed,
  listOrder,
  alphabetical;

  String get displayName {
    switch (this) {
      case CategorySortOption.lastUsed:
        return 'Last Used';
      case CategorySortOption.listOrder:
        return 'List Order';
      case CategorySortOption.alphabetical:
        return 'Alphabetical';
    }
  }
}

enum AssetSortOption {
  lastUsed,
  listOrder,
  alphabetical,
  newest;

  String get displayName {
    switch (this) {
      case AssetSortOption.lastUsed:
        return 'Last Used';
      case AssetSortOption.listOrder:
        return 'List Order';
      case AssetSortOption.alphabetical:
        return 'Alphabetical';
      case AssetSortOption.newest:
        return 'Newest';
    }
  }
}

enum AutoLockTimeout {
  immediate,
  after30Seconds,
  after1Minute,
  after5Minutes,
  after15Minutes,
  never;

  String get displayName {
    switch (this) {
      case AutoLockTimeout.immediate:
        return 'Immediately';
      case AutoLockTimeout.after30Seconds:
        return 'After 30 Seconds';
      case AutoLockTimeout.after1Minute:
        return 'After 1 Minute';
      case AutoLockTimeout.after5Minutes:
        return 'After 5 Minutes';
      case AutoLockTimeout.after15Minutes:
        return 'After 15 Minutes';
      case AutoLockTimeout.never:
        return 'Never';
    }
  }

  Duration? get duration {
    switch (this) {
      case AutoLockTimeout.immediate:
        return null;
      case AutoLockTimeout.after30Seconds:
        return const Duration(seconds: 30);
      case AutoLockTimeout.after1Minute:
        return const Duration(minutes: 1);
      case AutoLockTimeout.after5Minutes:
        return const Duration(minutes: 5);
      case AutoLockTimeout.after15Minutes:
        return const Duration(minutes: 15);
      case AutoLockTimeout.never:
        return null;
    }
  }
}

enum ExchangeRateApiOption {
  frankfurter,
  exchangeRateHost,
  manual;

  String get displayName {
    switch (this) {
      case ExchangeRateApiOption.frankfurter:
        return 'Frankfurter (ECB)';
      case ExchangeRateApiOption.exchangeRateHost:
        return 'Open ER-API';
      case ExchangeRateApiOption.manual:
        return 'Manual / Offline';
    }
  }
}

class AppSettings {
  // Appearance
  final ThemeModeOption themeMode;
  final ColorIntensity colorIntensity;
  final int accentColorIndex;
  final AccountCardStyle accountCardStyle;
  final bool tabTransitionsEnabled;
  final bool formAnimationsEnabled;
  final bool balanceCountersEnabled;

  // Formats
  final DateFormatOption dateFormat;
  final String mainCurrencyCode;
  final ExchangeRateApiOption exchangeRateApiOption;
  final String? cachedExchangeRates;
  final int? lastRateFetchTimestamp;
  final FirstDayOfWeek firstDayOfWeek;

  // Preferences
  final bool hapticFeedbackEnabled;
  final StartScreen startScreen;
  final String? lastUsedAccountId;

  // Transactions
  final bool autoCategorizeByMerchant;
  final bool selectLastCategory;
  final bool selectLastAccount;
  final int accountsFoldedCount;
  final int categoriesFoldedCount;
  final bool showAddAccountButton;
  final bool showAddCategoryButton;
  final TransactionType defaultTransactionType;
  final bool allowZeroAmount;
  final CategorySortOption categorySortOption;
  final String? lastUsedIncomeCategoryId;
  final String? lastUsedExpenseCategoryId;
  final AmountDisplaySize transactionAmountSize;
  final bool allowSelectParentCategory;

  // Assets
  final int assetsFoldedCount;
  final bool showAddAssetButton;
  final AssetSortOption assetSortOption;
  final bool showAssetSelector;

  // Home Page
  final bool homeShowAccountsList;
  final bool homeShowTotalBalance;
  final bool homeShowQuickActions;
  final bool homeShowRecentTransactions;
  final bool homeShowBudgetProgress;
  final List<String> homeSectionOrder;
  final AmountDisplaySize homeAccountsTextSize;
  final AmountDisplaySize homeTotalBalanceTextSize;
  final bool homeBalancesHiddenByDefault;

  // Security
  final bool appLockEnabled;
  final String? appPinCode;
  final String? appPassword;
  final AutoLockTimeout autoLockTimeout;
  final bool credentialReadFailed;
  final bool biometricUnlockEnabled;
  final bool hideFromScreenshots;

  // Notifications
  final bool notificationsEnabled;
  final List<int> budgetAlertThresholds;
  final bool recurringRemindersEnabled;
  final int recurringReminderAdvanceDays;
  final bool weeklySpendingSummaryEnabled;
  final int weeklySpendingSummaryDay; // 1=Monday, 7=Sunday

  // Attachments
  final bool encryptAttachments;

  // Recurring
  final bool autoGenerateRecurring;

  // Onboarding
  final bool onboardingCompleted;
  final bool tutorialCompleted;

  const AppSettings({
    this.themeMode = ThemeModeOption.dark,
    this.colorIntensity = ColorIntensity.prism,
    this.accentColorIndex = 0,
    this.accountCardStyle = AccountCardStyle.dim,
    this.tabTransitionsEnabled = true,
    this.formAnimationsEnabled = true,
    this.balanceCountersEnabled = true,
    this.dateFormat = DateFormatOption.mmddyyyy,
    this.mainCurrencyCode = 'USD',
    this.exchangeRateApiOption = ExchangeRateApiOption.frankfurter,
    this.cachedExchangeRates,
    this.lastRateFetchTimestamp,
    this.firstDayOfWeek = FirstDayOfWeek.sunday,
    this.hapticFeedbackEnabled = true,
    this.startScreen = StartScreen.home,
    this.lastUsedAccountId,
    this.autoCategorizeByMerchant = true,
    this.selectLastCategory = false,
    this.selectLastAccount = true,
    this.accountsFoldedCount = 3,
    this.categoriesFoldedCount = 5,
    this.showAddAccountButton = true,
    this.showAddCategoryButton = true,
    this.defaultTransactionType = TransactionType.expense,
    this.allowZeroAmount = true,
    this.categorySortOption = CategorySortOption.lastUsed,
    this.lastUsedIncomeCategoryId,
    this.lastUsedExpenseCategoryId,
    this.transactionAmountSize = AmountDisplaySize.large,
    this.allowSelectParentCategory = true,
    this.assetsFoldedCount = 5,
    this.showAddAssetButton = true,
    this.assetSortOption = AssetSortOption.lastUsed,
    this.showAssetSelector = true,
    this.homeShowAccountsList = true,
    this.homeShowTotalBalance = true,
    this.homeShowQuickActions = true,
    this.homeShowRecentTransactions = true,
    this.homeShowBudgetProgress = true,
    this.homeSectionOrder = const ['accounts', 'totalBalance', 'quickActions', 'budgetProgress', 'recentTransactions'],
    this.homeAccountsTextSize = AmountDisplaySize.large,
    this.homeTotalBalanceTextSize = AmountDisplaySize.large,
    this.homeBalancesHiddenByDefault = false,
    this.appLockEnabled = false,
    this.appPinCode,
    this.appPassword,
    this.autoLockTimeout = AutoLockTimeout.immediate,
    this.credentialReadFailed = false,
    this.biometricUnlockEnabled = true,
    this.hideFromScreenshots = true,
    this.notificationsEnabled = false,
    this.budgetAlertThresholds = const [75, 90, 100],
    this.recurringRemindersEnabled = true,
    this.recurringReminderAdvanceDays = 1,
    this.weeklySpendingSummaryEnabled = false,
    this.weeklySpendingSummaryDay = 1,
    this.encryptAttachments = false,
    this.autoGenerateRecurring = false,
    this.onboardingCompleted = false,
    this.tutorialCompleted = false,
  });

  Color get accentColor {
    return AppColors.getAccentColor(accentColorIndex, colorIntensity);
  }

  AppSettings copyWith({
    ThemeModeOption? themeMode,
    ColorIntensity? colorIntensity,
    int? accentColorIndex,
    AccountCardStyle? accountCardStyle,
    bool? tabTransitionsEnabled,
    bool? formAnimationsEnabled,
    bool? balanceCountersEnabled,
    DateFormatOption? dateFormat,
    String? mainCurrencyCode,
    ExchangeRateApiOption? exchangeRateApiOption,
    String? cachedExchangeRates,
    bool clearCachedExchangeRates = false,
    int? lastRateFetchTimestamp,
    FirstDayOfWeek? firstDayOfWeek,
    bool? hapticFeedbackEnabled,
    StartScreen? startScreen,
    String? lastUsedAccountId,
    bool? autoCategorizeByMerchant,
    bool? selectLastCategory,
    bool? selectLastAccount,
    int? accountsFoldedCount,
    int? categoriesFoldedCount,
    bool? showAddAccountButton,
    bool? showAddCategoryButton,
    TransactionType? defaultTransactionType,
    bool? allowZeroAmount,
    CategorySortOption? categorySortOption,
    String? lastUsedIncomeCategoryId,
    String? lastUsedExpenseCategoryId,
    AmountDisplaySize? transactionAmountSize,
    bool? allowSelectParentCategory,
    int? assetsFoldedCount,
    bool? showAddAssetButton,
    AssetSortOption? assetSortOption,
    bool? showAssetSelector,
    bool? homeShowAccountsList,
    bool? homeShowTotalBalance,
    bool? homeShowQuickActions,
    bool? homeShowRecentTransactions,
    bool? homeShowBudgetProgress,
    List<String>? homeSectionOrder,
    AmountDisplaySize? homeAccountsTextSize,
    AmountDisplaySize? homeTotalBalanceTextSize,
    bool? homeBalancesHiddenByDefault,
    bool? appLockEnabled,
    String? appPinCode,
    bool clearAppPinCode = false,
    String? appPassword,
    bool clearAppPassword = false,
    AutoLockTimeout? autoLockTimeout,
    bool? credentialReadFailed,
    bool? biometricUnlockEnabled,
    bool? hideFromScreenshots,
    bool? notificationsEnabled,
    List<int>? budgetAlertThresholds,
    bool? recurringRemindersEnabled,
    int? recurringReminderAdvanceDays,
    bool? weeklySpendingSummaryEnabled,
    int? weeklySpendingSummaryDay,
    bool? encryptAttachments,
    bool? autoGenerateRecurring,
    bool? onboardingCompleted,
    bool? tutorialCompleted,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      colorIntensity: colorIntensity ?? this.colorIntensity,
      accentColorIndex: accentColorIndex ?? this.accentColorIndex,
      accountCardStyle: accountCardStyle ?? this.accountCardStyle,
      tabTransitionsEnabled: tabTransitionsEnabled ?? this.tabTransitionsEnabled,
      formAnimationsEnabled: formAnimationsEnabled ?? this.formAnimationsEnabled,
      balanceCountersEnabled: balanceCountersEnabled ?? this.balanceCountersEnabled,
      dateFormat: dateFormat ?? this.dateFormat,
      mainCurrencyCode: mainCurrencyCode ?? this.mainCurrencyCode,
      exchangeRateApiOption: exchangeRateApiOption ?? this.exchangeRateApiOption,
      cachedExchangeRates: clearCachedExchangeRates ? null : (cachedExchangeRates ?? this.cachedExchangeRates),
      lastRateFetchTimestamp: lastRateFetchTimestamp ?? this.lastRateFetchTimestamp,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
      startScreen: startScreen ?? this.startScreen,
      lastUsedAccountId: lastUsedAccountId ?? this.lastUsedAccountId,
      autoCategorizeByMerchant: autoCategorizeByMerchant ?? this.autoCategorizeByMerchant,
      selectLastCategory: selectLastCategory ?? this.selectLastCategory,
      selectLastAccount: selectLastAccount ?? this.selectLastAccount,
      accountsFoldedCount: accountsFoldedCount ?? this.accountsFoldedCount,
      categoriesFoldedCount: categoriesFoldedCount ?? this.categoriesFoldedCount,
      showAddAccountButton: showAddAccountButton ?? this.showAddAccountButton,
      showAddCategoryButton: showAddCategoryButton ?? this.showAddCategoryButton,
      defaultTransactionType: defaultTransactionType ?? this.defaultTransactionType,
      allowZeroAmount: allowZeroAmount ?? this.allowZeroAmount,
      categorySortOption: categorySortOption ?? this.categorySortOption,
      lastUsedIncomeCategoryId: lastUsedIncomeCategoryId ?? this.lastUsedIncomeCategoryId,
      lastUsedExpenseCategoryId: lastUsedExpenseCategoryId ?? this.lastUsedExpenseCategoryId,
      transactionAmountSize: transactionAmountSize ?? this.transactionAmountSize,
      allowSelectParentCategory: allowSelectParentCategory ?? this.allowSelectParentCategory,
      assetsFoldedCount: assetsFoldedCount ?? this.assetsFoldedCount,
      showAddAssetButton: showAddAssetButton ?? this.showAddAssetButton,
      assetSortOption: assetSortOption ?? this.assetSortOption,
      showAssetSelector: showAssetSelector ?? this.showAssetSelector,
      homeShowAccountsList: homeShowAccountsList ?? this.homeShowAccountsList,
      homeShowTotalBalance: homeShowTotalBalance ?? this.homeShowTotalBalance,
      homeShowQuickActions: homeShowQuickActions ?? this.homeShowQuickActions,
      homeShowRecentTransactions: homeShowRecentTransactions ?? this.homeShowRecentTransactions,
      homeShowBudgetProgress: homeShowBudgetProgress ?? this.homeShowBudgetProgress,
      homeSectionOrder: homeSectionOrder ?? this.homeSectionOrder,
      homeAccountsTextSize: homeAccountsTextSize ?? this.homeAccountsTextSize,
      homeTotalBalanceTextSize: homeTotalBalanceTextSize ?? this.homeTotalBalanceTextSize,
      homeBalancesHiddenByDefault: homeBalancesHiddenByDefault ?? this.homeBalancesHiddenByDefault,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      appPinCode: clearAppPinCode ? null : (appPinCode ?? this.appPinCode),
      appPassword: clearAppPassword ? null : (appPassword ?? this.appPassword),
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      credentialReadFailed: credentialReadFailed ?? this.credentialReadFailed,
      biometricUnlockEnabled: biometricUnlockEnabled ?? this.biometricUnlockEnabled,
      hideFromScreenshots: hideFromScreenshots ?? this.hideFromScreenshots,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      budgetAlertThresholds: budgetAlertThresholds ?? this.budgetAlertThresholds,
      recurringRemindersEnabled: recurringRemindersEnabled ?? this.recurringRemindersEnabled,
      recurringReminderAdvanceDays: recurringReminderAdvanceDays ?? this.recurringReminderAdvanceDays,
      weeklySpendingSummaryEnabled: weeklySpendingSummaryEnabled ?? this.weeklySpendingSummaryEnabled,
      weeklySpendingSummaryDay: weeklySpendingSummaryDay ?? this.weeklySpendingSummaryDay,
      encryptAttachments: encryptAttachments ?? this.encryptAttachments,
      autoGenerateRecurring: autoGenerateRecurring ?? this.autoGenerateRecurring,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      tutorialCompleted: tutorialCompleted ?? this.tutorialCompleted,
    );
  }
}
