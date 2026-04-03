// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SettingsDataImpl _$$SettingsDataImplFromJson(
  Map<String, dynamic> json,
) => _$SettingsDataImpl(
  id: json['id'] as String? ?? 'app_settings',
  themeMode: json['themeMode'] as String? ?? 'dark',
  colorIntensity: json['colorIntensity'] as String? ?? 'prism',
  accentColorIndex: (json['accentColorIndex'] as num?)?.toInt() ?? 0,
  accountCardStyle: json['accountCardStyle'] as String? ?? 'dim',
  tabTransitionsEnabled: json['tabTransitionsEnabled'] as bool? ?? true,
  formAnimationsEnabled: json['formAnimationsEnabled'] as bool? ?? true,
  balanceCountersEnabled: json['balanceCountersEnabled'] as bool? ?? true,
  dateFormat: json['dateFormat'] as String? ?? 'mmddyyyy',
  mainCurrencyCode: json['mainCurrencyCode'] as String? ?? 'USD',
  exchangeRateApiOption:
      json['exchangeRateApiOption'] as String? ?? 'frankfurter',
  cachedExchangeRates: json['cachedExchangeRates'] as String?,
  lastRateFetchTimestamp: (json['lastRateFetchTimestamp'] as num?)?.toInt(),
  firstDayOfWeek: json['firstDayOfWeek'] as String? ?? 'sunday',
  hapticFeedbackEnabled: json['hapticFeedbackEnabled'] as bool? ?? true,
  startScreen: json['startScreen'] as String? ?? 'home',
  lastUsedAccountId: json['lastUsedAccountId'] as String?,
  autoCategorizeByMerchant: json['autoCategorizeByMerchant'] as bool? ?? true,
  selectLastCategory: json['selectLastCategory'] as bool? ?? false,
  selectLastAccount: json['selectLastAccount'] as bool? ?? true,
  accountsFoldedCount: (json['accountsFoldedCount'] as num?)?.toInt() ?? 3,
  categoriesFoldedCount: (json['categoriesFoldedCount'] as num?)?.toInt() ?? 5,
  showAddAccountButton: json['showAddAccountButton'] as bool? ?? true,
  showAddCategoryButton: json['showAddCategoryButton'] as bool? ?? true,
  defaultTransactionType:
      json['defaultTransactionType'] as String? ?? 'expense',
  allowZeroAmount: json['allowZeroAmount'] as bool? ?? true,
  categorySortOption: json['categorySortOption'] as String? ?? 'lastUsed',
  lastUsedIncomeCategoryId: json['lastUsedIncomeCategoryId'] as String?,
  lastUsedExpenseCategoryId: json['lastUsedExpenseCategoryId'] as String?,
  appLockEnabled: json['appLockEnabled'] as bool? ?? false,
  appPinCode: json['appPinCode'] as String?,
  appPassword: json['appPassword'] as String?,
  autoLockTimeout: json['autoLockTimeout'] as String? ?? 'immediate',
  biometricUnlockEnabled: json['biometricUnlockEnabled'] as bool? ?? true,
  notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
  budgetAlertThresholds:
      (json['budgetAlertThresholds'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [75, 90, 100],
  recurringRemindersEnabled: json['recurringRemindersEnabled'] as bool? ?? true,
  recurringReminderAdvanceDays:
      (json['recurringReminderAdvanceDays'] as num?)?.toInt() ?? 1,
  weeklySpendingSummaryEnabled:
      json['weeklySpendingSummaryEnabled'] as bool? ?? false,
  weeklySpendingSummaryDay:
      (json['weeklySpendingSummaryDay'] as num?)?.toInt() ?? 1,
  encryptAttachments: json['encryptAttachments'] as bool? ?? false,
  autoGenerateRecurring: json['autoGenerateRecurring'] as bool? ?? false,
  homeShowBudgetProgress: json['homeShowBudgetProgress'] as bool? ?? true,
  homeSectionOrder:
      (json['homeSectionOrder'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [
        'accounts',
        'totalBalance',
        'quickActions',
        'budgetProgress',
        'recentTransactions',
      ],
  tutorialCompleted: json['tutorialCompleted'] as bool? ?? false,
);

Map<String, dynamic> _$$SettingsDataImplToJson(_$SettingsDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'themeMode': instance.themeMode,
      'colorIntensity': instance.colorIntensity,
      'accentColorIndex': instance.accentColorIndex,
      'accountCardStyle': instance.accountCardStyle,
      'tabTransitionsEnabled': instance.tabTransitionsEnabled,
      'formAnimationsEnabled': instance.formAnimationsEnabled,
      'balanceCountersEnabled': instance.balanceCountersEnabled,
      'dateFormat': instance.dateFormat,
      'mainCurrencyCode': instance.mainCurrencyCode,
      'exchangeRateApiOption': instance.exchangeRateApiOption,
      'cachedExchangeRates': instance.cachedExchangeRates,
      'lastRateFetchTimestamp': instance.lastRateFetchTimestamp,
      'firstDayOfWeek': instance.firstDayOfWeek,
      'hapticFeedbackEnabled': instance.hapticFeedbackEnabled,
      'startScreen': instance.startScreen,
      'lastUsedAccountId': instance.lastUsedAccountId,
      'autoCategorizeByMerchant': instance.autoCategorizeByMerchant,
      'selectLastCategory': instance.selectLastCategory,
      'selectLastAccount': instance.selectLastAccount,
      'accountsFoldedCount': instance.accountsFoldedCount,
      'categoriesFoldedCount': instance.categoriesFoldedCount,
      'showAddAccountButton': instance.showAddAccountButton,
      'showAddCategoryButton': instance.showAddCategoryButton,
      'defaultTransactionType': instance.defaultTransactionType,
      'allowZeroAmount': instance.allowZeroAmount,
      'categorySortOption': instance.categorySortOption,
      'lastUsedIncomeCategoryId': instance.lastUsedIncomeCategoryId,
      'lastUsedExpenseCategoryId': instance.lastUsedExpenseCategoryId,
      'appLockEnabled': instance.appLockEnabled,
      'appPinCode': instance.appPinCode,
      'appPassword': instance.appPassword,
      'autoLockTimeout': instance.autoLockTimeout,
      'biometricUnlockEnabled': instance.biometricUnlockEnabled,
      'notificationsEnabled': instance.notificationsEnabled,
      'budgetAlertThresholds': instance.budgetAlertThresholds,
      'recurringRemindersEnabled': instance.recurringRemindersEnabled,
      'recurringReminderAdvanceDays': instance.recurringReminderAdvanceDays,
      'weeklySpendingSummaryEnabled': instance.weeklySpendingSummaryEnabled,
      'weeklySpendingSummaryDay': instance.weeklySpendingSummaryDay,
      'encryptAttachments': instance.encryptAttachments,
      'autoGenerateRecurring': instance.autoGenerateRecurring,
      'homeShowBudgetProgress': instance.homeShowBudgetProgress,
      'homeSectionOrder': instance.homeSectionOrder,
      'tutorialCompleted': instance.tutorialCompleted,
    };
