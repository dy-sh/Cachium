import 'package:flutter/material.dart';

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
  bright,
  dim,
  pastel,
  neon,
  earth,
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

enum CurrencySymbol {
  usd('\$', 'USD'),
  eur('\u20AC', 'EUR'),
  gbp('\u00A3', 'GBP'),
  custom('', 'Custom');

  final String symbol;
  final String label;
  const CurrencySymbol(this.symbol, this.label);
}

class AppSettings {
  // Appearance
  final ColorIntensity colorIntensity;
  final Color accentColor;
  final bool tabTransitionsEnabled;
  final bool formAnimationsEnabled;
  final bool balanceCountersEnabled;

  // Formats
  final DateFormatOption dateFormat;
  final CurrencySymbol currencySymbol;
  final String? customCurrencySymbol;
  final FirstDayOfWeek firstDayOfWeek;

  // Preferences
  final bool hapticFeedbackEnabled;
  final StartScreen startScreen;
  final String? lastUsedAccountId;

  const AppSettings({
    this.colorIntensity = ColorIntensity.dim,
    this.accentColor = const Color(0xFFFFFFFF),
    this.tabTransitionsEnabled = true,
    this.formAnimationsEnabled = true,
    this.balanceCountersEnabled = true,
    this.dateFormat = DateFormatOption.mmddyyyy,
    this.currencySymbol = CurrencySymbol.usd,
    this.customCurrencySymbol,
    this.firstDayOfWeek = FirstDayOfWeek.sunday,
    this.hapticFeedbackEnabled = true,
    this.startScreen = StartScreen.home,
    this.lastUsedAccountId,
  });

  String get effectiveCurrencySymbol {
    if (currencySymbol == CurrencySymbol.custom && customCurrencySymbol != null) {
      return customCurrencySymbol!;
    }
    return currencySymbol.symbol;
  }

  AppSettings copyWith({
    ColorIntensity? colorIntensity,
    Color? accentColor,
    bool? tabTransitionsEnabled,
    bool? formAnimationsEnabled,
    bool? balanceCountersEnabled,
    DateFormatOption? dateFormat,
    CurrencySymbol? currencySymbol,
    String? customCurrencySymbol,
    FirstDayOfWeek? firstDayOfWeek,
    bool? hapticFeedbackEnabled,
    StartScreen? startScreen,
    String? lastUsedAccountId,
  }) {
    return AppSettings(
      colorIntensity: colorIntensity ?? this.colorIntensity,
      accentColor: accentColor ?? this.accentColor,
      tabTransitionsEnabled: tabTransitionsEnabled ?? this.tabTransitionsEnabled,
      formAnimationsEnabled: formAnimationsEnabled ?? this.formAnimationsEnabled,
      balanceCountersEnabled: balanceCountersEnabled ?? this.balanceCountersEnabled,
      dateFormat: dateFormat ?? this.dateFormat,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      customCurrencySymbol: customCurrencySymbol ?? this.customCurrencySymbol,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
      startScreen: startScreen ?? this.startScreen,
      lastUsedAccountId: lastUsedAccountId ?? this.lastUsedAccountId,
    );
  }
}
