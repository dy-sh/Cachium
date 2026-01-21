import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/database_providers.dart';
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
