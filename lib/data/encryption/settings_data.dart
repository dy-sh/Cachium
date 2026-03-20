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

    /// Theme mode: 'dark', 'light', 'system'
    @Default('dark') String themeMode,

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

    /// Main currency code (ISO 4217)
    @Default('USD') String mainCurrencyCode,

    /// Exchange rate API option: 'frankfurter', 'exchangeRateHost', 'manual'
    @Default('frankfurter') String exchangeRateApiOption,

    /// Cached exchange rates as JSON string
    String? cachedExchangeRates,

    /// Timestamp of last successful rate fetch
    int? lastRateFetchTimestamp,

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

    /// Number of categories shown before "More" button
    @Default(5) int categoriesFoldedCount,

    /// Whether to show "New Account" button in form
    @Default(true) bool showAddAccountButton,

    /// Whether to show "New" category button in form
    @Default(true) bool showAddCategoryButton,

    /// Default transaction type: 'income' or 'expense'
    @Default('expense') String defaultTransactionType,

    /// Whether to allow saving with amount = 0
    @Default(true) bool allowZeroAmount,

    /// Category sort option: 'lastUsed', 'listOrder', 'alphabetical'
    @Default('lastUsed') String categorySortOption,

    /// Last used category ID for income transactions
    String? lastUsedIncomeCategoryId,

    /// Last used category ID for expense transactions
    String? lastUsedExpenseCategoryId,

    /// Whether app lock (biometric/PIN) is enabled
    @Default(false) bool appLockEnabled,

    /// App PIN code (stored as plaintext 4-8 digit string)
    String? appPinCode,

    /// App password (stored as plaintext string)
    String? appPassword,

    /// Auto-lock timeout: 'immediate', 'after30Seconds', 'after1Minute', 'after5Minutes', 'after15Minutes', 'never'
    @Default('immediate') String autoLockTimeout,

    /// Whether biometric unlock is enabled (when hardware is available)
    @Default(true) bool biometricUnlockEnabled,

    /// Whether notifications are enabled
    @Default(false) bool notificationsEnabled,

    /// Budget alert thresholds (percentages)
    @Default([75, 90, 100]) List<int> budgetAlertThresholds,

    /// Whether recurring transaction reminders are enabled
    @Default(true) bool recurringRemindersEnabled,

    /// Days in advance for recurring reminders
    @Default(1) int recurringReminderAdvanceDays,

    /// Whether weekly spending summary is enabled
    @Default(false) bool weeklySpendingSummaryEnabled,

    /// Day of week for weekly summary (1=Monday, 7=Sunday)
    @Default(1) int weeklySpendingSummaryDay,

    /// Whether attachment files on disk are encrypted
    @Default(false) bool encryptAttachments,

    /// Whether budget progress is shown on home
    @Default(true) bool homeShowBudgetProgress,

    /// Home section ordering
    @Default(['accounts', 'totalBalance', 'quickActions', 'budgetProgress', 'recentTransactions'])
    List<String> homeSectionOrder,
  }) = _SettingsData;

  factory SettingsData.fromJson(Map<String, dynamic> json) =>
      _$SettingsDataFromJson(json);
}
