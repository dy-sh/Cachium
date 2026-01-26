// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SettingsDataImpl _$$SettingsDataImplFromJson(Map<String, dynamic> json) =>
    _$SettingsDataImpl(
      id: json['id'] as String? ?? 'app_settings',
      colorIntensity: json['colorIntensity'] as String? ?? 'prism',
      accentColorIndex: (json['accentColorIndex'] as num?)?.toInt() ?? 0,
      accountCardStyle: json['accountCardStyle'] as String? ?? 'dim',
      tabTransitionsEnabled: json['tabTransitionsEnabled'] as bool? ?? true,
      formAnimationsEnabled: json['formAnimationsEnabled'] as bool? ?? true,
      balanceCountersEnabled: json['balanceCountersEnabled'] as bool? ?? true,
      dateFormat: json['dateFormat'] as String? ?? 'mmddyyyy',
      currencySymbol: json['currencySymbol'] as String? ?? 'usd',
      customCurrencySymbol: json['customCurrencySymbol'] as String?,
      firstDayOfWeek: json['firstDayOfWeek'] as String? ?? 'sunday',
      hapticFeedbackEnabled: json['hapticFeedbackEnabled'] as bool? ?? true,
      startScreen: json['startScreen'] as String? ?? 'home',
      lastUsedAccountId: json['lastUsedAccountId'] as String?,
      selectLastCategory: json['selectLastCategory'] as bool? ?? false,
      selectLastAccount: json['selectLastAccount'] as bool? ?? true,
      accountsFoldedCount: (json['accountsFoldedCount'] as num?)?.toInt() ?? 3,
      showAddAccountButton: json['showAddAccountButton'] as bool? ?? true,
      showAddCategoryButton: json['showAddCategoryButton'] as bool? ?? true,
      defaultTransactionType:
          json['defaultTransactionType'] as String? ?? 'expense',
      allowZeroAmount: json['allowZeroAmount'] as bool? ?? true,
      lastUsedIncomeCategoryId: json['lastUsedIncomeCategoryId'] as String?,
      lastUsedExpenseCategoryId: json['lastUsedExpenseCategoryId'] as String?,
    );

Map<String, dynamic> _$$SettingsDataImplToJson(_$SettingsDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'colorIntensity': instance.colorIntensity,
      'accentColorIndex': instance.accentColorIndex,
      'accountCardStyle': instance.accountCardStyle,
      'tabTransitionsEnabled': instance.tabTransitionsEnabled,
      'formAnimationsEnabled': instance.formAnimationsEnabled,
      'balanceCountersEnabled': instance.balanceCountersEnabled,
      'dateFormat': instance.dateFormat,
      'currencySymbol': instance.currencySymbol,
      'customCurrencySymbol': instance.customCurrencySymbol,
      'firstDayOfWeek': instance.firstDayOfWeek,
      'hapticFeedbackEnabled': instance.hapticFeedbackEnabled,
      'startScreen': instance.startScreen,
      'lastUsedAccountId': instance.lastUsedAccountId,
      'selectLastCategory': instance.selectLastCategory,
      'selectLastAccount': instance.selectLastAccount,
      'accountsFoldedCount': instance.accountsFoldedCount,
      'showAddAccountButton': instance.showAddAccountButton,
      'showAddCategoryButton': instance.showAddCategoryButton,
      'defaultTransactionType': instance.defaultTransactionType,
      'allowZeroAmount': instance.allowZeroAmount,
      'lastUsedIncomeCategoryId': instance.lastUsedIncomeCategoryId,
      'lastUsedExpenseCategoryId': instance.lastUsedExpenseCategoryId,
    };
