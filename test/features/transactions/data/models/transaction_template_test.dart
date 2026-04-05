import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/transactions/data/models/transaction.dart';
import 'package:cachium/features/transactions/data/models/transaction_template.dart';

TransactionTemplate _makeTemplate({
  String id = 'tmpl-1',
  String name = 'Test Template',
  double? amount = 50.0,
  TransactionType type = TransactionType.expense,
  String? categoryId = 'cat-1',
  String? accountId = 'acc-1',
  String? destinationAccountId,
  String? assetId,
  String? merchant = 'Store',
  String? note = 'Note',
  DateTime? createdAt,
}) {
  return TransactionTemplate(
    id: id,
    name: name,
    amount: amount,
    type: type,
    categoryId: categoryId,
    accountId: accountId,
    destinationAccountId: destinationAccountId,
    assetId: assetId,
    merchant: merchant,
    note: note,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
  );
}

void main() {
  group('TransactionTemplate equality', () {
    test('templates with same id are equal', () {
      final t1 = _makeTemplate(id: 'abc', name: 'A');
      final t2 = _makeTemplate(id: 'abc', name: 'B');
      expect(t1, equals(t2));
      expect(t1.hashCode, equals(t2.hashCode));
    });

    test('templates with different ids are not equal', () {
      final t1 = _makeTemplate(id: 'abc');
      final t2 = _makeTemplate(id: 'def');
      expect(t1, isNot(equals(t2)));
    });
  });

  group('TransactionTemplate.copyWith', () {
    test('updates fields', () {
      final t = _makeTemplate(name: 'Old');
      final copy = t.copyWith(name: 'New');
      expect(copy.name, 'New');
      expect(copy.id, t.id);
    });

    test('clearAmount sets to null', () {
      final t = _makeTemplate(amount: 100);
      final copy = t.copyWith(clearAmount: true);
      expect(copy.amount, isNull);
    });

    test('clearCategoryId sets to null', () {
      final t = _makeTemplate(categoryId: 'cat-1');
      final copy = t.copyWith(clearCategoryId: true);
      expect(copy.categoryId, isNull);
    });

    test('clearAccountId sets to null', () {
      final t = _makeTemplate(accountId: 'acc-1');
      final copy = t.copyWith(clearAccountId: true);
      expect(copy.accountId, isNull);
    });

    test('clearDestinationAccountId sets to null', () {
      final t = _makeTemplate(destinationAccountId: 'acc-2');
      final copy = t.copyWith(clearDestinationAccountId: true);
      expect(copy.destinationAccountId, isNull);
    });

    test('clearAssetId sets to null', () {
      final t = _makeTemplate(assetId: 'asset-1');
      final copy = t.copyWith(clearAssetId: true);
      expect(copy.assetId, isNull);
    });

    test('clearMerchant sets to null', () {
      final t = _makeTemplate(merchant: 'Store');
      final copy = t.copyWith(clearMerchant: true);
      expect(copy.merchant, isNull);
    });

    test('clearNote sets to null', () {
      final t = _makeTemplate(note: 'Note');
      final copy = t.copyWith(clearNote: true);
      expect(copy.note, isNull);
    });

    test('preserves unmodified fields', () {
      final t = _makeTemplate(
        amount: 100,
        categoryId: 'cat-1',
        merchant: 'Store',
      );
      final copy = t.copyWith(name: 'Updated');
      expect(copy.amount, 100);
      expect(copy.categoryId, 'cat-1');
      expect(copy.merchant, 'Store');
    });
  });
}
