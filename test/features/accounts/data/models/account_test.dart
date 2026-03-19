import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/accounts/data/models/account.dart';

Account _makeAccount({
  String id = 'acc-1',
  String name = 'Test Account',
  AccountType type = AccountType.bank,
  double balance = 1000.0,
  double initialBalance = 0.0,
  String currencyCode = 'USD',
}) {
  return Account(
    id: id,
    name: name,
    type: type,
    balance: balance,
    initialBalance: initialBalance,
    currencyCode: currencyCode,
    createdAt: DateTime.now(),
  );
}

void main() {
  group('Account validation', () {
    test('accepts valid account', () {
      expect(() => _makeAccount(), returnsNormally);
    });

    test('rejects empty name', () {
      expect(
        () => _makeAccount(name: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects invalid currency code', () {
      expect(
        () => _makeAccount(currencyCode: 'US'),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => _makeAccount(currencyCode: 'USDD'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('accepts negative balance (credit cards)', () {
      expect(
        () => _makeAccount(balance: -500.0, type: AccountType.creditCard),
        returnsNormally,
      );
    });
  });

  group('Account equality', () {
    test('accounts with same id are equal', () {
      final acc1 = _makeAccount(id: 'abc', name: 'A');
      final acc2 = _makeAccount(id: 'abc', name: 'B');
      expect(acc1, equals(acc2));
    });

    test('accounts with different ids are not equal', () {
      final acc1 = _makeAccount(id: 'abc');
      final acc2 = _makeAccount(id: 'def');
      expect(acc1, isNot(equals(acc2)));
    });
  });

  group('Account copyWith', () {
    test('creates copy with updated fields', () {
      final acc = _makeAccount(balance: 1000.0);
      final copy = acc.copyWith(balance: 2000.0);
      expect(copy.balance, 2000.0);
      expect(copy.id, acc.id);
      expect(copy.name, acc.name);
    });
  });

  group('AccountType extension', () {
    test('displayName returns correct values', () {
      expect(AccountType.bank.displayName, 'Bank');
      expect(AccountType.creditCard.displayName, 'Credit Card');
      expect(AccountType.cash.displayName, 'Cash');
      expect(AccountType.savings.displayName, 'Savings');
      expect(AccountType.investment.displayName, 'Investment');
      expect(AccountType.wallet.displayName, 'Wallet');
    });

    test('isLiability returns true only for credit card', () {
      expect(AccountType.creditCard.isLiability, isTrue);
      expect(AccountType.bank.isLiability, isFalse);
      expect(AccountType.cash.isLiability, isFalse);
    });

    test('isLiquid returns correct values', () {
      expect(AccountType.bank.isLiquid, isTrue);
      expect(AccountType.cash.isLiquid, isTrue);
      expect(AccountType.savings.isLiquid, isTrue);
      expect(AccountType.wallet.isLiquid, isTrue);
      expect(AccountType.creditCard.isLiquid, isFalse);
      expect(AccountType.investment.isLiquid, isFalse);
    });
  });
}
