import 'package:flutter/foundation.dart';

import '../../core/database/app_database.dart' as db;
import '../../core/database/services/encryption_service.dart';
import '../../core/exceptions/app_exception.dart';
import '../../core/utils/decrypt_batch.dart';
import '../../features/budgets/data/models/budget.dart' as ui;
import '../encryption/budget_data.dart';
import 'corruption_tracker.dart';
import 'decryption_cache.dart';

class BudgetRepository with CorruptionTracker {
  final db.AppDatabase database;
  final EncryptionService encryptionService;
  final _decryptionCache = DecryptionCache<ui.Budget>();

  static const _entityType = 'Budget';

  BudgetRepository({
    required this.database,
    required this.encryptionService,
  });

  BudgetData _toData(ui.Budget budget) {
    return BudgetData(
      id: budget.id,
      categoryId: budget.categoryId,
      amount: budget.amount,
      year: budget.year,
      month: budget.month,
      rolloverEnabled: budget.rolloverEnabled,
      createdAtMillis: budget.createdAt.millisecondsSinceEpoch,
    );
  }

  ui.Budget _toBudget(BudgetData data) {
    return ui.Budget(
      id: data.id,
      categoryId: data.categoryId,
      amount: data.amount,
      year: data.year,
      month: data.month,
      rolloverEnabled: data.rolloverEnabled,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data.createdAtMillis),
    );
  }

  Future<void> createBudget(ui.Budget budget) async {
    try {
      budget.validate();
      final data = _toData(budget);
      final encryptedBlob = await encryptionService.encryptBudget(data);

      await database.insertBudget(
        id: budget.id,
        createdAt: budget.createdAt.millisecondsSinceEpoch,
        lastUpdatedAt: budget.createdAt.millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
      _decryptionCache.invalidate(budget.id);
    } catch (e) {
      throw RepositoryException.create(entityType: _entityType, cause: e);
    }
  }

  Future<void> updateBudget(ui.Budget budget) async {
    try {
      budget.validate();
      final data = _toData(budget);
      final encryptedBlob = await encryptionService.encryptBudget(data);

      await database.updateBudget(
        id: budget.id,
        lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
      _decryptionCache.invalidate(budget.id);
    } catch (e) {
      throw RepositoryException.update(
        entityType: _entityType,
        entityId: budget.id,
        cause: e,
      );
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await database.softDeleteBudget(
        id,
        DateTime.now().millisecondsSinceEpoch,
      );
      _decryptionCache.invalidate(id);
    } catch (e) {
      throw RepositoryException.delete(
        entityType: _entityType,
        entityId: id,
        cause: e,
      );
    }
  }

  Future<List<ui.Budget>> getAllBudgets() async {
    try {
      final rows = await database.getAllBudgets();
      int corruptedCount = 0;

      final results = await decryptBatch(
        rows.map((row) => () async {
          try {
            final cached = _decryptionCache.get(row.id, row.encryptedBlob);
            if (cached != null) return cached;
            final data = await encryptionService.decryptBudget(
              row.encryptedBlob,
              expectedId: row.id,
              expectedCreatedAtMillis: row.createdAt,
            );
            final result = _toBudget(data);
            _decryptionCache.put(row.id, row.encryptedBlob, result);
            return result;
          } catch (e) {
            debugPrint('WARNING: Corrupted budget row id=${row.id}: $e');
            corruptedCount++;
            return null;
          }
        }),
      );

      updateCorruptedCount(corruptedCount);
      return results.whereType<ui.Budget>().toList();
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException.fetch(entityType: _entityType, cause: e);
    }
  }
}
