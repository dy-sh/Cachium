import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/settings/data/models/flexible_csv_import_config.dart';

void main() {
  group('FlexibleCsvImportConfig.getSampleValues', () {
    test('returns up to 3 sample values', () {
      final config = const FlexibleCsvImportConfig(
        entityType: ImportEntityType.account,
        filePath: '/tmp/test.csv',
        csvHeaders: ['name', 'balance'],
        csvRows: [
          ['Alice', '100'],
          ['Bob', '200'],
          ['Carol', '300'],
          ['Dave', '400'],
        ],
        fieldMappings: {},
      );
      expect(config.getSampleValues('name'), ['Alice', 'Bob', 'Carol']);
    });

    test('returns empty for unknown column', () {
      final config = const FlexibleCsvImportConfig(
        entityType: ImportEntityType.account,
        filePath: '/tmp/test.csv',
        csvHeaders: ['name'],
        csvRows: [['Alice']],
        fieldMappings: {},
      );
      expect(config.getSampleValues('unknown'), isEmpty);
    });

    test('skips empty and null values', () {
      final config = const FlexibleCsvImportConfig(
        entityType: ImportEntityType.account,
        filePath: '/tmp/test.csv',
        csvHeaders: ['name'],
        csvRows: [
          [''],
          ['Alice'],
          [null],
          ['Bob'],
          ['null'],
        ],
        fieldMappings: {},
      );
      expect(config.getSampleValues('name'), ['Alice', 'Bob']);
    });

    test('handles rows shorter than column index', () {
      final config = const FlexibleCsvImportConfig(
        entityType: ImportEntityType.account,
        filePath: '/tmp/test.csv',
        csvHeaders: ['a', 'b', 'c'],
        csvRows: [
          ['x'],
          ['x', 'y'],
          ['x', 'y', 'z'],
        ],
        fieldMappings: {},
      );
      expect(config.getSampleValues('c'), ['z']);
    });
  });

  group('FlexibleCsvImportConfig.copyWith', () {
    test('clearPresetName sets to null', () {
      final config = const FlexibleCsvImportConfig(
        entityType: ImportEntityType.account,
        filePath: '/tmp/test.csv',
        csvHeaders: [],
        csvRows: [],
        fieldMappings: {},
        presetName: 'Cachium',
      );
      final copy = config.copyWith(clearPresetName: true);
      expect(copy.presetName, isNull);
    });
  });

  group('ImportEntityType', () {
    test('displayName returns correct values', () {
      expect(ImportEntityType.account.displayName, 'Accounts');
      expect(ImportEntityType.category.displayName, 'Categories');
      expect(ImportEntityType.transaction.displayName, 'Transactions');
    });
  });

  group('ImportFieldDefinitions.getFieldsForType', () {
    test('returns account fields', () {
      final fields = ImportFieldDefinitions.getFieldsForType(
        ImportEntityType.account,
      );
      expect(fields, isNotEmpty);
      expect(fields.any((f) => f.key == 'name'), isTrue);
      expect(fields.any((f) => f.key == 'balance'), isTrue);
    });

    test('returns category fields', () {
      final fields = ImportFieldDefinitions.getFieldsForType(
        ImportEntityType.category,
      );
      expect(fields, isNotEmpty);
      expect(fields.any((f) => f.key == 'name'), isTrue);
      expect(fields.any((f) => f.key == 'type'), isTrue);
    });

    test('returns transaction fields', () {
      final fields = ImportFieldDefinitions.getFieldsForType(
        ImportEntityType.transaction,
      );
      expect(fields, isNotEmpty);
      expect(fields.any((f) => f.key == 'amount'), isTrue);
      expect(fields.any((f) => f.key == 'date'), isTrue);
    });

    test('transaction fields include FK fields', () {
      final fields = ImportFieldDefinitions.getFieldsForType(
        ImportEntityType.transaction,
      );
      final fkFields = fields.where((f) => f.isForeignKey);
      expect(fkFields.length, greaterThanOrEqualTo(2));
    });
  });

  group('FieldMapping.copyWith', () {
    test('clearCsvColumn sets to null', () {
      const mapping = FieldMapping(fieldKey: 'name', csvColumn: 'Name');
      final copy = mapping.copyWith(clearCsvColumn: true);
      expect(copy.csvColumn, isNull);
      expect(copy.fieldKey, 'name');
    });
  });
}
