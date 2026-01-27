enum DateRangePreset {
  last7Days,
  last30Days,
  thisMonth,
  lastMonth,
  last3Months,
  last6Months,
  last12Months,
  thisYear,
  allTime,
  custom,
}

extension DateRangePresetExtension on DateRangePreset {
  String get displayName {
    switch (this) {
      case DateRangePreset.last7Days:
        return '7D';
      case DateRangePreset.last30Days:
        return '30D';
      case DateRangePreset.thisMonth:
        return 'Month';
      case DateRangePreset.lastMonth:
        return 'Last Month';
      case DateRangePreset.last3Months:
        return '3M';
      case DateRangePreset.last6Months:
        return '6M';
      case DateRangePreset.last12Months:
        return '12M';
      case DateRangePreset.thisYear:
        return 'Year';
      case DateRangePreset.allTime:
        return 'All';
      case DateRangePreset.custom:
        return 'Custom';
    }
  }

  DateRange getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (this) {
      case DateRangePreset.last7Days:
        return DateRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        );
      case DateRangePreset.last30Days:
        return DateRange(
          start: today.subtract(const Duration(days: 29)),
          end: today,
        );
      case DateRangePreset.thisMonth:
        return DateRange(
          start: DateTime(now.year, now.month, 1),
          end: today,
        );
      case DateRangePreset.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final lastDayOfLastMonth = DateTime(now.year, now.month, 0);
        return DateRange(
          start: lastMonth,
          end: DateTime(lastDayOfLastMonth.year, lastDayOfLastMonth.month, lastDayOfLastMonth.day, 23, 59, 59),
        );
      case DateRangePreset.last3Months:
        return DateRange(
          start: DateTime(now.year, now.month - 2, 1),
          end: today,
        );
      case DateRangePreset.last6Months:
        return DateRange(
          start: DateTime(now.year, now.month - 5, 1),
          end: today,
        );
      case DateRangePreset.last12Months:
        return DateRange(
          start: DateTime(now.year - 1, now.month + 1, 1),
          end: today,
        );
      case DateRangePreset.thisYear:
        return DateRange(
          start: DateTime(now.year, 1, 1),
          end: today,
        );
      case DateRangePreset.allTime:
        return DateRange(
          start: DateTime(2000, 1, 1),
          end: today,
        );
      case DateRangePreset.custom:
        return DateRange(
          start: today.subtract(const Duration(days: 29)),
          end: today,
        );
    }
  }
}

class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({
    required this.start,
    required this.end,
  });

  int get dayCount => end.difference(start).inDays + 1;

  bool contains(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(start.year, start.month, start.day);
    final endOnly = DateTime(end.year, end.month, end.day);
    return !dateOnly.isBefore(startOnly) && !dateOnly.isAfter(endOnly);
  }

  DateRange copyWith({
    DateTime? start,
    DateTime? end,
  }) {
    return DateRange(
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateRange &&
           other.start == start &&
           other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}
