part of 'csv_importer.dart';

// Skip-duplicates variants, extracted from csv_importer.dart to keep the
// main file focused on the bulk-import path. These methods are called by
// `importFromCsvWithSkipDuplicates` when the user opts to merge an import
// into existing data instead of replacing it.
//
// The split is along a clean concern boundary: the bulk-import methods (in
// the main file) do `insertOnConflictUpdate` unconditionally, while these
// variants check an `existingIds` set and skip rather than overwrite.
//
// Implemented as an extension so the logic lives in a separate file while
// still having access to private members of CsvImporter (Dart treats `part
// of` files as sharing the same library scope).

extension CsvImporterSkipDuplicates on CsvImporter {
  Future<({int imported, int skipped})> _importTransactionsFromCsvSkipDuplicates(
    String path,
    Set<String> existingIds,
    List<String> errors,
  ) async {
    int imported = 0;
    int skipped = 0;
    final content = await File(path).readAsString();
    final rows = const CsvToListConverter().convert(content);

    if (rows.isEmpty) return (imported: 0, skipped: 0);

    final headers = rows.first.map((e) => e.toString()).toList();
    final hasEncryptedBlob = headers.contains('encrypted_blob') || headers.contains('encryptedBlob');

    await database.transaction(() async {
    for (int i = 1; i < rows.length; i++) {
      try {
        final row = rows[i];
        final Map<String, dynamic> data = {};
        for (int j = 0; j < headers.length; j++) {
          data[headers[j]] = row[j];
        }

        final id = data['id'].toString();

        // Skip if transaction already exists
        if (existingIds.contains(id)) {
          skipped++;
          continue;
        }

        int date;
        try {
          date = int.parse(data['date'].toString());
        } catch (e) {
          errors.add('Row $i: invalid date "${data['date']}"');
          continue;
        }
        int lastUpdatedAt;
        try {
          lastUpdatedAt = int.parse((data['last_updated_at'] ?? data['lastUpdatedAt']).toString());
        } catch (e) {
          errors.add('Row $i: invalid last_updated_at');
          continue;
        }
        // is_deleted is optional - defaults to false (plaintext CSV exports skip deleted records)
        final isDeletedRaw = data['is_deleted'] ?? data['isDeleted'];
        final isDeleted = isDeletedRaw != null && isDeletedRaw.toString() == '1';

        Uint8List encryptedBlob;

        if (hasEncryptedBlob) {
          encryptedBlob = base64Decode((data['encrypted_blob'] ?? data['encryptedBlob']).toString());
        } else {
          // Handle optional fields that may not exist in plaintext CSV exports
          final dateMillisRaw = data['date_millis'] ?? data['dateMillis'];
          final createdAtMillisRaw = data['created_at_millis'] ?? data['createdAtMillis'];

          // Parse note - handle empty strings and "null" string
          final noteRaw = data['note']?.toString() ?? '';
          final note = (noteRaw.isEmpty || noteRaw == 'null') ? null : noteRaw;

          final conversionRateRaw2 = data['conversion_rate'] ?? data['conversionRate'];
          double conversionRate2;
          try {
            conversionRate2 = conversionRateRaw2 != null ? double.parse(conversionRateRaw2.toString()) : 1.0;
          } catch (e) {
            errors.add('Row $i: invalid conversion_rate "$conversionRateRaw2"');
            continue;
          }
          double amount2;
          try {
            amount2 = double.parse(data['amount'].toString());
          } catch (e) {
            errors.add('Row $i: invalid amount "${data['amount']}"');
            continue;
          }
          final mainCurrencyCodeRaw2 = data['main_currency_code'] ?? data['mainCurrencyCode'];
          final mainCurrencyAmountRaw2 = data['main_currency_amount'] ?? data['mainCurrencyAmount'];

          double? parsedMainCurrencyAmount2;
          if (mainCurrencyAmountRaw2 != null && mainCurrencyAmountRaw2.toString().isNotEmpty && mainCurrencyAmountRaw2.toString() != 'null') {
            try {
              parsedMainCurrencyAmount2 = double.parse(mainCurrencyAmountRaw2.toString());
            } catch (e) {
              errors.add('Row $i: invalid main_currency_amount "$mainCurrencyAmountRaw2"');
              continue;
            }
          }

          int parsedDateMillis2;
          try {
            parsedDateMillis2 = dateMillisRaw != null ? int.parse(dateMillisRaw.toString()) : date;
          } catch (e) {
            errors.add('Row $i: invalid date_millis "$dateMillisRaw"');
            continue;
          }

          int parsedCreatedAtMillis2;
          try {
            parsedCreatedAtMillis2 = createdAtMillisRaw != null ? int.parse(createdAtMillisRaw.toString()) : date;
          } catch (e) {
            errors.add('Row $i: invalid created_at_millis "$createdAtMillisRaw"');
            continue;
          }

          // Parse merchant - handle empty strings and "null" string
          final merchantRaw2 = (data['merchant'])?.toString() ?? '';
          final merchant2 = (merchantRaw2.isEmpty || merchantRaw2 == 'null') ? null : merchantRaw2;

          // Parse destination_account_id
          final destAccountIdRaw2 = (data['destination_account_id'] ?? data['destinationAccountId'])?.toString() ?? '';
          final destinationAccountId2 = (destAccountIdRaw2.isEmpty || destAccountIdRaw2 == 'null') ? null : destAccountIdRaw2;

          // Parse destination_amount
          final destAmountRaw2 = (data['destination_amount'] ?? data['destinationAmount'])?.toString() ?? '';
          double? destinationAmount2;
          if (destAmountRaw2.isNotEmpty && destAmountRaw2 != 'null') {
            try {
              destinationAmount2 = double.parse(destAmountRaw2);
            } catch (e) {
              errors.add('Row $i: invalid destination_amount "$destAmountRaw2"');
              continue;
            }
          }

          // Parse asset_id
          final assetIdRaw2 = (data['asset_id'] ?? data['assetId'])?.toString() ?? '';
          final assetId2 = (assetIdRaw2.isEmpty || assetIdRaw2 == 'null') ? null : assetIdRaw2;

          // Parse is_acquisition_cost
          final isAcquisitionCostRaw2 = (data['is_acquisition_cost'] ?? data['isAcquisitionCost'])?.toString() ?? '0';
          final isAcquisitionCost2 = isAcquisitionCostRaw2 == '1' || isAcquisitionCostRaw2 == 'true';

          final transactionData = TransactionData(
            id: id,
            amount: amount2,
            categoryId: (data['category_id'] ?? data['categoryId']).toString(),
            accountId: (data['account_id'] ?? data['accountId']).toString(),
            destinationAccountId: destinationAccountId2,
            destinationAmount: destinationAmount2,
            type: data['type'].toString(),
            note: note,
            merchant: merchant2,
            assetId: assetId2,
            isAcquisitionCost: isAcquisitionCost2,
            currency: data['currency']?.toString() ?? 'USD',
            conversionRate: conversionRate2,
            mainCurrencyCode: mainCurrencyCodeRaw2?.toString() ?? 'USD',
            mainCurrencyAmount: parsedMainCurrencyAmount2,
            dateMillis: parsedDateMillis2,
            createdAtMillis: parsedCreatedAtMillis2,
          );
          encryptedBlob = await encryptionService.encryptJson(transactionData.toJson());
        }

        await database.into(database.transactions).insertOnConflictUpdate(
          TransactionsCompanion(
            id: Value(id),
            date: Value(date),
            lastUpdatedAt: Value(lastUpdatedAt),
            isDeleted: Value(isDeleted),
            encryptedBlob: Value(encryptedBlob),
          ),
        );
        imported++;
      } catch (e) {
        errors.add('Failed to import transaction row $i: $e');
      }
    }
    }); // end database.transaction

    return (imported: imported, skipped: skipped);
  }

  Future<({int imported, int skipped})> _importAccountsFromCsvSkipDuplicates(
    String path,
    Set<String> existingIds,
    List<String> errors,
  ) async {
    int imported = 0;
    int skipped = 0;
    final content = await File(path).readAsString();
    final rows = const CsvToListConverter().convert(content);

    if (rows.isEmpty) return (imported: 0, skipped: 0);

    final headers = rows.first.map((e) => e.toString()).toList();
    final hasEncryptedBlob = headers.contains('encrypted_blob') || headers.contains('encryptedBlob');

    await database.transaction(() async {
    for (int i = 1; i < rows.length; i++) {
      try {
        final row = rows[i];
        final Map<String, dynamic> data = {};
        for (int j = 0; j < headers.length; j++) {
          data[headers[j]] = row[j];
        }

        final id = data['id'].toString();

        // Skip if account already exists
        if (existingIds.contains(id)) {
          skipped++;
          continue;
        }

        final createdAt = int.parse((data['created_at'] ?? data['createdAt']).toString());
        final sortOrder = int.parse((data['sort_order'] ?? data['sortOrder'] ?? '0').toString());
        final lastUpdatedAt = int.parse((data['last_updated_at'] ?? data['lastUpdatedAt']).toString());
        // is_deleted is optional - defaults to false (plaintext CSV exports skip deleted records)
        final isDeletedRaw = data['is_deleted'] ?? data['isDeleted'];
        final isDeleted = isDeletedRaw != null && isDeletedRaw.toString() == '1';

        Uint8List encryptedBlob;

        if (hasEncryptedBlob) {
          encryptedBlob = base64Decode((data['encrypted_blob'] ?? data['encryptedBlob']).toString());
        } else {
          final customColorValue = (data['custom_color_value'] ?? data['customColorValue'])?.toString() ?? '';
          final customIconCodePoint = (data['custom_icon_code_point'] ?? data['customIconCodePoint'])?.toString() ?? '';
          final initialBalanceStr = (data['initial_balance'] ?? data['initialBalance'])?.toString() ?? '0';
          final createdAtMillisRaw = data['created_at_millis'] ?? data['createdAtMillis'];

          final accountData = AccountData(
            id: id,
            name: data['name'].toString(),
            type: data['type'].toString(),
            balance: double.parse(data['balance'].toString()),
            initialBalance: initialBalanceStr.isEmpty ? 0.0 : double.parse(initialBalanceStr),
            customColorValue: customColorValue.isEmpty ? null : int.parse(customColorValue),
            customIconCodePoint: customIconCodePoint.isEmpty ? null : int.parse(customIconCodePoint),
            createdAtMillis: createdAtMillisRaw != null ? int.parse(createdAtMillisRaw.toString()) : createdAt,
          );
          encryptedBlob = await encryptionService.encryptJson(accountData.toJson());
        }

        await database.into(database.accounts).insertOnConflictUpdate(
          AccountsCompanion(
            id: Value(id),
            createdAt: Value(createdAt),
            sortOrder: Value(sortOrder),
            lastUpdatedAt: Value(lastUpdatedAt),
            isDeleted: Value(isDeleted),
            encryptedBlob: Value(encryptedBlob),
          ),
        );
        imported++;
      } catch (e) {
        errors.add('Failed to import account row $i: $e');
      }
    }
    }); // end database.transaction

    return (imported: imported, skipped: skipped);
  }

  Future<({int imported, int skipped})> _importCategoriesFromCsvSkipDuplicates(
    String path,
    Set<String> existingIds,
    List<String> errors,
  ) async {
    int imported = 0;
    int skipped = 0;
    final content = await File(path).readAsString();
    final rows = const CsvToListConverter().convert(content);

    if (rows.isEmpty) return (imported: 0, skipped: 0);

    final headers = rows.first.map((e) => e.toString()).toList();
    final hasEncryptedBlob = headers.contains('encrypted_blob') || headers.contains('encryptedBlob');

    await database.transaction(() async {
    for (int i = 1; i < rows.length; i++) {
      try {
        final row = rows[i];
        final Map<String, dynamic> data = {};
        for (int j = 0; j < headers.length; j++) {
          data[headers[j]] = row[j];
        }

        final id = data['id'].toString();

        // Skip if category already exists
        if (existingIds.contains(id)) {
          skipped++;
          continue;
        }

        final sortOrder = int.parse((data['sort_order'] ?? data['sortOrder']).toString());
        final lastUpdatedAt = int.parse((data['last_updated_at'] ?? data['lastUpdatedAt']).toString());
        // is_deleted is optional - defaults to false (plaintext CSV exports skip deleted records)
        final isDeletedRaw = data['is_deleted'] ?? data['isDeleted'];
        final isDeleted = isDeletedRaw != null && isDeletedRaw.toString() == '1';

        Uint8List encryptedBlob;

        if (hasEncryptedBlob) {
          encryptedBlob = base64Decode((data['encrypted_blob'] ?? data['encryptedBlob']).toString());
        } else {
          final iconFontPackage = (data['icon_font_package'] ?? data['iconFontPackage'])?.toString() ?? '';
          final parentId = (data['parent_id'] ?? data['parentId'])?.toString() ?? '';
          final showAssetsRaw = (data['show_assets'] ?? data['showAssets'])?.toString() ?? '';

          final categoryData = CategoryData(
            id: id,
            name: data['name'].toString(),
            iconCodePoint: int.parse((data['icon_code_point'] ?? data['iconCodePoint']).toString()),
            iconFontFamily: (data['icon_font_family'] ?? data['iconFontFamily']).toString(),
            iconFontPackage: iconFontPackage.isEmpty ? null : iconFontPackage,
            colorIndex: int.parse((data['color_index'] ?? data['colorIndex']).toString()),
            type: data['type'].toString(),
            isCustom: (data['is_custom'] ?? data['isCustom']).toString() == '1',
            parentId: parentId.isEmpty ? null : parentId,
            sortOrder: sortOrder,
            showAssets: showAssetsRaw == '1',
          );
          encryptedBlob = await encryptionService.encryptJson(categoryData.toJson());
        }

        await database.into(database.categories).insertOnConflictUpdate(
          CategoriesCompanion(
            id: Value(id),
            sortOrder: Value(sortOrder),
            lastUpdatedAt: Value(lastUpdatedAt),
            isDeleted: Value(isDeleted),
            encryptedBlob: Value(encryptedBlob),
          ),
        );
        imported++;
      } catch (e) {
        errors.add('Failed to import category row $i: $e');
      }
    }
    }); // end database.transaction

    return (imported: imported, skipped: skipped);
  }
}
