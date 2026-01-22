import 'dart:convert';

import '../../core/database/app_database.dart' as db;
import '../../features/settings/data/models/app_settings.dart' as ui;
import '../encryption/settings_data.dart';

/// Repository for managing app settings storage.
///
/// Converts between UI AppSettings and database records.
/// Settings are stored as unencrypted JSON since they don't contain
/// sensitive financial data.
class SettingsRepository {
  final db.AppDatabase database;

  /// Fixed ID for the single settings row
  static const String settingsId = 'app_settings';

  SettingsRepository({
    required this.database,
  });

  /// Convert UI AppSettings to internal SettingsData for storage
  SettingsData _toData(ui.AppSettings settings) {
    return SettingsData(
      id: settingsId,
      colorIntensity: settings.colorIntensity.name,
      accentColorIndex: settings.accentColorIndex,
      accountCardStyle: settings.accountCardStyle.name,
      tabTransitionsEnabled: settings.tabTransitionsEnabled,
      formAnimationsEnabled: settings.formAnimationsEnabled,
      balanceCountersEnabled: settings.balanceCountersEnabled,
      dateFormat: settings.dateFormat.name,
      currencySymbol: settings.currencySymbol.name,
      customCurrencySymbol: settings.customCurrencySymbol,
      firstDayOfWeek: settings.firstDayOfWeek.name,
      hapticFeedbackEnabled: settings.hapticFeedbackEnabled,
      startScreen: settings.startScreen.name,
      lastUsedAccountId: settings.lastUsedAccountId,
    );
  }

  /// Convert internal SettingsData to UI AppSettings
  ui.AppSettings _toSettings(SettingsData data) {
    return ui.AppSettings(
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
      currencySymbol: ui.CurrencySymbol.values.firstWhere(
        (e) => e.name == data.currencySymbol,
        orElse: () => ui.CurrencySymbol.usd,
      ),
      customCurrencySymbol: data.customCurrencySymbol,
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
    );
  }

  /// Save settings to database (insert or update)
  Future<void> saveSettings(ui.AppSettings settings) async {
    final data = _toData(settings);
    final jsonData = jsonEncode(data.toJson());

    await database.upsertSettings(
      id: settingsId,
      lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      jsonData: jsonData,
    );
  }

  /// Load settings from database
  /// Returns null if no settings exist (first run)
  Future<ui.AppSettings?> loadSettings() async {
    final row = await database.getSettings(settingsId);
    if (row == null) return null;

    final json = jsonDecode(row.jsonData) as Map<String, dynamic>;
    final data = SettingsData.fromJson(json);
    return _toSettings(data);
  }

  /// Check if settings exist in database
  Future<bool> hasSettings() async {
    return database.hasSettings(settingsId);
  }
}
