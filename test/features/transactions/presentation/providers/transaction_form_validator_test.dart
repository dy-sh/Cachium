import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/transactions/data/models/transaction.dart';
import 'package:cachium/features/transactions/presentation/providers/transaction_form_provider.dart';

TransactionFormState _makeState({
  TransactionType type = TransactionType.expense,
  double amount = 100,
  String? categoryId = 'cat-1',
  String? accountId = 'acc-1',
  String? destinationAccountId,
  bool allowZeroAmount = false,
  bool showValidationErrors = true,
}) {
  return TransactionFormState(
    type: type,
    amount: amount,
    categoryId: categoryId,
    accountId: accountId,
    destinationAccountId: destinationAccountId,
    allowZeroAmount: allowZeroAmount,
    showValidationErrors: showValidationErrors,
    date: DateTime(2026, 3, 15),
  );
}

void main() {
  group('TransactionFormValidator.amountError', () {
    test('no error when validation hidden', () {
      final state = _makeState(amount: 0, showValidationErrors: false);
      expect(state.amountError, isNull);
    });

    test('error when amount is 0 and zero not allowed', () {
      final state = _makeState(amount: 0, allowZeroAmount: false);
      expect(state.amountError, isNotNull);
    });

    test('no error when amount is 0 and zero allowed', () {
      final state = _makeState(amount: 0, allowZeroAmount: true);
      expect(state.amountError, isNull);
    });

    test('error when amount is negative', () {
      final state = _makeState(amount: -1);
      expect(state.amountError, isNotNull);
    });

    test('error when amount is negative even with allowZero', () {
      final state = _makeState(amount: -1, allowZeroAmount: true);
      expect(state.amountError, isNotNull);
    });

    test('no error for positive amount', () {
      final state = _makeState(amount: 50);
      expect(state.amountError, isNull);
    });
  });

  group('TransactionFormValidator.categoryError', () {
    test('no error when validation hidden', () {
      final state = _makeState(categoryId: null, showValidationErrors: false);
      expect(state.categoryError, isNull);
    });

    test('no error for transfers (category not required)', () {
      final state = _makeState(
        type: TransactionType.transfer,
        categoryId: null,
      );
      expect(state.categoryError, isNull);
    });

    test('error when categoryId is null for expense', () {
      final state = _makeState(
        type: TransactionType.expense,
        categoryId: null,
      );
      expect(state.categoryError, isNotNull);
    });

    test('error when categoryId is null for income', () {
      final state = _makeState(
        type: TransactionType.income,
        categoryId: null,
      );
      expect(state.categoryError, isNotNull);
    });

    test('no error when categoryId is set', () {
      final state = _makeState(categoryId: 'cat-1');
      expect(state.categoryError, isNull);
    });
  });

  group('TransactionFormValidator.accountError', () {
    test('no error when validation hidden', () {
      final state = _makeState(accountId: null, showValidationErrors: false);
      expect(state.accountError, isNull);
    });

    test('error when accountId is null', () {
      final state = _makeState(accountId: null);
      expect(state.accountError, isNotNull);
    });

    test('no error when accountId is set', () {
      final state = _makeState(accountId: 'acc-1');
      expect(state.accountError, isNull);
    });
  });

  group('TransactionFormValidator.sameAccountError', () {
    test('null for non-transfers', () {
      final state = _makeState(type: TransactionType.expense);
      expect(state.sameAccountError, isNull);
    });

    test('error when same source and destination (real-time, no showValidation needed)', () {
      final state = _makeState(
        type: TransactionType.transfer,
        accountId: 'acc-1',
        destinationAccountId: 'acc-1',
        showValidationErrors: false,
      );
      expect(state.sameAccountError, isNotNull);
      expect(state.sameAccountError, contains('different'));
    });

    test('no error when different accounts', () {
      final state = _makeState(
        type: TransactionType.transfer,
        accountId: 'acc-1',
        destinationAccountId: 'acc-2',
      );
      expect(state.sameAccountError, isNull);
    });

    test('error when destination null and validation shown', () {
      final state = _makeState(
        type: TransactionType.transfer,
        accountId: 'acc-1',
        destinationAccountId: null,
        showValidationErrors: true,
      );
      expect(state.sameAccountError, isNotNull);
      expect(state.sameAccountError, contains('destination'));
    });

    test('no error when destination null and validation hidden', () {
      final state = _makeState(
        type: TransactionType.transfer,
        accountId: 'acc-1',
        destinationAccountId: null,
        showValidationErrors: false,
      );
      expect(state.sameAccountError, isNull);
    });
  });

  group('TransactionFormValidator.isValid', () {
    test('valid expense', () {
      final state = _makeState(
        type: TransactionType.expense,
        amount: 50,
        categoryId: 'cat-1',
        accountId: 'acc-1',
      );
      expect(state.isValid, isTrue);
    });

    test('valid income', () {
      final state = _makeState(
        type: TransactionType.income,
        amount: 50,
        categoryId: 'cat-1',
        accountId: 'acc-1',
      );
      expect(state.isValid, isTrue);
    });

    test('valid transfer', () {
      final state = _makeState(
        type: TransactionType.transfer,
        amount: 50,
        accountId: 'acc-1',
        destinationAccountId: 'acc-2',
      );
      expect(state.isValid, isTrue);
    });

    test('invalid: zero amount when not allowed', () {
      final state = _makeState(amount: 0, allowZeroAmount: false);
      expect(state.isValid, isFalse);
    });

    test('valid: zero amount when allowed', () {
      final state = _makeState(amount: 0, allowZeroAmount: true);
      expect(state.isValid, isTrue);
    });

    test('invalid: negative amount', () {
      final state = _makeState(amount: -1);
      expect(state.isValid, isFalse);
    });

    test('invalid: missing category for expense', () {
      final state = _makeState(
        type: TransactionType.expense,
        categoryId: null,
      );
      expect(state.isValid, isFalse);
    });

    test('invalid: missing account', () {
      final state = _makeState(accountId: null);
      expect(state.isValid, isFalse);
    });

    test('invalid transfer: same accounts', () {
      final state = _makeState(
        type: TransactionType.transfer,
        accountId: 'acc-1',
        destinationAccountId: 'acc-1',
      );
      expect(state.isValid, isFalse);
    });

    test('invalid transfer: missing destination', () {
      final state = _makeState(
        type: TransactionType.transfer,
        accountId: 'acc-1',
        destinationAccountId: null,
      );
      expect(state.isValid, isFalse);
    });

    test('transfer: category not required', () {
      final state = _makeState(
        type: TransactionType.transfer,
        amount: 50,
        categoryId: null,
        accountId: 'acc-1',
        destinationAccountId: 'acc-2',
      );
      expect(state.isValid, isTrue);
    });
  });

  group('TransactionFormState properties', () {
    test('isTransfer true for transfer type', () {
      final state = _makeState(type: TransactionType.transfer);
      expect(state.isTransfer, isTrue);
    });

    test('isTransfer false for expense', () {
      final state = _makeState(type: TransactionType.expense);
      expect(state.isTransfer, isFalse);
    });

    test('isEditing true when editingTransactionId set', () {
      final state = TransactionFormState(
        date: DateTime(2026, 3, 15),
        editingTransactionId: 'tx-1',
      );
      expect(state.isEditing, isTrue);
    });

    test('isEditing false when editingTransactionId null', () {
      final state = _makeState();
      expect(state.isEditing, isFalse);
    });
  });
}
