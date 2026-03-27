import 'package:flutter/foundation.dart';

import '../../core/database/app_database.dart' as db;
import '../../core/database/services/encryption_service.dart';
import '../../core/exceptions/app_exception.dart';
import '../../features/budgets/data/models/budget.dart' as ui;
import '../encryption/budget_data.dart';

class BudgetRepository {
  final db.AppDatabase database;
  final EncryptionService encryptionService;

  static const _entityType = 'Budget';

  int _lastCorruptedCount = 0;
  int get lastCorruptedCount => _lastCorruptedCount;

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
      final data = _toData(budget);
      final encryptedBlob = await encryptionService.encryptBudget(data);

      await database.insertBudget(
        id: budget.id,
        createdAt: budget.createdAt.millisecondsSinceEpoch,
        lastUpdatedAt: budget.createdAt.millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
    } catch (e) {
      throw RepositoryException.create(entityType: _entityType, cause: e);
    }
  }

  Future<void> updateBudget(ui.Budget budget) async {
    try {
      final data = _toData(budget);
      final encryptedBlob = await encryptionService.encryptBudget(data);

      await database.updateBudget(
        id: budget.id,
        lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
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

      final results = await Future.wait(
        rows.map((row) async {
          try {
            final data = await encryptionService.decryptBudget(
              row.encryptedBlob,
              expectedId: row.id,
              expectedCreatedAtMillis: row.createdAt,
            );
            return _toBudget(data);
          } catch (e) {
            debugPrint('WARNING: Corrupted budget row id=${row.id}: $e');
            corruptedCount++;
            return null;
          }
        }),
      );

      _lastCorruptedCount = corruptedCount;
      return results.whereType<ui.Budget>().toList();
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException.fetch(entityType: _entityType, cause: e);
    }
  }
}
