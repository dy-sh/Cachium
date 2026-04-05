import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/settings/data/models/import_preset.dart';
import 'package:cachium/features/settings/data/models/flexible_csv_import_config.dart';

void main() {
  group('ImportPreset.getMatchScore', () {
    test('returns 0 for empty mappings', () {
      const preset = ImportPreset(
        id: 'test',
        name: 'Test',
        description: 'Test',
        entityType: ImportEntityType.transaction,
        columnMappings: {},
      );
      expect(preset.getMatchScore(['col1', 'col2']), 0.0);
    });

    test('returns 1.0 for perfect match', () {
      const preset = ImportPreset(
        id: 'test',
        name: 'Test',
        description: 'Test',
        entityType: ImportEntityType.transaction,
        columnMappings: {'amount': 'Amount', 'date': 'Date'},
      );
      expect(preset.getMatchScore(['Amount', 'Date']), 1.0);
    });

    test('returns 0.5 for half match', () {
      const preset = ImportPreset(
        id: 'test',
        name: 'Test',
        description: 'Test',
        entityType: ImportEntityType.transaction,
        columnMappings: {'amount': 'Amount', 'date': 'Date'},
      );
      expect(preset.getMatchScore(['Amount', 'Other']), 0.5);
    });

    test('returns 0 for no match', () {
      const preset = ImportPreset(
        id: 'test',
        name: 'Test',
        description: 'Test',
        entityType: ImportEntityType.transaction,
        columnMappings: {'amount': 'Amount'},
      );
      expect(preset.getMatchScore(['Other']), 0.0);
    });

    test('normalizes column names (case insensitive, ignores underscores/spaces)', () {
      const preset = ImportPreset(
        id: 'test',
        name: 'Test',
        description: 'Test',
        entityType: ImportEntityType.transaction,
        columnMappings: {'id': 'category_id'},
      );
      // 'Category ID' normalizes to 'categoryid', 'category_id' normalizes to 'categoryid'
      expect(preset.getMatchScore(['Category ID']), 1.0);
    });

    test('handles snake_case vs camelCase normalization', () {
      const preset = ImportPreset(
        id: 'test',
        name: 'Test',
        description: 'Test',
        entityType: ImportEntityType.transaction,
        columnMappings: {'date': 'last_updated_at'},
      );
      // 'last updated at' → 'lastupdatedat', 'last_updated_at' → 'lastupdatedat'
      expect(preset.getMatchScore(['last updated at']), 1.0);
    });
  });

  group('ImportPreset.isGoodMatch', () {
    test('true when score >= 0.7', () {
      const preset = ImportPreset(
        id: 'test',
        name: 'Test',
        description: 'Test',
        entityType: ImportEntityType.transaction,
        columnMappings: {
          'a': 'col1',
          'b': 'col2',
          'c': 'col3',
          'd': 'col4',
          'e': 'col5',
          'f': 'col6',
          'g': 'col7',
          'h': 'col8',
          'i': 'col9',
          'j': 'col10',
        },
      );
      // 7 out of 10 match = 0.7
      expect(
        preset.isGoodMatch([
          'col1', 'col2', 'col3', 'col4', 'col5', 'col6', 'col7',
          'other1', 'other2', 'other3',
        ]),
        isTrue,
      );
    });

    test('false when score < 0.7', () {
      const preset = ImportPreset(
        id: 'test',
        name: 'Test',
        description: 'Test',
        entityType: ImportEntityType.transaction,
        columnMappings: {
          'a': 'col1',
          'b': 'col2',
          'c': 'col3',
          'd': 'col4',
          'e': 'col5',
        },
      );
      // 3 out of 5 = 0.6 < 0.7
      expect(
        preset.isGoodMatch(['col1', 'col2', 'col3', 'other1', 'other2']),
        isFalse,
      );
    });
  });

  group('BuiltInPresets', () {
    test('getPresetForType returns correct presets', () {
      expect(
        BuiltInPresets.getPresetForType(ImportEntityType.transaction)?.id,
        'cachium_transactions',
      );
      expect(
        BuiltInPresets.getPresetForType(ImportEntityType.account)?.id,
        'cachium_accounts',
      );
      expect(
        BuiltInPresets.getPresetForType(ImportEntityType.category)?.id,
        'cachium_categories',
      );
    });

    test('getPresetsForType returns non-empty lists', () {
      for (final type in ImportEntityType.values) {
        expect(BuiltInPresets.getPresetsForType(type), isNotEmpty);
      }
    });

    test('detectPreset returns null for non-matching headers', () {
      final result = BuiltInPresets.detectPreset(
        ImportEntityType.transaction,
        ['foo', 'bar', 'baz'],
      );
      expect(result, isNull);
    });

    test('detectPreset returns preset for matching headers', () {
      final result = BuiltInPresets.detectPreset(
        ImportEntityType.transaction,
        [
          'id', 'amount', 'type', 'category_id', 'account_id',
          'date', 'note', 'currency', 'last_updated_at',
        ],
      );
      expect(result, isNotNull);
      expect(result!.id, 'cachium_transactions');
    });
  });
}
