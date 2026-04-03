import 'transaction_form_provider.dart';

extension TransactionFormValidator on TransactionFormState {
  String? get amountError {
    if (!showValidationErrors) return null;
    if (allowZeroAmount ? amount < 0 : amount <= 0) return 'Enter an amount';
    return null;
  }

  String? get categoryError {
    if (!showValidationErrors || isTransfer) return null;
    if (categoryId == null) return 'Select a category';
    return null;
  }

  String? get accountError {
    if (!showValidationErrors) return null;
    if (accountId == null) return 'Select an account';
    return null;
  }

  String? get sameAccountError {
    if (!isTransfer) return null;
    // Show same-account error immediately (real-time feedback)
    if (accountId != null &&
        destinationAccountId != null &&
        accountId == destinationAccountId) {
      return 'Source and destination must be different';
    }
    if (!showValidationErrors) return null;
    if (destinationAccountId == null) return 'Select a destination account';
    return null;
  }

  bool get isValid {
    final amountValid = allowZeroAmount ? amount >= 0 : amount > 0;
    if (isTransfer) {
      return amountValid &&
          accountId != null &&
          destinationAccountId != null &&
          accountId != destinationAccountId;
    }
    return amountValid && categoryId != null && accountId != null;
  }

  /// Valid and has changes (for Save button).
  bool get canSave => isValid && hasChanges;
}
