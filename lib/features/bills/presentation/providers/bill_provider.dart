import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/providers/exchange_rate_provider.dart';
import '../../../../core/providers/optimistic_notifier.dart';
import '../../../../core/utils/currency_conversion.dart';
import '../../../settings/presentation/providers/settings_provider.dart'
    show mainCurrencyCodeProvider;
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/bill.dart';

class BillsNotifier extends AsyncNotifier<List<Bill>>
    with OptimisticAsyncNotifier<Bill> {
  final _uuid = const Uuid();

  @override
  Future<List<Bill>> build() async {
    final repository = ref.watch(billRepositoryProvider);
    return repository.getAllBills();
  }

  Future<void> addBill(Bill bill) => runOptimistic(
        update: (bills) => [...bills, bill],
        action: () => ref.read(billRepositoryProvider).createBill(bill),
        onError: (e) =>
            RepositoryException.create(entityType: 'Bill', cause: e),
      );

  Future<void> updateBill(Bill bill) => runOptimistic(
        update: (bills) =>
            bills.map((b) => b.id == bill.id ? bill : b).toList(),
        action: () => ref.read(billRepositoryProvider).updateBill(bill),
        onError: (e) => RepositoryException.update(
            entityType: 'Bill', entityId: bill.id, cause: e),
      );

  Future<void> deleteBill(String id) => runOptimistic(
        update: (bills) => bills.where((b) => b.id != id).toList(),
        action: () => ref.read(billRepositoryProvider).deleteBill(id),
        onError: (e) => RepositoryException.delete(
            entityType: 'Bill', entityId: id, cause: e),
      );

  /// Mark a bill as paid and optionally create an expense transaction.
  Future<void> markAsPaid(String id, {bool createTransaction = true}) async {
    final bills = state.valueOrNull ?? [];
    final bill = bills.firstWhereOrNull((b) => b.id == id);
    if (bill == null) return;
    final now = DateTime.now();

    // Mark current bill as paid
    final paidBill = bill.copyWith(isPaid: true, paidDate: now);
    await updateBill(paidBill);

    // Create a transaction for the payment
    if (createTransaction && bill.accountId != null && bill.categoryId != null) {
      final mainCurrency = ref.read(mainCurrencyCodeProvider);
      final rates = ref.read(exchangeRatesProvider).valueOrNull ?? {};
      double conversionRate = 1.0;
      if (bill.currencyCode != mainCurrency) {
        final fromRate = rates[bill.currencyCode];
        if (fromRate != null && fromRate > 0) {
          conversionRate = 1.0 / fromRate;
        }
      }
      final mainCurrencyAmount = bill.currencyCode == mainCurrency
          ? bill.amount
          : roundCurrency(bill.amount * conversionRate);

      await ref.read(transactionsProvider.notifier).addTransaction(
            amount: bill.amount,
            type: TransactionType.expense,
            categoryId: bill.categoryId!,
            accountId: bill.accountId!,
            assetId: bill.assetId,
            currencyCode: bill.currencyCode,
            conversionRate: conversionRate,
            mainCurrencyCode: mainCurrency,
            mainCurrencyAmount: mainCurrencyAmount,
            date: now,
            note: 'Bill payment: ${bill.name}',
          );
    }

    // Create the next recurring bill
    final nextBill = Bill(
      id: _uuid.v4(),
      name: bill.name,
      amount: bill.amount,
      currencyCode: bill.currencyCode,
      categoryId: bill.categoryId,
      accountId: bill.accountId,
      assetId: bill.assetId,
      dueDate: bill.nextDueDate,
      frequency: bill.frequency,
      isPaid: false,
      note: bill.note,
      reminderEnabled: bill.reminderEnabled,
      reminderDaysBefore: bill.reminderDaysBefore,
      createdAt: now,
    );
    await addBill(nextBill);
  }

  Future<void> refresh() async {
    try {
      final repository = ref.read(billRepositoryProvider);
      state = AsyncData(await repository.getAllBills());
    } catch (e, st) {
      state = AsyncError(
        e is AppException
            ? e
            : RepositoryException.fetch(entityType: 'Bill', cause: e),
        st,
      );
    }
  }
}

final billsProvider =
    AsyncNotifierProvider<BillsNotifier, List<Bill>>(BillsNotifier.new);

/// Provider that returns unpaid bills due in the next 30 days, sorted by due date.
final upcomingBillsProvider = Provider<List<Bill>>((ref) {
  final bills = ref.watch(billsProvider).valueOrNull ?? [];
  final now = DateTime.now();
  final thirtyDaysLater = now.add(const Duration(days: 30));

  return bills
      .where((b) =>
          !b.isPaid &&
          b.dueDate.isAfter(now.subtract(const Duration(days: 1))) &&
          b.dueDate.isBefore(thirtyDaysLater))
      .toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
});

/// Provider that returns bills linked to a specific asset.
final billsByAssetProvider = Provider.family<List<Bill>, String>((ref, assetId) {
  final bills = ref.watch(billsProvider).valueOrNull ?? [];
  return bills.where((b) => b.assetId == assetId && !b.isPaid).toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
});

/// Provider that returns unpaid bills past their due date.
final overdueBillsProvider = Provider<List<Bill>>((ref) {
  final bills = ref.watch(billsProvider).valueOrNull ?? [];
  return bills.where((b) => b.isOverdue).toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
});
