import '../../core/database/app_database.dart' as db;
import '../../core/database/services/encryption_service.dart';
import '../../core/exceptions/app_exception.dart';
import '../../features/transactions/data/models/recurring_rule.dart' as ui;
import '../../features/transactions/data/models/transaction.dart' as tx;
import '../encryption/recurring_rule_data.dart';

/// Repository for managing encrypted recurring rule storage.
class RecurringRuleRepository {
  final db.AppDatabase database;
  final EncryptionService encryptionService;

  static const _entityType = 'RecurringRule';

  RecurringRuleRepository({
    required this.database,
    required this.encryptionService,
  });

  RecurringRuleData _toData(ui.RecurringRule rule) {
    return RecurringRuleData(
      id: rule.id,
      name: rule.name,
      amount: rule.amount,
      type: rule.type.name,
      categoryId: rule.categoryId,
      accountId: rule.accountId,
      destinationAccountId: rule.destinationAccountId,
      merchant: rule.merchant,
      note: rule.note,
      frequency: rule.frequency.name,
      startDateMillis: rule.startDate.millisecondsSinceEpoch,
      endDateMillis: rule.endDate?.millisecondsSinceEpoch,
      lastGeneratedDateMillis: rule.lastGeneratedDate.millisecondsSinceEpoch,
      isActive: rule.isActive,
      createdAtMillis: rule.createdAt.millisecondsSinceEpoch,
    );
  }

  ui.RecurringRule _toRule(RecurringRuleData data) {
    return ui.RecurringRule(
      id: data.id,
      name: data.name,
      amount: data.amount,
      type: tx.TransactionType.values.firstWhere(
        (e) => e.name == data.type,
        orElse: () => tx.TransactionType.expense,
      ),
      categoryId: data.categoryId,
      accountId: data.accountId,
      destinationAccountId: data.destinationAccountId,
      merchant: data.merchant,
      note: data.note,
      frequency: ui.RecurrenceFrequency.values.firstWhere(
        (e) => e.name == data.frequency,
        orElse: () => ui.RecurrenceFrequency.monthly,
      ),
      startDate: DateTime.fromMillisecondsSinceEpoch(data.startDateMillis),
      endDate: data.endDateMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(data.endDateMillis!)
          : null,
      lastGeneratedDate:
          DateTime.fromMillisecondsSinceEpoch(data.lastGeneratedDateMillis),
      isActive: data.isActive,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data.createdAtMillis),
    );
  }

  Future<void> createRule(ui.RecurringRule rule) async {
    try {
      final data = _toData(rule);
      final encryptedBlob = await encryptionService.encryptRecurringRule(data);

      await database.insertRecurringRule(
        id: rule.id,
        createdAt: rule.createdAt.millisecondsSinceEpoch,
        lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
    } catch (e) {
      throw RepositoryException.create(entityType: _entityType, cause: e);
    }
  }

  Future<void> updateRule(ui.RecurringRule rule) async {
    try {
      final data = _toData(rule);
      final encryptedBlob = await encryptionService.encryptRecurringRule(data);

      await database.updateRecurringRule(
        id: rule.id,
        lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
    } catch (e) {
      throw RepositoryException.update(entityType: _entityType, cause: e);
    }
  }

  Future<void> deleteRule(String id) async {
    try {
      await database.softDeleteRecurringRule(
        id,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      throw RepositoryException.delete(entityType: _entityType, cause: e);
    }
  }

  Future<List<ui.RecurringRule>> getAllRules() async {
    try {
      final rows = await database.getAllRecurringRules();
      final rules = <ui.RecurringRule>[];

      for (final row in rows) {
        try {
          final data = await encryptionService.decryptRecurringRule(
            row.encryptedBlob,
            expectedId: row.id,
            expectedCreatedAtMillis: row.createdAt,
          );
          rules.add(_toRule(data));
        } catch (_) {
          // Skip corrupted rows
        }
      }
      return rules;
    } catch (e) {
      throw RepositoryException.fetch(entityType: _entityType, cause: e);
    }
  }

  Stream<List<ui.RecurringRule>> watchAllRules() {
    return database.watchAllRecurringRules().asyncMap((rows) async {
      final rules = <ui.RecurringRule>[];
      for (final row in rows) {
        try {
          final data = await encryptionService.decryptRecurringRule(
            row.encryptedBlob,
            expectedId: row.id,
            expectedCreatedAtMillis: row.createdAt,
          );
          rules.add(_toRule(data));
        } catch (_) {
          // Skip corrupted rows
        }
      }
      return rules;
    });
  }
}
