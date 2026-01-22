import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../features/settings/data/models/app_settings.dart';
import '../../features/settings/presentation/providers/settings_provider.dart';

/// Settings-aware currency formatter that uses the user's currency symbol.
class SettingsCurrencyFormatter {
  final String symbol;
  late final NumberFormat _currencyFormat;
  late final NumberFormat _compactFormat;

  SettingsCurrencyFormatter({required this.symbol}) {
    _currencyFormat = NumberFormat.currency(
      locale: 'en_US',
      symbol: symbol,
      decimalDigits: 2,
    );
    _compactFormat = NumberFormat.compactCurrency(
      locale: 'en_US',
      symbol: symbol,
      decimalDigits: 0,
    );
  }

  String format(double amount) {
    return _currencyFormat.format(amount);
  }

  String formatCompact(double amount) {
    return _compactFormat.format(amount);
  }

  String formatWithSign(double amount, String type) {
    final formatted = format(amount.abs());
    if (type == 'income') {
      return '+$formatted';
    } else if (type == 'expense') {
      return '-$formatted';
    }
    return formatted;
  }

  String formatSimple(double amount) {
    if (amount == amount.roundToDouble()) {
      return '$symbol${amount.toInt()}';
    }
    return format(amount);
  }
}

/// Provider for settings-aware currency formatter.
final currencyFormatterProvider = Provider<SettingsCurrencyFormatter>((ref) {
  final symbol = ref.watch(currencySymbolProvider);
  return SettingsCurrencyFormatter(symbol: symbol);
});

/// Settings-aware date formatter that uses the user's date format preference.
class SettingsDateFormatter {
  final DateFormatOption dateFormat;
  final FirstDayOfWeek firstDayOfWeek;

  late final DateFormat _fullFormat;
  late final DateFormat _shortFormat;
  late final DateFormat _dayFormat;
  late final DateFormat _timeFormat;
  late final DateFormat _monthYearFormat;
  late final DateFormat _dateOptionFormat;

  SettingsDateFormatter({
    required this.dateFormat,
    required this.firstDayOfWeek,
  }) {
    _fullFormat = DateFormat('MMMM d, yyyy');
    _shortFormat = DateFormat('MMM d');
    _dayFormat = DateFormat('EEEE');
    _timeFormat = DateFormat('h:mm a');
    _monthYearFormat = DateFormat('MMMM yyyy');
    _dateOptionFormat = DateFormat(dateFormat.pattern);
  }

  String formatFull(DateTime date) => _fullFormat.format(date);

  String formatShort(DateTime date) => _shortFormat.format(date);

  String formatTime(DateTime date) => _timeFormat.format(date);

  String formatMonthYear(DateTime date) => _monthYearFormat.format(date);

  /// Format date according to user's selected format
  String formatWithOption(DateTime date) => _dateOptionFormat.format(date);

  String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (dateOnly.isAfter(today.subtract(const Duration(days: 7)))) {
      return _dayFormat.format(date);
    } else if (date.year == now.year) {
      return _shortFormat.format(date);
    } else {
      return _fullFormat.format(date);
    }
  }

  String formatGroupHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (date.year == now.year) {
      return _shortFormat.format(date);
    } else {
      return _fullFormat.format(date);
    }
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Provider for settings-aware date formatter.
final dateFormatterProvider = Provider<SettingsDateFormatter>((ref) {
  final dateFormat = ref.watch(dateFormatProvider);
  final firstDayOfWeek = ref.watch(firstDayOfWeekProvider);
  return SettingsDateFormatter(
    dateFormat: dateFormat,
    firstDayOfWeek: firstDayOfWeek,
  );
});
