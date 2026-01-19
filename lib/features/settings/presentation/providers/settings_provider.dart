import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/app_settings.dart';

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    return const AppSettings();
  }

  // Appearance
  void setColorIntensity(ColorIntensity intensity) {
    state = state.copyWith(colorIntensity: intensity);
  }

  void setAccentColorIndex(int index) {
    state = state.copyWith(accentColorIndex: index);
  }

  void setAccountCardStyle(AccountCardStyle style) {
    state = state.copyWith(accountCardStyle: style);
  }

  void setTabTransitionsEnabled(bool enabled) {
    state = state.copyWith(tabTransitionsEnabled: enabled);
  }

  void setFormAnimationsEnabled(bool enabled) {
    state = state.copyWith(formAnimationsEnabled: enabled);
  }

  void setBalanceCountersEnabled(bool enabled) {
    state = state.copyWith(balanceCountersEnabled: enabled);
  }

  // Formats
  void setDateFormat(DateFormatOption format) {
    state = state.copyWith(dateFormat: format);
  }

  void setCurrencySymbol(CurrencySymbol symbol) {
    state = state.copyWith(currencySymbol: symbol);
  }

  void setCustomCurrencySymbol(String symbol) {
    state = state.copyWith(customCurrencySymbol: symbol);
  }

  void setFirstDayOfWeek(FirstDayOfWeek day) {
    state = state.copyWith(firstDayOfWeek: day);
  }

  // Preferences
  void setHapticFeedbackEnabled(bool enabled) {
    state = state.copyWith(hapticFeedbackEnabled: enabled);
  }

  void setStartScreen(StartScreen screen) {
    state = state.copyWith(startScreen: screen);
  }

  void setLastUsedAccountId(String? accountId) {
    state = state.copyWith(lastUsedAccountId: accountId);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});

// Convenience providers
final colorIntensityProvider = Provider<ColorIntensity>((ref) {
  return ref.watch(settingsProvider.select((s) => s.colorIntensity));
});

final accentColorProvider = Provider<Color>((ref) {
  return ref.watch(settingsProvider.select((s) => s.accentColor));
});

final accountCardStyleProvider = Provider<AccountCardStyle>((ref) {
  return ref.watch(settingsProvider.select((s) => s.accountCardStyle));
});

final dateFormatProvider = Provider<DateFormatOption>((ref) {
  return ref.watch(settingsProvider.select((s) => s.dateFormat));
});

final currencySymbolProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider.select((s) => s.effectiveCurrencySymbol));
});

final firstDayOfWeekProvider = Provider<FirstDayOfWeek>((ref) {
  return ref.watch(settingsProvider.select((s) => s.firstDayOfWeek));
});

final hapticEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider.select((s) => s.hapticFeedbackEnabled));
});

final tabTransitionsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider.select((s) => s.tabTransitionsEnabled));
});

final formAnimationsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider.select((s) => s.formAnimationsEnabled));
});

final balanceCountersEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider.select((s) => s.balanceCountersEnabled));
});

final startScreenProvider = Provider<StartScreen>((ref) {
  return ref.watch(settingsProvider.select((s) => s.startScreen));
});

final lastUsedAccountIdProvider = Provider<String?>((ref) {
  return ref.watch(settingsProvider.select((s) => s.lastUsedAccountId));
});
