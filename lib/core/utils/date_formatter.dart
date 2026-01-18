import 'package:intl/intl.dart';
import '../../features/settings/data/models/app_settings.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _fullFormat = DateFormat('MMMM d, yyyy');
  static final DateFormat _shortFormat = DateFormat('MMM d');
  static final DateFormat _dayFormat = DateFormat('EEEE');
  static final DateFormat _timeFormat = DateFormat('h:mm a');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');

  // Cached format instances for date format options
  static final Map<DateFormatOption, DateFormat> _dateFormats = {
    DateFormatOption.mmddyyyy: DateFormat('M/d/yyyy'),
    DateFormatOption.ddmmyyyy: DateFormat('d/M/yyyy'),
    DateFormatOption.ddmmyyyyDot: DateFormat('d.M.yyyy'),
    DateFormatOption.yyyymmdd: DateFormat('yyyy-MM-dd'),
  };

  static String formatFull(DateTime date) {
    return _fullFormat.format(date);
  }

  static String formatShort(DateTime date) {
    return _shortFormat.format(date);
  }

  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  /// Format date according to user's selected format
  static String formatWithOption(DateTime date, DateFormatOption option) {
    return _dateFormats[option]!.format(date);
  }

  static String formatRelative(DateTime date) {
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

  static String formatGroupHeader(DateTime date) {
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

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
