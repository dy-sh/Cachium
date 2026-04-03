import '../../core/database/app_database.dart' as db;
import '../../core/database/services/encryption_service.dart';
import '../../core/exceptions/app_exception.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/decrypt_batch.dart';
import '../../features/transactions/data/models/transaction.dart' as tx;
import '../../features/transactions/data/models/transaction_template.dart' as ui;
import '../encryption/transaction_template_data.dart';
import 'corruption_tracker.dart';
import 'decryption_cache.dart';

const _log = AppLogger('TemplateRepo');

class TransactionTemplateRepository with CorruptionTracker {
  final db.AppDatabase database;
  final EncryptionService encryptionService;
  final _decryptionCache = DecryptionCache<ui.TransactionTemplate>();

  static const _entityType = 'TransactionTemplate';

  TransactionTemplateRepository({
    required this.database,
    required this.encryptionService,
  });

  TransactionTemplateData _toData(ui.TransactionTemplate template) {
    return TransactionTemplateData(
      id: template.id,
      name: template.name,
      amount: template.amount,
      type: template.type.name,
      categoryId: template.categoryId,
      accountId: template.accountId,
      destinationAccountId: template.destinationAccountId,
      assetId: template.assetId,
      merchant: template.merchant,
      note: template.note,
      createdAtMillis: template.createdAt.millisecondsSinceEpoch,
    );
  }

  ui.TransactionTemplate _toTemplate(TransactionTemplateData data) {
    return ui.TransactionTemplate(
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
      assetId: data.assetId,
      merchant: data.merchant,
      note: data.note,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data.createdAtMillis),
    );
  }

  Future<void> createTemplate(ui.TransactionTemplate template) async {
    try {
      final data = _toData(template);
      final encryptedBlob = await encryptionService.encryptTransactionTemplate(data);

      await database.insertTransactionTemplate(
        id: template.id,
        createdAt: template.createdAt.millisecondsSinceEpoch,
        lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
      _decryptionCache.invalidate(template.id);
    } catch (e) {
      throw RepositoryException.create(entityType: _entityType, cause: e);
    }
  }

  Future<void> updateTemplate(ui.TransactionTemplate template) async {
    try {
      final data = _toData(template);
      final encryptedBlob = await encryptionService.encryptTransactionTemplate(data);

      await database.updateTransactionTemplate(
        id: template.id,
        lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        encryptedBlob: encryptedBlob,
      );
      _decryptionCache.invalidate(template.id);
    } catch (e) {
      throw RepositoryException.update(entityType: _entityType, cause: e);
    }
  }

  Future<void> deleteTemplate(String id) async {
    try {
      await database.softDeleteTransactionTemplate(
        id,
        DateTime.now().millisecondsSinceEpoch,
      );
      _decryptionCache.invalidate(id);
    } catch (e) {
      throw RepositoryException.delete(entityType: _entityType, cause: e);
    }
  }

  Future<List<ui.TransactionTemplate>> getAllTemplates() async {
    try {
      final rows = await database.getAllTransactionTemplates();
      int corruptedCount = 0;

      final results = await decryptBatch(
        rows.map((row) => () async {
          try {
            final cached = _decryptionCache.get(row.id, row.encryptedBlob);
            if (cached != null) return cached;
            final data = await encryptionService.decryptTransactionTemplate(
              row.encryptedBlob,
              expectedId: row.id,
              expectedCreatedAtMillis: row.createdAt,
            );
            final result = _toTemplate(data);
            _decryptionCache.put(row.id, row.encryptedBlob, result);
            return result;
          } catch (e) {
            _log.warning('Corrupted template row id=${row.id}: $e');
            corruptedCount++;
            return null;
          }
        }),
      );

      updateCorruptedCount(corruptedCount);
      return results.whereType<ui.TransactionTemplate>().toList();
    } catch (e) {
      throw RepositoryException.fetch(entityType: _entityType, cause: e);
    }
  }
}
