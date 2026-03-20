class AdvancedTransactionFilter {
  final double? minAmount;
  final double? maxAmount;
  final DateTime? startDate;
  final DateTime? endDate;
  final Set<String> selectedCategoryIds;
  final Set<String> selectedAccountIds;

  const AdvancedTransactionFilter({
    this.minAmount,
    this.maxAmount,
    this.startDate,
    this.endDate,
    this.selectedCategoryIds = const {},
    this.selectedAccountIds = const {},
  });

  bool get isActive =>
      minAmount != null ||
      maxAmount != null ||
      startDate != null ||
      endDate != null ||
      selectedCategoryIds.isNotEmpty ||
      selectedAccountIds.isNotEmpty;

  int get activeFilterCount {
    int count = 0;
    if (minAmount != null || maxAmount != null) count++;
    if (startDate != null || endDate != null) count++;
    if (selectedCategoryIds.isNotEmpty) count++;
    if (selectedAccountIds.isNotEmpty) count++;
    return count;
  }

  AdvancedTransactionFilter copyWith({
    double? minAmount,
    bool clearMinAmount = false,
    double? maxAmount,
    bool clearMaxAmount = false,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    Set<String>? selectedCategoryIds,
    Set<String>? selectedAccountIds,
  }) {
    return AdvancedTransactionFilter(
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
      selectedAccountIds: selectedAccountIds ?? this.selectedAccountIds,
    );
  }
}
