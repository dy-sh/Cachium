import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/transactions/data/models/transaction.dart';

Transaction _makeTx({
  String id = 'tx-1',
  double amount = 100.0,
  TransactionType type = TransactionType.expense,
  String categoryId = 'cat-1',
  String accountId = 'acc-1',
  String? destinationAccountId,
  String currencyCode = 'USD',
  double conversionRate = 1.0,
  double? destinationAmount,
  String mainCurrencyCode = 'USD',
  double? mainCurrencyAmount,
}) {
  final now = DateTime.now();
  return Transaction(
    id: id,
    amount: amount,
    type: type,
    categoryId: categoryId,
    accountId: accountId,
    destinationAccountId: destinationAccountId,
    currencyCode: currencyCode,
    conversionRate: conversionRate,
    destinationAmount: destinationAmount,
    mainCurrencyCode: mainCurrencyCode,
    mainCurrencyAmount: mainCurrencyAmount,
    date: now,
    createdAt: now,
  );
}

void main() {
  group('Transaction validation', () {
    test('accepts valid transaction', () {
      expect(() => _makeTx(), returnsNormally);
    });

    test('rejects negative amount', () {
      expect(() => _makeTx(amount: -1.0), throwsA(isA<AssertionError>()));
    });

    test('accepts zero amount', () {
      expect(() => _makeTx(amount: 0.0), returnsNormally);
    });

    test('rejects zero conversion rate', () {
      expect(
        () => _makeTx(conversionRate: 0.0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects negative conversion rate', () {
      expect(
        () => _makeTx(conversionRate: -1.0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects infinite conversion rate', () {
      expect(
        () => _makeTx(conversionRate: double.infinity),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects NaN conversion rate', () {
      expect(
        () => _makeTx(conversionRate: double.nan),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects negative destination amount', () {
      expect(
        () => _makeTx(destinationAmount: -50.0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('accepts null destination amount', () {
      expect(() => _makeTx(destinationAmount: null), returnsNormally);
    });

    test('accepts zero destination amount', () {
      expect(() => _makeTx(destinationAmount: 0.0), returnsNormally);
    });

    test('rejects invalid currency code length', () {
      expect(
        () => _makeTx(currencyCode: 'US'),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => _makeTx(currencyCode: 'USDD'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects invalid main currency code length', () {
      expect(
        () => _makeTx(mainCurrencyCode: 'U'),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Transaction equality', () {
    test('transactions with same id are equal', () {
      final tx1 = _makeTx(id: 'abc', amount: 100.0);
      final tx2 = _makeTx(id: 'abc', amount: 200.0);
      expect(tx1, equals(tx2));
    });

    test('transactions with different ids are not equal', () {
      final tx1 = _makeTx(id: 'abc');
      final tx2 = _makeTx(id: 'def');
      expect(tx1, isNot(equals(tx2)));
    });
  });

  group('Transaction copyWith', () {
    test('creates copy with updated fields', () {
      final tx = _makeTx(amount: 100.0);
      final copy = tx.copyWith(amount: 200.0);
      expect(copy.amount, 200.0);
      expect(copy.id, tx.id);
    });

    test('clearDestinationAccountId sets to null', () {
      final tx = _makeTx(destinationAccountId: 'acc-2');
      final copy = tx.copyWith(clearDestinationAccountId: true);
      expect(copy.destinationAccountId, isNull);
    });

    test('clearNote sets to null', () {
      final now = DateTime.now();
      final tx = Transaction(
        id: 'tx-1',
        amount: 100.0,
        type: TransactionType.expense,
        categoryId: 'cat-1',
        accountId: 'acc-1',
        date: now,
        createdAt: now,
        note: 'some note',
      );
      final copy = tx.copyWith(clearNote: true);
      expect(copy.note, isNull);
    });
  });

  group('TransactionType extension', () {
    test('displayName returns correct values', () {
      expect(TransactionType.income.displayName, 'Income');
      expect(TransactionType.expense.displayName, 'Expense');
      expect(TransactionType.transfer.displayName, 'Transfer');
    });
  });

  group('TransactionGroup', () {
    test('netAmountInMainCurrency sums correctly', () {
      final group = TransactionGroup(
        date: DateTime.now(),
        transactions: [
          _makeTx(type: TransactionType.income, amount: 500.0),
          _makeTx(id: 'tx-2', type: TransactionType.expense, amount: 200.0),
          _makeTx(id: 'tx-3', type: TransactionType.transfer, amount: 100.0),
        ],
      );
      // income +500, expense -200, transfer 0 = 300
      expect(group.netAmountInMainCurrency({}, 'USD'), 300.0);
    });

    test('totalIncomeInMainCurrency filters correctly', () {
      final group = TransactionGroup(
        date: DateTime.now(),
        transactions: [
          _makeTx(type: TransactionType.income, amount: 500.0),
          _makeTx(id: 'tx-2', type: TransactionType.expense, amount: 200.0),
        ],
      );
      expect(group.totalIncomeInMainCurrency({}, 'USD'), 500.0);
    });

    test('totalExpenseInMainCurrency filters correctly', () {
      final group = TransactionGroup(
        date: DateTime.now(),
        transactions: [
          _makeTx(type: TransactionType.income, amount: 500.0),
          _makeTx(id: 'tx-2', type: TransactionType.expense, amount: 200.0),
        ],
      );
      expect(group.totalExpenseInMainCurrency({}, 'USD'), 200.0);
    });
  });
}
