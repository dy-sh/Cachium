import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/analytics_filter.dart';
import '../../data/models/date_range_preset.dart';

class AnalyticsFilterNotifier extends Notifier<AnalyticsFilter> {
  @override
  AnalyticsFilter build() {
    return AnalyticsFilter.initial();
  }

  void setDateRangePreset(DateRangePreset preset) {
    state = state.copyWith(
      preset: preset,
      dateRange: preset.getDateRange(),
    );
  }

  void setCustomDateRange(DateRange range) {
    state = state.copyWith(
      preset: DateRangePreset.custom,
      dateRange: range,
    );
  }

  void toggleAccount(String accountId) {
    final newSet = Set<String>.from(state.selectedAccountIds);
    if (newSet.contains(accountId)) {
      newSet.remove(accountId);
    } else {
      newSet.add(accountId);
    }
    state = state.copyWith(selectedAccountIds: newSet);
  }

  void setAccounts(Set<String> accountIds) {
    state = state.copyWith(selectedAccountIds: accountIds);
  }

  void clearAccountFilter() {
    state = state.copyWith(selectedAccountIds: {});
  }

  void toggleCategory(String categoryId) {
    final newSet = Set<String>.from(state.selectedCategoryIds);
    if (newSet.contains(categoryId)) {
      newSet.remove(categoryId);
    } else {
      newSet.add(categoryId);
    }
    state = state.copyWith(selectedCategoryIds: newSet);
  }

  void setCategories(Set<String> categoryIds) {
    state = state.copyWith(selectedCategoryIds: categoryIds);
  }

  void clearCategoryFilter() {
    state = state.copyWith(selectedCategoryIds: {});
  }

  void setTypeFilter(AnalyticsTypeFilter typeFilter) {
    state = state.copyWith(typeFilter: typeFilter);
  }

  void shiftDateRange(int direction) {
    final range = state.dateRange;
    final preset = state.preset;

    final monthShift = _getMonthShift(preset);
    if (monthShift != null) {
      final newStart = DateTime(
        range.start.year,
        range.start.month + monthShift * direction,
        1,
      );
      final newEnd = DateTime(
        newStart.year,
        newStart.month + monthShift,
        0,
        23, 59, 59,
      );
      state = state.copyWith(
        preset: preset,
        dateRange: DateRange(start: newStart, end: newEnd),
      );
      return;
    }

    // Day-based presets: shift by range length
    final shift = Duration(days: range.end.difference(range.start).inDays + 1);
    final newStart = direction > 0
        ? range.start.add(shift)
        : range.start.subtract(shift);
    final newEnd = direction > 0
        ? range.end.add(shift)
        : range.end.subtract(shift);

    state = state.copyWith(
      preset: preset,
      dateRange: DateRange(start: newStart, end: newEnd),
    );
  }

  /// Returns the number of months for month/year-aligned presets, or null.
  int? _getMonthShift(DateRangePreset preset) {
    switch (preset) {
      case DateRangePreset.thisMonth:
      case DateRangePreset.lastMonth:
        return 1;
      case DateRangePreset.last3Months:
        return 3;
      case DateRangePreset.last6Months:
        return 6;
      case DateRangePreset.last12Months:
        return 12;
      case DateRangePreset.thisYear:
        return 12;
      default:
        return null;
    }
  }

  void resetFilters() {
    state = AnalyticsFilter.initial();
  }
}

final analyticsFilterProvider =
    NotifierProvider<AnalyticsFilterNotifier, AnalyticsFilter>(() {
  return AnalyticsFilterNotifier();
});
