import 'package:intl/intl.dart';

import '../constants/currencies.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(double amount, {String currencyCode = 'USD'}) {
    final symbol = Currency.symbolFromCode(currencyCode);
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static String formatCompact(double amount, {String currencyCode = 'USD'}) {
    final symbol = Currency.symbolFromCode(currencyCode);
    final formatter = NumberFormat.compactCurrency(
      locale: 'en_US',
      symbol: symbol,
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  static String formatWithSign(double amount, String type, {String currencyCode = 'USD'}) {
    final formatted = format(amount.abs(), currencyCode: currencyCode);
    if (type == 'income') {
      return '+$formatted';
    } else if (type == 'expense') {
      return '-$formatted';
    }
    return formatted;
  }

  static String formatSimple(double amount, {String currencyCode = 'USD'}) {
    final symbol = Currency.symbolFromCode(currencyCode);
    if (amount == amount.roundToDouble()) {
      return '$symbol${amount.toInt()}';
    }
    return format(amount, currencyCode: currencyCode);
  }

  /// Format an amount with thousands separators and fixed decimals, WITHOUT a
  /// currency symbol. Callers that need to prepend a symbol themselves (e.g.
  /// charts that control symbol placement separately) should use this.
  static String formatNumber(double amount, {int decimalDigits = 2}) {
    return NumberFormat.decimalPatternDigits(
      locale: 'en_US',
      decimalDigits: decimalDigits,
    ).format(amount);
  }

  /// Short-form amount for chart axis labels: 1.2M / 3.4K / 500.
  /// Prepends the provided symbol without whitespace. Suitable for compact
  /// contexts where a full currency-formatted value would overflow.
  static String formatShort(double amount, String symbol) {
    final abs = amount.abs();
    if (abs >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (abs >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '$symbol${amount.toStringAsFixed(0)}';
  }
}
