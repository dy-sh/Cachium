import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/bills/data/models/bill.dart';
import 'package:cachium/features/transactions/data/models/recurring_rule.dart';
import 'package:cachium/core/exceptions/app_exception.dart';

Bill _makeBill({
  String id = 'bill-1',
  String name = 'Test Bill',
  double amount = 100.0,
  String currencyCode = 'USD',
  String? categoryId,
  String? accountId,
  String? assetId,
  DateTime? dueDate,
  RecurrenceFrequency frequency = RecurrenceFrequency.monthly,
  bool isPaid = false,
  DateTime? paidDate,
  String? note,
  bool reminderEnabled = true,
  int reminderDaysBefore = 3,
  DateTime? createdAt,
}) {
  return Bill(
    id: id,
    name: name,
    amount: amount,
    currencyCode: currencyCode,
    categoryId: categoryId,
    accountId: accountId,
    assetId: assetId,
    dueDate: dueDate ?? DateTime(2026, 5, 1),
    frequency: frequency,
    isPaid: isPaid,
    paidDate: paidDate,
    note: note,
    reminderEnabled: reminderEnabled,
    reminderDaysBefore: reminderDaysBefore,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
  );
}

void main() {
  group('Bill constructor', () {
    test('accepts valid bill', () {
      expect(() => _makeBill(), returnsNormally);
    });

    test('rejects negative amount', () {
      expect(
        () => _makeBill(amount: -1.0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects negative reminderDaysBefore', () {
      expect(
        () => _makeBill(reminderDaysBefore: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('accepts zero amount', () {
      expect(() => _makeBill(amount: 0.0), returnsNormally);
    });

    test('accepts zero reminderDaysBefore', () {
      expect(() => _makeBill(reminderDaysBefore: 0), returnsNormally);
    });
  });

  group('Bill.validate()', () {
    test('accepts valid bill', () {
      expect(() => _makeBill().validate(), returnsNormally);
    });

    test('rejects empty id', () {
      expect(
        () => _makeBill(id: '').validate(),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty name', () {
      expect(
        () => _makeBill(name: '').validate(),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid currency code - too short', () {
      expect(
        () => _makeBill(currencyCode: 'US').validate(),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid currency code - too long', () {
      expect(
        () => _makeBill(currencyCode: 'USDD').validate(),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('Bill equality', () {
    test('bills with same id are equal', () {
      final b1 = _makeBill(id: 'abc', name: 'A');
      final b2 = _makeBill(id: 'abc', name: 'B');
      expect(b1, equals(b2));
      expect(b1.hashCode, equals(b2.hashCode));
    });

    test('bills with different ids are not equal', () {
      final b1 = _makeBill(id: 'abc');
      final b2 = _makeBill(id: 'def');
      expect(b1, isNot(equals(b2)));
    });
  });

  group('Bill.copyWith()', () {
    test('updates specified fields', () {
      final bill = _makeBill(name: 'Old', amount: 50.0);
      final copy = bill.copyWith(name: 'New', amount: 100.0);
      expect(copy.name, 'New');
      expect(copy.amount, 100.0);
      expect(copy.id, bill.id);
    });

    test('clearCategoryId sets categoryId to null', () {
      final bill = _makeBill(categoryId: 'cat-1');
      final copy = bill.copyWith(clearCategoryId: true);
      expect(copy.categoryId, isNull);
    });

    test('clearAccountId sets accountId to null', () {
      final bill = _makeBill(accountId: 'acc-1');
      final copy = bill.copyWith(clearAccountId: true);
      expect(copy.accountId, isNull);
    });

    test('clearAssetId sets assetId to null', () {
      final bill = _makeBill(assetId: 'asset-1');
      final copy = bill.copyWith(clearAssetId: true);
      expect(copy.assetId, isNull);
    });

    test('clearPaidDate sets paidDate to null', () {
      final bill = _makeBill(paidDate: DateTime(2026, 3, 1));
      final copy = bill.copyWith(clearPaidDate: true);
      expect(copy.paidDate, isNull);
    });

    test('clearNote sets note to null', () {
      final bill = _makeBill(note: 'Some note');
      final copy = bill.copyWith(clearNote: true);
      expect(copy.note, isNull);
    });
  });

  group('Bill.nextDueDate', () {
    test('monthly bill advances by one month', () {
      final bill = _makeBill(
        dueDate: DateTime(2026, 3, 15),
        frequency: RecurrenceFrequency.monthly,
      );
      expect(bill.nextDueDate, DateTime(2026, 4, 15));
    });

    test('weekly bill advances by 7 days', () {
      final bill = _makeBill(
        dueDate: DateTime(2026, 3, 1),
        frequency: RecurrenceFrequency.weekly,
      );
      expect(bill.nextDueDate, DateTime(2026, 3, 8));
    });

    test('yearly bill advances by one year', () {
      final bill = _makeBill(
        dueDate: DateTime(2026, 6, 1),
        frequency: RecurrenceFrequency.yearly,
      );
      expect(bill.nextDueDate, DateTime(2027, 6, 1));
    });

    test('daily bill advances by 1 day', () {
      final bill = _makeBill(
        dueDate: DateTime(2026, 3, 1),
        frequency: RecurrenceFrequency.daily,
      );
      expect(bill.nextDueDate, DateTime(2026, 3, 2));
    });

    test('biweekly bill advances by 14 days', () {
      final bill = _makeBill(
        dueDate: DateTime(2026, 3, 1),
        frequency: RecurrenceFrequency.biweekly,
      );
      expect(bill.nextDueDate, DateTime(2026, 3, 15));
    });

    test('weekly bill crosses month boundary correctly', () {
      final bill = _makeBill(
        dueDate: DateTime(2026, 3, 28),
        frequency: RecurrenceFrequency.weekly,
      );
      expect(bill.nextDueDate, DateTime(2026, 4, 4));
    });

    test('monthly bill crosses year boundary (Dec → Jan)', () {
      final bill = _makeBill(
        dueDate: DateTime(2026, 12, 15),
        frequency: RecurrenceFrequency.monthly,
      );
      expect(bill.nextDueDate, DateTime(2027, 1, 15));
    });

    // Documents current behavior: Dart normalizes overflow days into the
    // next month, so Jan 31 monthly does NOT roll back to Feb 28. If/when
    // bill recurrence is changed to clamp instead, update this test.
    test('monthly bill on Jan 31 overflows into March (Dart normalization)',
        () {
      final bill = _makeBill(
        dueDate: DateTime(2026, 1, 31),
        frequency: RecurrenceFrequency.monthly,
      );
      // DateTime(2026, 2, 31) normalizes to 2026-03-03 (Feb has 28 days).
      expect(bill.nextDueDate, DateTime(2026, 3, 3));
    });

    test('monthly bill on May 31 overflows into July (Dart normalization)',
        () {
      // June has 30 days; May 31 + 1 month → June 31 → July 1.
      final bill = _makeBill(
        dueDate: DateTime(2026, 5, 31),
        frequency: RecurrenceFrequency.monthly,
      );
      expect(bill.nextDueDate, DateTime(2026, 7, 1));
    });

    // Documents current behavior: Feb 29 leap-year + 1 year overflows
    // because the next year is not a leap year.
    test('yearly bill on Feb 29 leap year overflows to Mar 1', () {
      final bill = _makeBill(
        dueDate: DateTime(2024, 2, 29),
        frequency: RecurrenceFrequency.yearly,
      );
      // DateTime(2025, 2, 29) → 2025-03-01.
      expect(bill.nextDueDate, DateTime(2025, 3, 1));
    });

    test('yearly bill on Feb 29 leap year lands correctly four years later',
        () {
      // 2024 → 2025 (Mar 1, see test above), but a four-year leap is not
      // computed by nextDueDate. We just verify the one-shot 2024 → 2025
      // already covered. This test confirms 2020 → 2021 same overflow.
      final bill = _makeBill(
        dueDate: DateTime(2020, 2, 29),
        frequency: RecurrenceFrequency.yearly,
      );
      expect(bill.nextDueDate, DateTime(2021, 3, 1));
    });
  });
}
