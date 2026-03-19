import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/core/utils/balance_calculation.dart';
import 'package:cachium/features/transactions/data/models/transaction.dart';

Transaction _makeTx({
  String id = 'tx-1',
  double amount = 100.0,
  TransactionType type = TransactionType.expense,
  String accountId = 'acc-1',
  String? destinationAccountId,
  double? destinationAmount,
}) {
  final now = DateTime.now();
  return Transaction(
    id: id,
    amount: amount,
    type: type,
    categoryId: 'cat-1',
    accountId: accountId,
    destinationAccountId: destinationAccountId,
    destinationAmount: destinationAmount,
    date: now,
    createdAt: now,
  );
}

void main() {
  group('calculateAccountDeltas', () {
    test('returns empty map for empty list', () {
      expect(calculateAccountDeltas([]), isEmpty);
    });

    test('income credits the account', () {
      final txs = [
        _makeTx(
          type: TransactionType.income,
          amount: 500.0,
          accountId: 'acc-1',
        ),
      ];
      final deltas = calculateAccountDeltas(txs);
      expect(deltas['acc-1'], 500.0);
    });

    test('expense debits the account', () {
      final txs = [
        _makeTx(
          type: TransactionType.expense,
          amount: 200.0,
          accountId: 'acc-1',
        ),
      ];
      final deltas = calculateAccountDeltas(txs);
      expect(deltas['acc-1'], -200.0);
    });

    test('transfer debits source and credits destination with same amount', () {
      final txs = [
        _makeTx(
          id: 'tx-transfer',
          type: TransactionType.transfer,
          amount: 300.0,
          accountId: 'acc-src',
          destinationAccountId: 'acc-dst',
        ),
      ];
      final deltas = calculateAccountDeltas(txs);
      expect(deltas['acc-src'], -300.0);
      expect(deltas['acc-dst'], 300.0);
    });

    test('transfer uses destinationAmount for cross-currency credit', () {
      final txs = [
        _makeTx(
          id: 'tx-xfer',
          type: TransactionType.transfer,
          amount: 100.0,
          accountId: 'acc-usd',
          destinationAccountId: 'acc-eur',
          destinationAmount: 90.0,
        ),
      ];
      final deltas = calculateAccountDeltas(txs);
      expect(deltas['acc-usd'], -100.0);
      expect(deltas['acc-eur'], 90.0);
    });

    test('transfer without destinationAccountId only debits source', () {
      final txs = [
        _makeTx(
          id: 'tx-no-dest',
          type: TransactionType.transfer,
          amount: 50.0,
          accountId: 'acc-1',
          destinationAccountId: null,
        ),
      ];
      final deltas = calculateAccountDeltas(txs);
      expect(deltas['acc-1'], -50.0);
      expect(deltas.containsKey(null), isFalse);
      expect(deltas.length, 1);
    });

    test('multiple transactions on the same account accumulate', () {
      final txs = [
        _makeTx(
          id: 'tx-1',
          type: TransactionType.income,
          amount: 1000.0,
          accountId: 'acc-1',
        ),
        _makeTx(
          id: 'tx-2',
          type: TransactionType.expense,
          amount: 250.0,
          accountId: 'acc-1',
        ),
        _makeTx(
          id: 'tx-3',
          type: TransactionType.expense,
          amount: 150.0,
          accountId: 'acc-1',
        ),
      ];
      final deltas = calculateAccountDeltas(txs);
      // 1000 - 250 - 150 = 600
      expect(deltas['acc-1'], 600.0);
    });

    test('mixed types across multiple accounts', () {
      final txs = [
        _makeTx(
          id: 'tx-1',
          type: TransactionType.income,
          amount: 500.0,
          accountId: 'acc-1',
        ),
        _makeTx(
          id: 'tx-2',
          type: TransactionType.expense,
          amount: 100.0,
          accountId: 'acc-2',
        ),
        _makeTx(
          id: 'tx-3',
          type: TransactionType.transfer,
          amount: 200.0,
          accountId: 'acc-1',
          destinationAccountId: 'acc-2',
        ),
      ];
      final deltas = calculateAccountDeltas(txs);
      // acc-1: +500 - 200 = 300
      expect(deltas['acc-1'], 300.0);
      // acc-2: -100 + 200 = 100
      expect(deltas['acc-2'], 100.0);
    });

    test('deltas are rounded to 2 decimal places', () {
      final txs = [
        _makeTx(
          id: 'tx-1',
          type: TransactionType.income,
          amount: 1.001,
          accountId: 'acc-1',
        ),
        _makeTx(
          id: 'tx-2',
          type: TransactionType.income,
          amount: 2.002,
          accountId: 'acc-1',
        ),
      ];
      final deltas = calculateAccountDeltas(txs);
      // 1.001 + 2.002 = 3.003 -> rounded to 3.0
      expect(deltas['acc-1'], 3.0);
    });

    test('zero amount transactions produce zero deltas', () {
      final txs = [
        _makeTx(
          id: 'tx-1',
          type: TransactionType.income,
          amount: 0.0,
          accountId: 'acc-1',
        ),
      ];
      final deltas = calculateAccountDeltas(txs);
      expect(deltas['acc-1'], 0.0);
    });
  });
}
