import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_data.freezed.dart';
part 'settings_data.g.dart';

/// Internal data model for app settings storage.
///
/// This model represents the data that gets serialized to JSON and stored
/// in the database. Settings are not encrypted as they don't contain
/// sensitive financial data.
@freezed
class SettingsData with _$SettingsData {
  const factory SettingsData({
    /// Fixed ID - always 'app_settings'
    @Default('app_settings') String id,

    /// Color intensity: 'prism', 'zen', 'neon'
    @Default('prism') String colorIntensity,

    /// Accent color index
    @Default(0) int accentColorIndex,

    /// Account card style: 'dim' or 'bright'
    @Default('dim') String accountCardStyle,

    /// Whether tab transitions are enabled
    @Default(true) bool tabTransitionsEnabled,

    /// Whether form animations are enabled
    @Default(true) bool formAnimationsEnabled,

    /// Whether balance counter animations are enabled
    @Default(true) bool balanceCountersEnabled,

    /// Date format: 'mmddyyyy', 'ddmmyyyy', 'ddmmyyyyDot', 'yyyymmdd'
    @Default('mmddyyyy') String dateFormat,

    /// Currency symbol: 'usd', 'eur', 'gbp', 'custom'
    @Default('usd') String currencySymbol,

    /// Custom currency symbol when currencySymbol is 'custom'
    String? customCurrencySymbol,

    /// First day of week: 'sunday' or 'monday'
    @Default('sunday') String firstDayOfWeek,

    /// Whether haptic feedback is enabled
    @Default(true) bool hapticFeedbackEnabled,

    /// Start screen: 'home', 'transactions', 'accounts'
    @Default('home') String startScreen,

    /// Last used account ID for transaction form
    String? lastUsedAccountId,

    /// Whether to pre-select last used category
    @Default(false) bool selectLastCategory,

    /// Whether to pre-select last used account
    @Default(true) bool selectLastAccount,

    /// Number of accounts shown before "More" button
    @Default(3) int accountsFoldedCount,

    /// Whether to show "New Account" button in form
    @Default(true) bool showAddAccountButton,

    /// Whether to show "New" category button in form
    @Default(true) bool showAddCategoryButton,

    /// Default transaction type: 'income' or 'expense'
    @Default('expense') String defaultTransactionType,

    /// Whether to allow saving with amount = 0
    @Default(true) bool allowZeroAmount,

    /// Last used category ID for income transactions
    String? lastUsedIncomeCategoryId,

    /// Last used category ID for expense transactions
    String? lastUsedExpenseCategoryId,
  }) = _SettingsData;

  factory SettingsData.fromJson(Map<String, dynamic> json) =>
      _$SettingsDataFromJson(json);
}
