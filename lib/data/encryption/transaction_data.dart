import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_data.freezed.dart';
part 'transaction_data.g.dart';

/// Internal data model for encrypted storage.
///
/// This model represents the data that gets serialized to JSON and then
/// encrypted before storing in the database blob. It contains duplicated
/// fields (id, dateMillis) for integrity verification during decryption.
@freezed
class TransactionData with _$TransactionData {
  const factory TransactionData({
    /// Duplicated for integrity check - must match row id
    required String id,

    /// Transaction amount (positive value)
    required double amount,

    /// Reference to the category
    required String categoryId,

    /// Reference to the account
    required String accountId,

    /// Transaction type: 'income' or 'expense'
    required String type,

    /// Optional note/memo for the transaction
    String? note,

    /// Currency code (default: USD)
    @Default('USD') String currency,

    /// Matches the database date field for integrity verification during import.
    /// Not exported as a separate CSV column to avoid duplication.
    required int dateMillis,

    /// When the transaction was created (internal metadata only).
    /// Not exported as a separate CSV column to avoid duplication.
    required int createdAtMillis,
  }) = _TransactionData;

  factory TransactionData.fromJson(Map<String, dynamic> json) =>
      _$TransactionDataFromJson(json);
}
