class ChartDrillDown {
  final String? categoryId;
  final String? accountId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? transactionType; // 'income' or 'expense'

  const ChartDrillDown({
    this.categoryId,
    this.accountId,
    this.startDate,
    this.endDate,
    this.transactionType,
  });

  Map<String, String> toQueryParameters() {
    final params = <String, String>{};
    if (categoryId != null) params['categoryId'] = categoryId!;
    if (accountId != null) params['accountId'] = accountId!;
    if (startDate != null) params['startDate'] = startDate!.toIso8601String();
    if (endDate != null) params['endDate'] = endDate!.toIso8601String();
    if (transactionType != null) params['type'] = transactionType!;
    return params;
  }
}
