import 'package:flutter/foundation.dart';

import '../../core/database/app_database.dart' as db;
import '../../core/database/services/encryption_service.dart';
import '../../core/exceptions/app_exception.dart';
import '../../features/bills/data/models/bill.dart' as ui;
import '../../features/transactions/data/models/recurring_rule.dart';
import '../encryption/bill_data.dart';

/// Repository for managing encrypted bill storage.
class BillRepository {
  final db.AppDatabase database;
  final EncryptionService encryptionService;

  static const _entityType = 'Bill';

  int _lastCorruptedCount = 0;
  int get lastCorruptedCount => _lastCorruptedCount;

  BillRepository({
    required this.database,
    required this.encryptionService,
  });

  BillData _toData(ui.Bill bill) {
    return BillData(
      id: bill.id,
      name: bill.name,
      amount: bill.amount,
      currencyCode: bill.currencyCode,
      categoryId: bill.categoryId,
      accountId: bill.accountId,
      assetId: bill.assetId,
      dueDateMillis: bill.dueDate.millisecondsSinceEpoch,
      frequency: bill.frequency.name,
      isPaid: bill.isPaid,
      paidDateMillis: bill.paidDate?.millisecondsSinceEpoch,
      note: bill.note,
      reminderEnabled: bill.reminderEnabled,
      reminderDaysBefore: bill.reminderDaysBefore,
      createdAtMillis: bill.createdAt.millisecondsSinceEpoch,
    );
  }

  ui.Bill _toBill(BillData data) {
    return ui.Bill(
      id: data.id,
      name: data.name,
      amount: data.amount,
      currencyCode: data.currencyCode,
      categoryId: data.categoryId,
      accountId: data.accountId,
      assetId: data.assetId,
      dueDate: DateTime.fromMillisecondsSinceEpoch(data.dueDateMillis),
      frequency: RecurrenceFrequency.values.firstWhere(
        (e) => e.name == data.frequency,
        orElse: () => RecurrenceFrequency.monthly,
      ),
      isPaid: data.isPaid,
      paidDate: data.paidDateMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(data.paidDateMillis!)
          : null,
      note: data.note,
      reminderEnabled: data.reminderEnabled,
      reminderDaysBefore: data.reminderDaysBefore,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data.createdAtMillis),
    );
  }

  Future<void> createBill(ui.Bill bill) async {
    try {
      final data = _toData(bill);
      final encryptedBlob = await encryptionService.encryptBill(data);

      await database.insertBill(
        id: bill.id,
        createdAt: bill.createdAt.millisecondsSinceEpoch,
        lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
    } catch (e) {
      throw RepositoryException.create(entityType: _entityType, cause: e);
    }
  }

  Future<void> updateBill(ui.Bill bill) async {
    try {
      final data = _toData(bill);
      final encryptedBlob = await encryptionService.encryptBill(data);

      await database.updateBill(
        id: bill.id,
        lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
    } catch (e) {
      throw RepositoryException.update(entityType: _entityType, cause: e);
    }
  }

  Future<void> deleteBill(String id) async {
    try {
      await database.softDeleteBill(
        id,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      throw RepositoryException.delete(entityType: _entityType, cause: e);
    }
  }

  Future<List<ui.Bill>> getAllBills() async {
    try {
      final rows = await database.getAllBills();
      int corruptedCount = 0;

      final results = await Future.wait(
        rows.map((row) async {
          try {
            final data = await encryptionService.decryptBill(
              row.encryptedBlob,
              expectedId: row.id,
              expectedCreatedAtMillis: row.createdAt,
            );
            return _toBill(data);
          } catch (e) {
            debugPrint('WARNING: Corrupted bill row id=${row.id}: $e');
            corruptedCount++;
            return null;
          }
        }),
      );

      _lastCorruptedCount = corruptedCount;
      return results.whereType<ui.Bill>().toList();
    } catch (e) {
      throw RepositoryException.fetch(entityType: _entityType, cause: e);
    }
  }

  Stream<List<ui.Bill>> watchAllBills() {
    return database.watchAllBills().asyncMap((rows) async {
      int corruptedCount = 0;

      final results = await Future.wait(
        rows.map((row) async {
          try {
            final data = await encryptionService.decryptBill(
              row.encryptedBlob,
              expectedId: row.id,
              expectedCreatedAtMillis: row.createdAt,
            );
            return _toBill(data);
          } catch (e) {
            debugPrint('WARNING: Corrupted bill row id=${row.id}: $e');
            corruptedCount++;
            return null;
          }
        }),
      );

      _lastCorruptedCount = corruptedCount;
      return results.whereType<ui.Bill>().toList();
    });
  }
}
