import 'package:flutter/widgets.dart';

import '../../core/database/app_database.dart' as db;
import '../../core/database/services/encryption_service.dart';
import '../../core/exceptions/app_exception.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/decrypt_batch.dart';
import '../../features/savings_goals/data/models/savings_goal.dart' as ui;
import '../encryption/savings_goal_data.dart';
import 'corruption_tracker.dart';
import 'decryption_cache.dart';

const _log = AppLogger('SavingsGoalRepo');

class SavingsGoalRepository with CorruptionTracker {
  final db.AppDatabase database;
  final EncryptionService encryptionService;
  final _decryptionCache = DecryptionCache<ui.SavingsGoal>();

  static const _entityType = 'SavingsGoal';

  SavingsGoalRepository({
    required this.database,
    required this.encryptionService,
  });

  SavingsGoalData _toData(ui.SavingsGoal goal) {
    return SavingsGoalData(
      id: goal.id,
      name: goal.name,
      targetAmount: goal.targetAmount,
      currentAmount: goal.currentAmount,
      colorIndex: goal.colorIndex,
      iconCodePoint: goal.icon.codePoint,
      iconFontFamily: goal.icon.fontFamily,
      iconFontPackage: goal.icon.fontPackage,
      linkedAccountId: goal.linkedAccountId,
      targetDateMillis: goal.targetDate?.millisecondsSinceEpoch,
      note: goal.note,
      createdAtMillis: goal.createdAt.millisecondsSinceEpoch,
    );
  }

  ui.SavingsGoal _toGoal(SavingsGoalData data) {
    return ui.SavingsGoal(
      id: data.id,
      name: data.name,
      targetAmount: data.targetAmount,
      currentAmount: data.currentAmount,
      colorIndex: data.colorIndex,
      icon: IconData(
        data.iconCodePoint,
        fontFamily: data.iconFontFamily,
        fontPackage: data.iconFontPackage,
      ),
      linkedAccountId: data.linkedAccountId,
      targetDate: data.targetDateMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(data.targetDateMillis!)
          : null,
      note: data.note,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data.createdAtMillis),
    );
  }

  Future<void> createGoal(ui.SavingsGoal goal) async {
    try {
      final data = _toData(goal);
      final encryptedBlob =
          await encryptionService.encryptSavingsGoal(data);

      await database.insertSavingsGoal(
        id: goal.id,
        createdAt: goal.createdAt.millisecondsSinceEpoch,
        lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
      _decryptionCache.invalidate(goal.id);
    } catch (e) {
      throw RepositoryException.create(entityType: _entityType, cause: e);
    }
  }

  Future<void> updateGoal(ui.SavingsGoal goal) async {
    try {
      final data = _toData(goal);
      final encryptedBlob =
          await encryptionService.encryptSavingsGoal(data);

      await database.updateSavingsGoal(
        id: goal.id,
        lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
      _decryptionCache.invalidate(goal.id);
    } catch (e) {
      throw RepositoryException.update(entityType: _entityType, cause: e);
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await database.softDeleteSavingsGoal(
        id,
        DateTime.now().millisecondsSinceEpoch,
      );
      _decryptionCache.invalidate(id);
    } catch (e) {
      throw RepositoryException.delete(entityType: _entityType, cause: e);
    }
  }

  Future<List<ui.SavingsGoal>> getAllGoals() async {
    try {
      final rows = await database.getAllSavingsGoals();
      int corruptedCount = 0;

      final results = await decryptBatch(
        rows.map((row) => () async {
          try {
            final cached = _decryptionCache.get(row.id, row.encryptedBlob);
            if (cached != null) return cached;
            final data = await encryptionService.decryptSavingsGoal(
              row.encryptedBlob,
              expectedId: row.id,
              expectedCreatedAtMillis: row.createdAt,
            );
            final result = _toGoal(data);
            _decryptionCache.put(row.id, row.encryptedBlob, result);
            return result;
          } catch (e) {
            _log.warning('Corrupted savings goal row id=${row.id}: $e');
            corruptedCount++;
            return null;
          }
        }),
      );

      updateCorruptedCount(corruptedCount);
      return results.whereType<ui.SavingsGoal>().toList();
    } catch (e) {
      throw RepositoryException.fetch(entityType: _entityType, cause: e);
    }
  }
}
