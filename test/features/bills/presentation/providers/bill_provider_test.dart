import 'package:cachium/core/exceptions/app_exception.dart';
import 'package:cachium/core/providers/database_providers.dart';
import 'package:cachium/core/providers/exchange_rate_provider.dart';
import 'package:cachium/data/repositories/bill_repository.dart';
import 'package:cachium/features/bills/data/models/bill.dart';
import 'package:cachium/features/bills/presentation/providers/bill_provider.dart';
import 'package:cachium/features/settings/presentation/providers/settings_provider.dart';
import 'package:cachium/features/transactions/data/models/recurring_rule.dart';
import 'package:cachium/features/transactions/data/models/transaction.dart';
import 'package:cachium/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockBillRepo extends Mock implements BillRepository {}

class _RecordedTxCall {
  final double amount;
  final String currencyCode;
  final double conversionRate;
  final double? mainCurrencyAmount;
  final String mainCurrencyCode;
  final String categoryId;
  final String accountId;
  final String? note;

  _RecordedTxCall({
    required this.amount,
    required this.currencyCode,
    required this.conversionRate,
    required this.mainCurrencyAmount,
    required this.mainCurrencyCode,
    required this.categoryId,
    required this.accountId,
    required this.note,
  });
}

final _txCalls = <_RecordedTxCall>[];

class _FakeTransactionsNotifier extends TransactionsNotifier {
  @override
  Future<List<Transaction>> build() async => [];

  @override
  Future<void> addTransaction({
    required double amount,
    required TransactionType type,
    required String categoryId,
    required String accountId,
    String? destinationAccountId,
    String? assetId,
    bool isAcquisitionCost = false,
    String currencyCode = 'USD',
    double conversionRate = 1.0,
    double? destinationAmount,
    String mainCurrencyCode = 'USD',
    double? mainCurrencyAmount,
    required DateTime date,
    String? note,
    String? merchant,
  }) async {
    _txCalls.add(_RecordedTxCall(
      amount: amount,
      currencyCode: currencyCode,
      conversionRate: conversionRate,
      mainCurrencyAmount: mainCurrencyAmount,
      mainCurrencyCode: mainCurrencyCode,
      categoryId: categoryId,
      accountId: accountId,
      note: note,
    ));
  }
}

class _FakeExchangeRatesNotifier extends ExchangeRatesNotifier {
  final Map<String, double> rates;
  _FakeExchangeRatesNotifier(this.rates);

  @override
  Future<Map<String, double>> build() async => rates;
}

Bill _bill({
  String id = 'bill-1',
  String name = 'Internet',
  double amount = 50.0,
  String currencyCode = 'USD',
  String? categoryId = 'cat-utilities',
  String? accountId = 'acc-checking',
  DateTime? dueDate,
  RecurrenceFrequency frequency = RecurrenceFrequency.monthly,
  bool isPaid = false,
}) {
  return Bill(
    id: id,
    name: name,
    amount: amount,
    currencyCode: currencyCode,
    categoryId: categoryId,
    accountId: accountId,
    dueDate: dueDate ?? DateTime(2026, 4, 15),
    frequency: frequency,
    isPaid: isPaid,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late _MockBillRepo repo;

  setUpAll(() {
    registerFallbackValue(_bill());
  });

  setUp(() {
    _txCalls.clear();
    repo = _MockBillRepo();
  });

  ProviderContainer makeContainer({
    required List<Bill> initialBills,
    Map<String, double> rates = const {'EUR': 0.9},
    String mainCurrency = 'USD',
  }) {
    when(() => repo.getAllBills()).thenAnswer((_) async => initialBills);
    when(() => repo.createBill(any())).thenAnswer((_) async {});
    when(() => repo.updateBill(any())).thenAnswer((_) async {});

    final container = ProviderContainer(overrides: [
      billRepositoryProvider.overrideWithValue(repo),
      transactionsProvider.overrideWith(() => _FakeTransactionsNotifier()),
      exchangeRatesProvider
          .overrideWith(() => _FakeExchangeRatesNotifier(rates)),
      mainCurrencyCodeProvider.overrideWith((ref) => mainCurrency),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  group('BillsNotifier.markAsPaid', () {
    test(
        'createTransaction: false → bill marked paid, no transaction, next bill scheduled',
        () async {
      final bill = _bill(dueDate: DateTime(2026, 4, 15));
      final container = makeContainer(initialBills: [bill]);

      await container.read(billsProvider.future);
      await container
          .read(billsProvider.notifier)
          .markAsPaid(bill.id, createTransaction: false);

      // No transaction was created.
      expect(_txCalls, isEmpty);

      // Repository updateBill called with isPaid=true.
      final updateCaptured =
          verify(() => repo.updateBill(captureAny())).captured;
      expect(updateCaptured.length, 1);
      final updated = updateCaptured.single as Bill;
      expect(updated.isPaid, isTrue);
      expect(updated.paidDate, isNotNull);

      // A new (next) bill was created with the next due date.
      final createCaptured =
          verify(() => repo.createBill(captureAny())).captured;
      expect(createCaptured.length, 1);
      final next = createCaptured.single as Bill;
      expect(next.id, isNot(bill.id));
      expect(next.isPaid, isFalse);
      expect(next.dueDate, DateTime(2026, 5, 15));
      expect(next.amount, bill.amount);
      expect(next.frequency, bill.frequency);

      // State now contains: original (updated to paid) + next bill.
      final stateBills = container.read(billsProvider).valueOrNull!;
      expect(stateBills.length, 2);
      expect(stateBills.any((b) => b.id == bill.id && b.isPaid), isTrue);
      expect(stateBills.any((b) => b.id == next.id && !b.isPaid), isTrue);
    });

    test(
        'createTransaction: true same currency → expense recorded with bill amount',
        () async {
      final bill = _bill(amount: 75, currencyCode: 'USD');
      final container =
          makeContainer(initialBills: [bill], mainCurrency: 'USD');

      await container.read(billsProvider.future);
      await container.read(billsProvider.notifier).markAsPaid(bill.id);

      expect(_txCalls.length, 1);
      final call = _txCalls.single;
      expect(call.amount, 75);
      expect(call.currencyCode, 'USD');
      expect(call.mainCurrencyCode, 'USD');
      expect(call.conversionRate, 1.0);
      expect(call.mainCurrencyAmount, 75);
      expect(call.categoryId, bill.categoryId);
      expect(call.accountId, bill.accountId);
      expect(call.note, contains(bill.name));
    });

    test(
        'createTransaction: true cross-currency → conversionRate and mainCurrencyAmount populated from rates',
        () async {
      // Bill in EUR, main currency USD, EUR rate 0.9 (1 USD = 0.9 EUR).
      // Expected conversionRate = 1 / 0.9 ≈ 1.1111…
      // Expected mainCurrencyAmount = 100 * 1.1111… ≈ 111.11
      final bill = _bill(amount: 100, currencyCode: 'EUR');
      final container = makeContainer(
        initialBills: [bill],
        mainCurrency: 'USD',
        rates: {'EUR': 0.9},
      );

      await container.read(billsProvider.future);
      await container.read(exchangeRatesProvider.future);
      await container.read(billsProvider.notifier).markAsPaid(bill.id);

      expect(_txCalls.length, 1);
      final call = _txCalls.single;
      expect(call.amount, 100);
      expect(call.currencyCode, 'EUR');
      expect(call.mainCurrencyCode, 'USD');
      expect(call.conversionRate, closeTo(1 / 0.9, 1e-9));
      expect(call.mainCurrencyAmount, closeTo(111.11, 0.01));
    });

    test(
        'createTransaction: true but bill has no accountId → no transaction created',
        () async {
      final bill = _bill(accountId: null);
      final container = makeContainer(initialBills: [bill]);

      await container.read(billsProvider.future);
      await container.read(billsProvider.notifier).markAsPaid(bill.id);

      expect(_txCalls, isEmpty);
      // The bill is still marked paid and a next bill is still generated.
      verify(() => repo.updateBill(any())).called(1);
      verify(() => repo.createBill(any())).called(1);
    });

    test('next bill carries over name, amount, frequency, and recurring fields',
        () async {
      final bill = _bill(
        name: 'Gym Membership',
        amount: 30,
        frequency: RecurrenceFrequency.monthly,
        dueDate: DateTime(2026, 4, 1),
      );
      final container = makeContainer(initialBills: [bill]);

      await container.read(billsProvider.future);
      await container
          .read(billsProvider.notifier)
          .markAsPaid(bill.id, createTransaction: false);

      final next =
          verify(() => repo.createBill(captureAny())).captured.single as Bill;
      expect(next.name, 'Gym Membership');
      expect(next.amount, 30);
      expect(next.frequency, RecurrenceFrequency.monthly);
      expect(next.dueDate, DateTime(2026, 5, 1));
      expect(next.categoryId, bill.categoryId);
      expect(next.accountId, bill.accountId);
    });

    test('repository createBill failure rolls back the next-bill state',
        () async {
      final bill = _bill();
      final container = makeContainer(initialBills: [bill]);
      // Override createBill to fail — must come AFTER makeContainer which
      // installs the default thenAnswer stub.
      when(() => repo.createBill(any()))
          .thenThrow(Exception('db write failed'));
      await container.read(billsProvider.future);

      await expectLater(
        container
            .read(billsProvider.notifier)
            .markAsPaid(bill.id, createTransaction: false),
        throwsA(isA<RepositoryException>()),
      );

      // The original bill is still marked paid (updateBill succeeded), but
      // no extra bill was added to state because createBill failed and
      // OptimisticAsyncNotifier rolled the addBill optimistic update back.
      final stateBills = container.read(billsProvider).valueOrNull!;
      expect(stateBills.length, 1);
      expect(stateBills.single.id, bill.id);
      expect(stateBills.single.isPaid, isTrue);
    });
  });

  group('derived bill providers', () {
    test('upcomingBillsProvider includes unpaid bills due in the next 30 days',
        () {
      final now = DateTime.now();
      final bills = [
        _bill(id: 'soon', dueDate: now.add(const Duration(days: 5))),
        _bill(id: 'later', dueDate: now.add(const Duration(days: 60))),
        _bill(id: 'past', dueDate: now.subtract(const Duration(days: 5))),
        _bill(
            id: 'paid-soon',
            dueDate: now.add(const Duration(days: 3)),
            isPaid: true),
      ];
      final container = makeContainer(initialBills: bills);

      // Trigger build
      container.read(billsProvider);
      // Read after async build settles
      return container.read(billsProvider.future).then((_) {
        final upcoming = container.read(upcomingBillsProvider);
        expect(upcoming.map((b) => b.id), ['soon']);
      });
    });

    test('overdueBillsProvider returns only unpaid past-due bills', () async {
      final now = DateTime.now();
      final bills = [
        _bill(id: 'overdue', dueDate: now.subtract(const Duration(days: 2))),
        _bill(
            id: 'overdue-paid',
            dueDate: now.subtract(const Duration(days: 2)),
            isPaid: true),
        _bill(id: 'future', dueDate: now.add(const Duration(days: 5))),
      ];
      final container = makeContainer(initialBills: bills);
      await container.read(billsProvider.future);

      final overdue = container.read(overdueBillsProvider);
      expect(overdue.map((b) => b.id), ['overdue']);
    });
  });
}
