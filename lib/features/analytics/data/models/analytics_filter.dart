import '../../../transactions/data/models/transaction.dart';
import 'date_range_preset.dart';

enum AnalyticsTypeFilter {
  all,
  income,
  expense,
}

extension AnalyticsTypeFilterExtension on AnalyticsTypeFilter {
  String get displayName {
    switch (this) {
      case AnalyticsTypeFilter.all:
        return 'All';
      case AnalyticsTypeFilter.income:
        return 'Income';
      case AnalyticsTypeFilter.expense:
        return 'Expense';
    }
  }

  bool matches(TransactionType type) {
    switch (this) {
      case AnalyticsTypeFilter.all:
        return true;
      case AnalyticsTypeFilter.income:
        return type == TransactionType.income;
      case AnalyticsTypeFilter.expense:
        return type == TransactionType.expense;
    }
  }
}

class AnalyticsFilter {
  final DateRange dateRange;
  final DateRangePreset preset;
  final Set<String> selectedAccountIds;
  final Set<String> selectedCategoryIds;
  final AnalyticsTypeFilter typeFilter;

  const AnalyticsFilter({
    required this.dateRange,
    this.preset = DateRangePreset.last30Days,
    this.selectedAccountIds = const {},
    this.selectedCategoryIds = const {},
    this.typeFilter = AnalyticsTypeFilter.all,
  });

  factory AnalyticsFilter.initial() {
    final preset = DateRangePreset.last30Days;
    return AnalyticsFilter(
      dateRange: preset.getDateRange(),
      preset: preset,
    );
  }

  bool get hasAccountFilter => selectedAccountIds.isNotEmpty;
  bool get hasCategoryFilter => selectedCategoryIds.isNotEmpty;

  AnalyticsFilter copyWith({
    DateRange? dateRange,
    DateRangePreset? preset,
    Set<String>? selectedAccountIds,
    Set<String>? selectedCategoryIds,
    AnalyticsTypeFilter? typeFilter,
  }) {
    return AnalyticsFilter(
      dateRange: dateRange ?? this.dateRange,
      preset: preset ?? this.preset,
      selectedAccountIds: selectedAccountIds ?? this.selectedAccountIds,
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
      typeFilter: typeFilter ?? this.typeFilter,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalyticsFilter &&
        other.dateRange == dateRange &&
        other.preset == preset &&
        _setEquals(other.selectedAccountIds, selectedAccountIds) &&
        _setEquals(other.selectedCategoryIds, selectedCategoryIds) &&
        other.typeFilter == typeFilter;
  }

  bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  @override
  int get hashCode => Object.hash(
        dateRange,
        preset,
        Object.hashAll(selectedAccountIds),
        Object.hashAll(selectedCategoryIds),
        typeFilter,
      );
}
