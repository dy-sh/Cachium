class MerchantBreakdown {
  final String merchant;
  final double totalAmount;
  final int transactionCount;
  final String? primaryCategoryId;
  final double averageTransaction;
  final DateTime lastTransaction;
  final double? monthlyTrend;

  const MerchantBreakdown({
    required this.merchant,
    required this.totalAmount,
    required this.transactionCount,
    this.primaryCategoryId,
    required this.averageTransaction,
    required this.lastTransaction,
    this.monthlyTrend,
  });
}

class MerchantSummary {
  final List<MerchantBreakdown> topMerchants;
  final int totalMerchants;
  final double totalSpending;
  final String? topMerchant;
  final double? topMerchantAmount;

  const MerchantSummary({
    required this.topMerchants,
    required this.totalMerchants,
    required this.totalSpending,
    this.topMerchant,
    this.topMerchantAmount,
  });

  factory MerchantSummary.empty() {
    return const MerchantSummary(
      topMerchants: [],
      totalMerchants: 0,
      totalSpending: 0,
    );
  }
}
