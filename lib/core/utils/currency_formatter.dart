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
}
