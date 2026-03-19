import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_data.freezed.dart';
part 'account_data.g.dart';

/// Internal data model for encrypted account storage.
///
/// This model represents the data that gets serialized to JSON and then
/// encrypted before storing in the database blob. It contains duplicated
/// fields (id, createdAtMillis) for integrity verification during decryption.
@freezed
class AccountData with _$AccountData {
  const factory AccountData({
    /// Duplicated for integrity check - must match row id
    required String id,

    /// Account name
    required String name,

    /// Account type: 'bank', 'creditCard', 'cash', 'savings', 'investment', 'wallet'
    required String type,

    /// Current balance
    required double balance,

    /// Initial balance when account was created (for recalculation)
    @Default(0.0) double initialBalance,

    /// Custom color value (optional) - stored as int for serialization
    int? customColorValue,

    /// Custom icon code point (optional)
    int? customIconCodePoint,

    /// Custom icon font family (optional, e.g. 'lucide')
    String? customIconFontFamily,

    /// Custom icon font package (optional, e.g. 'lucide_icons')
    String? customIconFontPackage,

    /// Currency code (ISO 4217)
    @Default('USD') String currencyCode,

    /// Sort order for display ordering
    @Default(0) int sortOrder,

    /// Matches the database createdAt field for integrity verification during import.
    /// Not exported as a separate CSV column to avoid duplication.
    required int createdAtMillis,
  }) = _AccountData;

  factory AccountData.fromJson(Map<String, dynamic> json) =>
      _$AccountDataFromJson(json);
}
