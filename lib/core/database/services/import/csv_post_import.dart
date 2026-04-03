import 'package:drift/drift.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../data/encryption/account_data.dart';
import '../../../../data/encryption/transaction_data.dart';
import '../../../../features/transactions/data/models/transaction.dart' as tx;
import '../../../utils/balance_calculation.dart';
import '../../../utils/currency_conversion.dart';
import '../../app_database.dart';
import '../encryption_service.dart';

const _log = AppLogger('CsvPostImport');

Future<int> validateForeignKeys(
  AppDatabase database,
  EncryptionService encryptionService,
  List<String> errors,
) async {
  int skipped = 0;

  try {
    // Collect valid account IDs
    final accountRows = await database.select(database.accounts).get();
    final validAccountIds = <String>{};
    for (final row in accountRows) {
      if (!row.isDeleted) {
        validAccountIds.add(row.id);
      }
    }

    // Collect valid category IDs
    final categoryRows = await database.select(database.categories).get();
    final validCategoryIds = <String>{};
    for (final row in categoryRows) {
      if (!row.isDeleted) {
        validCategoryIds.add(row.id);
      }
    }

    // Collect valid asset IDs
    final assetRows = await database.select(database.assets).get();
    final validAssetIds = <String>{};
    for (final row in assetRows) {
      if (!row.isDeleted) {
        validAssetIds.add(row.id);
      }
    }

    // Check transactions for orphaned references
    final transactionRows = await database.select(database.transactions).get();
    for (final row in transactionRows) {
      if (row.isDeleted) continue;
      try {
        final json = await encryptionService.decryptJson(row.encryptedBlob);
        final data = TransactionData.fromJson(json);

        final hasValidAccount = validAccountIds.contains(data.accountId);
        final hasValidCategory = data.categoryId.isEmpty || validCategoryIds.contains(data.categoryId);
        final hasValidDestAccount = data.destinationAccountId == null ||
            data.destinationAccountId!.isEmpty ||
            validAccountIds.contains(data.destinationAccountId);

        // Treat empty destinationAccountId as null for transfers
        final isTransfer = data.type == 'transfer';
        final hasEmptyDestAccount = isTransfer &&
            data.destinationAccountId != null &&
            data.destinationAccountId!.isEmpty;
        final hasOrphanedAsset = data.assetId != null &&
            data.assetId!.isNotEmpty &&
            !validAssetIds.contains(data.assetId);

        if (!hasValidAccount || !hasValidCategory || !hasValidDestAccount || hasEmptyDestAccount) {
          final reasons = <String>[];
          if (!hasValidAccount) reasons.add('account "${data.accountId}" not found');
          if (!hasValidCategory) reasons.add('category "${data.categoryId}" not found');
          if (!hasValidDestAccount) reasons.add('destination account "${data.destinationAccountId}" not found');
          if (hasEmptyDestAccount) reasons.add('transfer missing destination account');

          errors.add('Skipped transaction ${data.id}: ${reasons.join(', ')}');

          // Soft-delete the orphaned transaction
          await (database.update(database.transactions)
                ..where((t) => t.id.equals(row.id)))
              .write(const TransactionsCompanion(isDeleted: Value(true)));
          skipped++;
        } else if (hasOrphanedAsset) {
          // Asset is optional — clear it instead of deleting the transaction
          final cleanedData = data.copyWith(assetId: null);
          final encryptedBlob = await encryptionService.encryptJson(cleanedData.toJson());
          await (database.update(database.transactions)
                ..where((t) => t.id.equals(row.id)))
              .write(TransactionsCompanion(encryptedBlob: Value(encryptedBlob)));
          errors.add('Cleared orphaned asset "${data.assetId}" from transaction ${data.id}');
        }
      } catch (e) {
        errors.add('Skipped corrupted transaction ${row.id}: $e');
      }
    }
  } catch (e) {
    errors.add('Foreign key validation error: $e');
  }

  return skipped;
}

Future<void> reconcileAccountBalances(
  AppDatabase database,
  EncryptionService encryptionService,
  List<String> errors,
) async {
  try {
    // Decrypt all accounts
    final accountRows = await database.select(database.accounts).get();
    final transactionRows = await database.select(database.transactions).get();

    // Decrypt transactions
    final transactions = <tx.Transaction>[];
    for (final row in transactionRows) {
      if (row.isDeleted) continue;
      try {
        final json = await encryptionService.decryptJson(row.encryptedBlob);
        final data = TransactionData.fromJson(json);
        transactions.add(tx.Transaction(
          id: data.id,
          amount: data.amount,
          type: tx.TransactionType.values.firstWhere(
            (t) => t.name == data.type,
            orElse: () => tx.TransactionType.expense,
          ),
          categoryId: data.categoryId,
          accountId: data.accountId,
          destinationAccountId: data.destinationAccountId,
          destinationAmount: data.destinationAmount,
          currencyCode: data.currency,
          conversionRate: data.conversionRate,
          mainCurrencyCode: data.mainCurrencyCode,
          mainCurrencyAmount: data.mainCurrencyAmount,
          date: DateTime.fromMillisecondsSinceEpoch(data.dateMillis),
          createdAt: DateTime.fromMillisecondsSinceEpoch(data.createdAtMillis),
        ));
      } catch (e) {
        errors.add('Skipped corrupted transaction during reconciliation ${row.id}: $e');
      }
    }

    final deltas = calculateAccountDeltas(transactions);

    for (final row in accountRows) {
      if (row.isDeleted) continue;
      try {
        final json = await encryptionService.decryptJson(row.encryptedBlob);
        final data = AccountData.fromJson(json);
        final delta = deltas[data.id] ?? 0;
        final expectedBalance = roundCurrency(data.initialBalance + delta);

        if ((data.balance - expectedBalance).abs() > 0.001) {
          errors.add(
            'Account "${data.name}" balance adjusted: '
            '${data.balance} -> $expectedBalance',
          );

          // Update the account with corrected balance
          final corrected = AccountData(
            id: data.id,
            name: data.name,
            type: data.type,
            balance: expectedBalance,
            initialBalance: data.initialBalance,
            customColorValue: data.customColorValue,
            customIconCodePoint: data.customIconCodePoint,
            customIconFontFamily: data.customIconFontFamily,
            customIconFontPackage: data.customIconFontPackage,
            currencyCode: data.currencyCode,
            createdAtMillis: data.createdAtMillis,
          );
          final encryptedBlob =
              await encryptionService.encryptJson(corrected.toJson());

          await database.into(database.accounts).insertOnConflictUpdate(
            AccountsCompanion(
              id: Value(row.id),
              createdAt: Value(row.createdAt),
              sortOrder: Value(row.sortOrder),
              lastUpdatedAt: Value(DateTime.now().millisecondsSinceEpoch),
              isDeleted: Value(row.isDeleted),
              encryptedBlob: Value(encryptedBlob),
            ),
          );
        }
      } catch (e) {
        _log.warning('Skipped corrupted account during reconciliation ${row.id}: $e');
      }
    }
  } catch (e) {
    errors.add('Balance reconciliation failed: $e');
  }
}
