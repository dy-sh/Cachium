import 'package:flutter/material.dart';

import '../../core/database/app_database.dart' as db;
import '../../core/database/services/encryption_service.dart';
import '../../core/exceptions/app_exception.dart';
import '../../features/savings_goals/data/models/savings_goal.dart' as ui;
import '../encryption/savings_goal_data.dart';

class SavingsGoalRepository {
  final db.AppDatabase database;
  final EncryptionService encryptionService;

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
    } catch (e) {
      throw RepositoryException.delete(entityType: _entityType, cause: e);
    }
  }

  Future<List<ui.SavingsGoal>> getAllGoals() async {
    try {
      final rows = await database.getAllSavingsGoals();
      final goals = <ui.SavingsGoal>[];

      for (final row in rows) {
        try {
          final data = await encryptionService.decryptSavingsGoal(
            row.encryptedBlob,
            expectedId: row.id,
            expectedCreatedAtMillis: row.createdAt,
          );
          goals.add(_toGoal(data));
        } catch (_) {
          // Skip corrupted rows
        }
      }
      return goals;
    } catch (e) {
      throw RepositoryException.fetch(entityType: _entityType, cause: e);
    }
  }
}
