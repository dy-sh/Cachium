import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/settings/data/models/flexible_csv_import_state.dart';
import 'package:cachium/features/settings/data/models/flexible_csv_import_config.dart';
import 'package:cachium/features/settings/data/models/field_mapping_options.dart';

FlexibleCsvImportConfig _makeConfig({
  ImportEntityType entityType = ImportEntityType.account,
  List<String> headers = const ['name', 'balance', 'type'],
  Map<String, FieldMapping>? fieldMappings,
}) {
  return FlexibleCsvImportConfig(
    entityType: entityType,
    filePath: '/tmp/test.csv',
    csvHeaders: headers,
    csvRows: const [],
    fieldMappings: fieldMappings ?? {},
  );
}

void main() {
  group('ParsedImportRow', () {
    test('isValid when no errors', () {
      const row = ParsedImportRow(
        rowIndex: 0,
        parsedValues: {'a': 1},
      );
      expect(row.isValid, isTrue);
    });

    test('not valid when errors exist', () {
      const row = ParsedImportRow(
        rowIndex: 0,
        parsedValues: {},
        errors: ['bad data'],
      );
      expect(row.isValid, isFalse);
    });

    test('hasWarnings when warnings exist', () {
      const row = ParsedImportRow(
        rowIndex: 0,
        parsedValues: {},
        warnings: ['heads up'],
      );
      expect(row.hasWarnings, isTrue);
    });

    test('no warnings by default', () {
      const row = ParsedImportRow(rowIndex: 0, parsedValues: {});
      expect(row.hasWarnings, isFalse);
    });
  });

  group('ParseResult', () {
    test('totalRows sums valid and invalid', () {
      const result = ParseResult(
        validRows: [
          ParsedImportRow(rowIndex: 0, parsedValues: {}),
          ParsedImportRow(rowIndex: 1, parsedValues: {}),
        ],
        invalidRows: [
          ParsedImportRow(rowIndex: 2, parsedValues: {}, errors: ['err']),
        ],
      );
      expect(result.totalRows, 3);
      expect(result.validCount, 2);
      expect(result.invalidCount, 1);
    });

    test('hasErrors when invalid rows exist', () {
      const result = ParseResult(
        validRows: [],
        invalidRows: [
          ParsedImportRow(rowIndex: 0, parsedValues: {}, errors: ['err']),
        ],
      );
      expect(result.hasErrors, isTrue);
    });

    test('hasErrors when global errors exist', () {
      const result = ParseResult(
        validRows: [],
        invalidRows: [],
        globalErrors: ['file issue'],
      );
      expect(result.hasErrors, isTrue);
    });

    test('no errors when all clean', () {
      const result = ParseResult(validRows: [], invalidRows: []);
      expect(result.hasErrors, isFalse);
    });
  });

  group('FlexibleImportResult', () {
    test('total sums all counts', () {
      const result = FlexibleImportResult(
        imported: 10,
        skipped: 2,
        failed: 1,
      );
      expect(result.total, 13);
    });

    test('hasErrors when failed > 0', () {
      const result = FlexibleImportResult(
        imported: 0,
        skipped: 0,
        failed: 1,
      );
      expect(result.hasErrors, isTrue);
    });

    test('hasErrors when errors list non-empty', () {
      const result = FlexibleImportResult(
        imported: 10,
        skipped: 0,
        failed: 0,
        errors: ['something went wrong'],
      );
      expect(result.hasErrors, isTrue);
    });

    test('no errors when clean', () {
      const result = FlexibleImportResult(
        imported: 10,
        skipped: 0,
        failed: 0,
      );
      expect(result.hasErrors, isFalse);
    });
  });

  group('FlexibleCsvImportState.unmappedCsvColumns', () {
    test('returns empty when no config', () {
      const state = FlexibleCsvImportState();
      expect(state.unmappedCsvColumns, isEmpty);
    });

    test('returns all headers when nothing mapped', () {
      final state = FlexibleCsvImportState(
        config: _makeConfig(
          headers: ['a', 'b', 'c'],
          fieldMappings: {
            'x': const FieldMapping(fieldKey: 'x'),
          },
        ),
      );
      expect(state.unmappedCsvColumns, ['a', 'b', 'c']);
    });

    test('excludes mapped columns', () {
      final state = FlexibleCsvImportState(
        config: _makeConfig(
          headers: ['a', 'b', 'c'],
          fieldMappings: {
            'x': const FieldMapping(fieldKey: 'x', csvColumn: 'b'),
          },
        ),
      );
      expect(state.unmappedCsvColumns, ['a', 'c']);
    });
  });

  group('FlexibleCsvImportState.connectionBadges', () {
    test('returns empty when no config', () {
      const state = FlexibleCsvImportState();
      expect(state.connectionBadges, isEmpty);
    });

    test('assigns sequential badges to mapped columns', () {
      final state = FlexibleCsvImportState(
        config: _makeConfig(
          headers: ['a', 'b', 'c'],
          fieldMappings: {
            'field1': const FieldMapping(fieldKey: 'field1', csvColumn: 'a'),
            'field2': const FieldMapping(fieldKey: 'field2', csvColumn: 'c'),
          },
        ),
      );
      final badges = state.connectionBadges;
      expect(badges['a'], 1);
      expect(badges['c'], 2);
      expect(badges.containsKey('b'), isFalse);
    });
  });

  group('FlexibleCsvImportState.getFieldKeyForCsvColumn', () {
    test('returns null when no config', () {
      const state = FlexibleCsvImportState();
      expect(state.getFieldKeyForCsvColumn('col'), isNull);
    });

    test('returns field key for mapped column', () {
      final state = FlexibleCsvImportState(
        config: _makeConfig(
          fieldMappings: {
            'name': const FieldMapping(fieldKey: 'name', csvColumn: 'Name'),
          },
        ),
      );
      expect(state.getFieldKeyForCsvColumn('Name'), 'name');
    });

    test('returns null for unmapped column', () {
      final state = FlexibleCsvImportState(
        config: _makeConfig(fieldMappings: {}),
      );
      expect(state.getFieldKeyForCsvColumn('unknown'), isNull);
    });
  });

  group('FlexibleCsvImportState.getCsvColumnForField', () {
    test('returns null when no config', () {
      const state = FlexibleCsvImportState();
      expect(state.getCsvColumnForField('name'), isNull);
    });

    test('returns csv column for mapped field', () {
      final state = FlexibleCsvImportState(
        config: _makeConfig(
          fieldMappings: {
            'name': const FieldMapping(fieldKey: 'name', csvColumn: 'Name'),
          },
        ),
      );
      expect(state.getCsvColumnForField('name'), 'Name');
    });

    test('returns null for unmapped field', () {
      final state = FlexibleCsvImportState(
        config: _makeConfig(fieldMappings: {}),
      );
      expect(state.getCsvColumnForField('name'), isNull);
    });
  });

  group('FlexibleCsvImportState.getBadgeForField', () {
    test('returns null when no config', () {
      const state = FlexibleCsvImportState();
      expect(state.getBadgeForField('name'), isNull);
    });

    test('returns badge number for mapped field', () {
      final state = FlexibleCsvImportState(
        config: _makeConfig(
          headers: ['Name', 'Balance'],
          fieldMappings: {
            'name': const FieldMapping(fieldKey: 'name', csvColumn: 'Name'),
            'balance': const FieldMapping(
              fieldKey: 'balance',
              csvColumn: 'Balance',
            ),
          },
        ),
      );
      expect(state.getBadgeForField('name'), 1);
      expect(state.getBadgeForField('balance'), 2);
    });

    test('returns null for unmapped field', () {
      final state = FlexibleCsvImportState(
        config: _makeConfig(
          headers: ['Name'],
          fieldMappings: {
            'name': const FieldMapping(fieldKey: 'name'),
          },
        ),
      );
      expect(state.getBadgeForField('name'), isNull);
    });
  });

  group('FlexibleCsvImportState.totalFieldCount', () {
    test('returns 0 when no entityType', () {
      const state = FlexibleCsvImportState();
      expect(state.totalFieldCount, 0);
    });

    test('transaction: excludes FK and amount/type, adds 3 consolidated', () {
      const state = FlexibleCsvImportState(
        entityType: ImportEntityType.transaction,
      );
      // Transaction fields: id, amount, type, categoryId, categoryName,
      // accountId, accountName, date, note, currency, lastUpdatedAt = 11
      // FK fields: categoryId, categoryName, accountId, accountName = 4
      // amount/type = 2
      // Non-excluded = 11 - 4 - 2 = 5
      // + 3 consolidated = 8
      expect(state.totalFieldCount, 8);
    });

    test('account: counts non-FK fields only', () {
      const state = FlexibleCsvImportState(
        entityType: ImportEntityType.account,
      );
      // Account has no FK fields, so all fields counted
      // accountFields has 9 fields, none are FK
      expect(state.totalFieldCount, 9);
    });

    test('category: excludes FK fields', () {
      const state = FlexibleCsvImportState(
        entityType: ImportEntityType.category,
      );
      // Category has 11 fields total, parentId is FK = 1
      // 11 - 1 = 10
      expect(state.totalFieldCount, 10);
    });
  });

  group('FlexibleCsvImportState.mappedFieldCount', () {
    test('returns 0 when no config', () {
      const state = FlexibleCsvImportState();
      expect(state.mappedFieldCount, 0);
    });

    test('counts mapped non-FK fields for accounts', () {
      final state = FlexibleCsvImportState(
        entityType: ImportEntityType.account,
        config: _makeConfig(
          entityType: ImportEntityType.account,
          fieldMappings: {
            'name': const FieldMapping(fieldKey: 'name', csvColumn: 'Name'),
            'balance': const FieldMapping(
              fieldKey: 'balance',
              csvColumn: 'Balance',
            ),
            'type': const FieldMapping(fieldKey: 'type'), // not mapped
          },
        ),
      );
      expect(state.mappedFieldCount, 2);
    });

    test('transaction: adds FK/amount configs if valid', () {
      final state = FlexibleCsvImportState(
        entityType: ImportEntityType.transaction,
        config: _makeConfig(
          entityType: ImportEntityType.transaction,
          headers: ['Date', 'Note'],
          fieldMappings: {
            'date': const FieldMapping(fieldKey: 'date', csvColumn: 'Date'),
            'note': const FieldMapping(fieldKey: 'note', csvColumn: 'Note'),
          },
        ),
        categoryConfig: const ForeignKeyConfig(
          mode: ForeignKeyResolutionMode.mapFromCsv,
          nameColumn: 'Category',
        ),
        accountConfig: const ForeignKeyConfig(
          mode: ForeignKeyResolutionMode.useSameForAll,
          selectedEntityId: 'acc-1',
        ),
        amountConfig: const AmountConfig(
          mode: AmountResolutionMode.signedAmount,
          amountColumn: 'Amount',
        ),
      );
      // 2 mapped regular fields + 3 valid configs = 5
      expect(state.mappedFieldCount, 5);
    });
  });
}
