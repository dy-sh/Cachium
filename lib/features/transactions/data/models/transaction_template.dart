import 'transaction.dart';

class TransactionTemplate {
  final String id;
  final String name;
  final double? amount;
  final TransactionType type;
  final String? categoryId;
  final String? accountId;
  final String? destinationAccountId;
  final String? assetId;
  final String? merchant;
  final String? note;
  final DateTime createdAt;

  const TransactionTemplate({
    required this.id,
    required this.name,
    this.amount,
    required this.type,
    this.categoryId,
    this.accountId,
    this.destinationAccountId,
    this.assetId,
    this.merchant,
    this.note,
    required this.createdAt,
  });

  TransactionTemplate copyWith({
    String? id,
    String? name,
    double? amount,
    bool clearAmount = false,
    TransactionType? type,
    String? categoryId,
    bool clearCategoryId = false,
    String? accountId,
    bool clearAccountId = false,
    String? destinationAccountId,
    bool clearDestinationAccountId = false,
    String? assetId,
    bool clearAssetId = false,
    String? merchant,
    bool clearMerchant = false,
    String? note,
    bool clearNote = false,
    DateTime? createdAt,
  }) {
    return TransactionTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: clearAmount ? null : (amount ?? this.amount),
      type: type ?? this.type,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      destinationAccountId: clearDestinationAccountId
          ? null
          : (destinationAccountId ?? this.destinationAccountId),
      assetId: clearAssetId ? null : (assetId ?? this.assetId),
      merchant: clearMerchant ? null : (merchant ?? this.merchant),
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionTemplate && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
