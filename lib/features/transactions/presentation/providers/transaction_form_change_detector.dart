import 'transaction_form_provider.dart';

extension TransactionFormChangeDetector on TransactionFormState {
  /// Whether currency-relevant fields changed from the original (amount, currencyCode, conversionRate).
  bool get hasCurrencyFieldChanges {
    if (!isEditing || originalTransaction == null) return true;
    final orig = originalTransaction!;
    return amount != orig.amount ||
        currencyCode != orig.currencyCode ||
        conversionRate != orig.conversionRate;
  }

  /// Check if any field has changed from original (for edit mode).
  bool get hasChanges {
    if (!isEditing || originalTransaction == null) return true; // New transaction always "has changes"
    final orig = originalTransaction!;
    return type != orig.type ||
        amount != orig.amount ||
        categoryId != orig.categoryId ||
        accountId != orig.accountId ||
        destinationAccountId != orig.destinationAccountId ||
        destinationAmount != orig.destinationAmount ||
        assetId != orig.assetId ||
        !isSameDateTime(date, orig.date) ||
        note != orig.note ||
        merchant != orig.merchant ||
        currencyCode != orig.currencyCode ||
        conversionRate != orig.conversionRate ||
        !sameTagIds(tagIds, originalTagIds);
  }
}

/// Compare dates ignoring seconds/milliseconds (only year, month, day, hour, minute).
bool isSameDateTime(DateTime a, DateTime? b) {
  if (b == null) return false;
  return a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute;
}

bool sameTagIds(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  final sortedA = List<String>.from(a)..sort();
  final sortedB = List<String>.from(b)..sort();
  for (int i = 0; i < sortedA.length; i++) {
    if (sortedA[i] != sortedB[i]) return false;
  }
  return true;
}
