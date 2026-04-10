import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/transactions/data/models/transaction.dart';
import 'package:cachium/features/transactions/presentation/providers/transaction_form_provider.dart';

Transaction _makeTx({
  String id = 'tx-1',
  TransactionType type = TransactionType.expense,
  double amount = 100,
  String categoryId = 'cat-1',
  String accountId = 'acc-1',
  String? destinationAccountId,
  double? destinationAmount,
  String? assetId,
  DateTime? date,
  String? note,
  String? merchant,
  String currencyCode = 'USD',
  double conversionRate = 1.0,
}) {
  return Transaction(
    id: id,
    type: type,
    amount: amount,
    categoryId: categoryId,
    accountId: accountId,
    destinationAccountId: destinationAccountId,
    destinationAmount: destinationAmount,
    assetId: assetId,
    date: date ?? DateTime(2026, 3, 15, 10, 30),
    note: note,
    merchant: merchant,
    currencyCode: currencyCode,
    conversionRate: conversionRate,
    mainCurrencyCode: 'USD',
    mainCurrencyAmount: amount * conversionRate,
    createdAt: DateTime(2026, 1, 1),
  );
}

TransactionFormState _editState(Transaction original, {
  TransactionType? type,
  double? amount,
  String? categoryId,
  String? accountId,
  String? destinationAccountId,
  bool clearDestinationAccountId = false,
  double? destinationAmount,
  bool clearDestinationAmount = false,
  String? assetId,
  bool clearAssetId = false,
  DateTime? date,
  String? note,
  bool clearNote = false,
  String? merchant,
  bool clearMerchant = false,
  String? currencyCode,
  double? conversionRate,
  List<String>? tagIds,
  List<String>? originalTagIds,
  bool allowZeroAmount = false,
  bool showValidationErrors = true,
}) {
  return TransactionFormState(
    type: type ?? original.type,
    amount: amount ?? original.amount,
    categoryId: categoryId ?? original.categoryId,
    accountId: accountId ?? original.accountId,
    destinationAccountId: clearDestinationAccountId
        ? null
        : (destinationAccountId ?? original.destinationAccountId),
    destinationAmount: clearDestinationAmount
        ? null
        : (destinationAmount ?? original.destinationAmount),
    assetId: clearAssetId ? null : (assetId ?? original.assetId),
    date: date ?? original.date,
    note: clearNote ? null : (note ?? original.note),
    merchant: clearMerchant ? null : (merchant ?? original.merchant),
    currencyCode: currencyCode ?? original.currencyCode,
    conversionRate: conversionRate ?? original.conversionRate,
    tagIds: tagIds ?? const [],
    originalTagIds: originalTagIds ?? const [],
    editingTransactionId: original.id,
    originalTransaction: original,
    allowZeroAmount: allowZeroAmount,
    showValidationErrors: showValidationErrors,
  );
}

void main() {
  group('TransactionFormState.canSave', () {
    test('true when valid and has changes', () {
      final original = _makeTx(amount: 100);
      final state = _editState(original, amount: 200);
      expect(state.canSave, isTrue);
    });

    test('false when valid but no changes', () {
      final original = _makeTx();
      final state = _editState(original);
      expect(state.canSave, isFalse);
    });

    test('false when has changes but invalid', () {
      final original = _makeTx();
      final state = _editState(original, amount: -1);
      expect(state.canSave, isFalse);
    });

    test('true for new transaction (always has changes)', () {
      final state = TransactionFormState(
        amount: 50,
        categoryId: 'cat-1',
        accountId: 'acc-1',
        date: DateTime(2026, 3, 15),
      );
      // New transaction (no editingTransactionId) always "has changes"
      expect(state.canSave, isTrue);
    });
  });

  group('TransactionFormChangeDetector.hasChanges', () {
    test('false when no fields changed', () {
      final original = _makeTx(
        amount: 100,
        categoryId: 'cat-1',
        accountId: 'acc-1',
        note: 'Test',
        merchant: 'Store',
      );
      final state = _editState(original);
      expect(state.hasChanges, isFalse);
    });

    test('true when amount changed', () {
      final original = _makeTx(amount: 100);
      final state = _editState(original, amount: 200);
      expect(state.hasChanges, isTrue);
    });

    test('true when type changed', () {
      final original = _makeTx(type: TransactionType.expense);
      final state = _editState(original, type: TransactionType.income);
      expect(state.hasChanges, isTrue);
    });

    test('true when categoryId changed', () {
      final original = _makeTx(categoryId: 'cat-1');
      final state = _editState(original, categoryId: 'cat-2');
      expect(state.hasChanges, isTrue);
    });

    test('true when accountId changed', () {
      final original = _makeTx(accountId: 'acc-1');
      final state = _editState(original, accountId: 'acc-2');
      expect(state.hasChanges, isTrue);
    });

    test('true when note changed', () {
      final original = _makeTx(note: 'Old');
      final state = _editState(original, note: 'New');
      expect(state.hasChanges, isTrue);
    });

    test('true when merchant changed', () {
      final original = _makeTx(merchant: 'OldStore');
      final state = _editState(original, merchant: 'NewStore');
      expect(state.hasChanges, isTrue);
    });

    test('true when currencyCode changed', () {
      final original = _makeTx(currencyCode: 'USD');
      final state = _editState(original, currencyCode: 'EUR');
      expect(state.hasChanges, isTrue);
    });

    test('true when conversionRate changed', () {
      final original = _makeTx(conversionRate: 1.0);
      final state = _editState(original, conversionRate: 0.85);
      expect(state.hasChanges, isTrue);
    });

    test('true when tagIds changed', () {
      final original = _makeTx();
      final state = _editState(
        original,
        tagIds: ['tag-1'],
        originalTagIds: [],
      );
      expect(state.hasChanges, isTrue);
    });

    test('false when tagIds same but different order', () {
      final original = _makeTx();
      final state = _editState(
        original,
        tagIds: ['b', 'a'],
        originalTagIds: ['a', 'b'],
      );
      expect(state.hasChanges, isFalse);
    });

    test('true for new transaction (no original)', () {
      final state = TransactionFormState(
        amount: 50,
        date: DateTime(2026, 3, 15),
      );
      expect(state.hasChanges, isTrue);
    });
  });

  group('TransactionFormChangeDetector.hasCurrencyFieldChanges', () {
    test('false when currency fields unchanged', () {
      final original = _makeTx(
        amount: 100,
        currencyCode: 'USD',
        conversionRate: 1.0,
      );
      final state = _editState(original);
      expect(state.hasCurrencyFieldChanges, isFalse);
    });

    test('true when amount changed', () {
      final original = _makeTx(amount: 100);
      final state = _editState(original, amount: 200);
      expect(state.hasCurrencyFieldChanges, isTrue);
    });

    test('true when currencyCode changed', () {
      final original = _makeTx(currencyCode: 'USD');
      final state = _editState(original, currencyCode: 'EUR');
      expect(state.hasCurrencyFieldChanges, isTrue);
    });

    test('true when conversionRate changed', () {
      final original = _makeTx(conversionRate: 1.0);
      final state = _editState(original, conversionRate: 0.85);
      expect(state.hasCurrencyFieldChanges, isTrue);
    });

    test('true for new transaction', () {
      final state = TransactionFormState(
        amount: 50,
        date: DateTime(2026, 3, 15),
      );
      expect(state.hasCurrencyFieldChanges, isTrue);
    });
  });

  group('TransactionFormState.isSaving', () {
    test('defaults to false', () {
      final state = TransactionFormState(date: DateTime(2026, 3, 15));
      expect(state.isSaving, isFalse);
    });

    test('copyWith toggles isSaving to true', () {
      final state = TransactionFormState(date: DateTime(2026, 3, 15));
      final saving = state.copyWith(isSaving: true);
      expect(saving.isSaving, isTrue);
      // Other fields unchanged
      expect(saving.date, state.date);
      expect(saving.amount, state.amount);
    });

    test('copyWith without isSaving preserves value', () {
      final state = TransactionFormState(date: DateTime(2026, 3, 15))
          .copyWith(isSaving: true);
      final next = state.copyWith(amount: 100);
      expect(next.isSaving, isTrue);
      expect(next.amount, 100);
    });

    test('copyWith can reset isSaving to false', () {
      final state = TransactionFormState(date: DateTime(2026, 3, 15))
          .copyWith(isSaving: true);
      final next = state.copyWith(isSaving: false);
      expect(next.isSaving, isFalse);
    });
  });
}
