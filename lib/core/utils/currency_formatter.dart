import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  static final NumberFormat _compactFormat = NumberFormat.compactCurrency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 0,
  );

  static String format(double amount) {
    return _currencyFormat.format(amount);
  }

  static String formatCompact(double amount) {
    return _compactFormat.format(amount);
  }

  static String formatWithSign(double amount, String type) {
    final formatted = format(amount.abs());
    if (type == 'income') {
      return '+$formatted';
    } else if (type == 'expense') {
      return '-$formatted';
    }
    return formatted;
  }

  static String formatSimple(double amount) {
    if (amount == amount.roundToDouble()) {
      return '\$${amount.toInt()}';
    }
    return format(amount);
  }
}
