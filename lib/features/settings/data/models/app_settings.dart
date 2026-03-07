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
  final AmountDisplaySize homeAccountsTextSize;
  final AmountDisplaySize homeTotalBalanceTextSize;
  final bool homeBalancesHiddenByDefault;

  // Security
  final bool appLockEnabled;
  final String? appPinCode;
  final String? appPassword;

  // Onboarding
  final bool onboardingCompleted;

  const AppSettings({
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
    this.homeAccountsTextSize = AmountDisplaySize.large,
    this.homeTotalBalanceTextSize = AmountDisplaySize.large,
    this.homeBalancesHiddenByDefault = false,
    this.appLockEnabled = false,
    this.appPinCode,
    this.appPassword,
    this.onboardingCompleted = false,
  });

  Color get accentColor {
    return AppColors.getAccentColor(accentColorIndex, colorIntensity);
  }

  AppSettings copyWith({
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
    AmountDisplaySize? homeAccountsTextSize,
    AmountDisplaySize? homeTotalBalanceTextSize,
    bool? homeBalancesHiddenByDefault,
    bool? appLockEnabled,
    String? appPinCode,
    bool clearAppPinCode = false,
    String? appPassword,
    bool clearAppPassword = false,
    bool? onboardingCompleted,
  }) {
    return AppSettings(
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
      homeAccountsTextSize: homeAccountsTextSize ?? this.homeAccountsTextSize,
      homeTotalBalanceTextSize: homeTotalBalanceTextSize ?? this.homeTotalBalanceTextSize,
      homeBalancesHiddenByDefault: homeBalancesHiddenByDefault ?? this.homeBalancesHiddenByDefault,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      appPinCode: clearAppPinCode ? null : (appPinCode ?? this.appPinCode),
      appPassword: clearAppPassword ? null : (appPassword ?? this.appPassword),
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}
