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
  }) = _SettingsData;

  factory SettingsData.fromJson(Map<String, dynamic> json) =>
      _$SettingsDataFromJson(json);
}
