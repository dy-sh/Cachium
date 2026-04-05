import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/settings/data/models/field_mapping_options.dart';

void main() {
  group('AmountConfig.isValid', () {
    test('false when amountColumn is null', () {
      const config = AmountConfig();
      expect(config.isValid, isFalse);
    });

    test('separateAmountAndType: false when typeColumn is null', () {
      const config = AmountConfig(
        mode: AmountResolutionMode.separateAmountAndType,
        amountColumn: 'amount',
      );
      expect(config.isValid, isFalse);
    });

    test('separateAmountAndType: true when both columns set', () {
      const config = AmountConfig(
        mode: AmountResolutionMode.separateAmountAndType,
        amountColumn: 'amount',
        typeColumn: 'type',
      );
      expect(config.isValid, isTrue);
    });

    test('signedAmount: true with only amountColumn', () {
      const config = AmountConfig(
        mode: AmountResolutionMode.signedAmount,
        amountColumn: 'amount',
      );
      expect(config.isValid, isTrue);
    });

    test('signedAmount: false without amountColumn', () {
      const config = AmountConfig(
        mode: AmountResolutionMode.signedAmount,
      );
      expect(config.isValid, isFalse);
    });
  });

  group('AmountConfig.getDisplaySummary', () {
    test('separateAmountAndType with both columns', () {
      const config = AmountConfig(
        mode: AmountResolutionMode.separateAmountAndType,
        amountColumn: 'Amount',
        typeColumn: 'Type',
      );
      expect(config.getDisplaySummary(), '"Amount" + "Type"');
    });

    test('separateAmountAndType with only amount', () {
      const config = AmountConfig(
        mode: AmountResolutionMode.separateAmountAndType,
        amountColumn: 'Amount',
      );
      expect(config.getDisplaySummary(), '"Amount"');
    });

    test('separateAmountAndType with only type', () {
      const config = AmountConfig(
        mode: AmountResolutionMode.separateAmountAndType,
        typeColumn: 'Type',
      );
      expect(config.getDisplaySummary(), '"Type"');
    });

    test('separateAmountAndType with neither', () {
      const config = AmountConfig(
        mode: AmountResolutionMode.separateAmountAndType,
      );
      expect(config.getDisplaySummary(), 'Select fields...');
    });

    test('signedAmount with column', () {
      const config = AmountConfig(
        mode: AmountResolutionMode.signedAmount,
        amountColumn: 'Value',
      );
      expect(config.getDisplaySummary(), '"Value"');
    });

    test('signedAmount without column', () {
      const config = AmountConfig(
        mode: AmountResolutionMode.signedAmount,
      );
      expect(config.getDisplaySummary(), 'Select field...');
    });
  });

  group('AmountConfig equality', () {
    test('equal configs are equal', () {
      const a = AmountConfig(amountColumn: 'a', typeColumn: 'b');
      const b = AmountConfig(amountColumn: 'a', typeColumn: 'b');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different configs are not equal', () {
      const a = AmountConfig(amountColumn: 'a');
      const b = AmountConfig(amountColumn: 'b');
      expect(a, isNot(equals(b)));
    });
  });

  group('AmountConfig.copyWith', () {
    test('updates fields', () {
      const config = AmountConfig(amountColumn: 'old');
      final copy = config.copyWith(amountColumn: 'new');
      expect(copy.amountColumn, 'new');
    });

    test('clearAmountColumn sets to null', () {
      const config = AmountConfig(amountColumn: 'amount');
      final copy = config.copyWith(clearAmountColumn: true);
      expect(copy.amountColumn, isNull);
    });

    test('clearTypeColumn sets to null', () {
      const config = AmountConfig(typeColumn: 'type');
      final copy = config.copyWith(clearTypeColumn: true);
      expect(copy.typeColumn, isNull);
    });
  });

  group('ForeignKeyConfig.isValid', () {
    test('mapFromCsv: false when no columns', () {
      const config = ForeignKeyConfig(
        mode: ForeignKeyResolutionMode.mapFromCsv,
      );
      expect(config.isValid, isFalse);
    });

    test('mapFromCsv: true with nameColumn', () {
      const config = ForeignKeyConfig(
        mode: ForeignKeyResolutionMode.mapFromCsv,
        nameColumn: 'category_name',
      );
      expect(config.isValid, isTrue);
    });

    test('mapFromCsv: true with idColumn', () {
      const config = ForeignKeyConfig(
        mode: ForeignKeyResolutionMode.mapFromCsv,
        idColumn: 'category_id',
      );
      expect(config.isValid, isTrue);
    });

    test('mapFromCsv: true with both columns', () {
      const config = ForeignKeyConfig(
        mode: ForeignKeyResolutionMode.mapFromCsv,
        nameColumn: 'name',
        idColumn: 'id',
      );
      expect(config.isValid, isTrue);
    });

    test('useSameForAll: false without selectedEntityId', () {
      const config = ForeignKeyConfig(
        mode: ForeignKeyResolutionMode.useSameForAll,
      );
      expect(config.isValid, isFalse);
    });

    test('useSameForAll: true with selectedEntityId', () {
      const config = ForeignKeyConfig(
        mode: ForeignKeyResolutionMode.useSameForAll,
        selectedEntityId: 'cat-1',
      );
      expect(config.isValid, isTrue);
    });
  });

  group('ForeignKeyConfig.getDisplaySummary', () {
    test('mapFromCsv with both columns', () {
      const config = ForeignKeyConfig(
        mode: ForeignKeyResolutionMode.mapFromCsv,
        nameColumn: 'Name',
        idColumn: 'ID',
      );
      expect(config.getDisplaySummary(), 'Mapping "Name" + "ID"');
    });

    test('mapFromCsv with only name', () {
      const config = ForeignKeyConfig(
        mode: ForeignKeyResolutionMode.mapFromCsv,
        nameColumn: 'Category',
      );
      expect(config.getDisplaySummary(), 'Mapping "Category" column');
    });

    test('mapFromCsv with only id', () {
      const config = ForeignKeyConfig(
        mode: ForeignKeyResolutionMode.mapFromCsv,
        idColumn: 'cat_id',
      );
      expect(config.getDisplaySummary(), 'Mapping "cat_id" column');
    });

    test('mapFromCsv with neither', () {
      const config = ForeignKeyConfig(
        mode: ForeignKeyResolutionMode.mapFromCsv,
      );
      expect(config.getDisplaySummary(), 'Select column...');
    });

    test('useSameForAll with entity name', () {
      const config = ForeignKeyConfig(
        mode: ForeignKeyResolutionMode.useSameForAll,
        selectedEntityId: 'cat-1',
      );
      expect(config.getDisplaySummary(entityName: 'Food'), 'Using: Food');
    });

    test('useSameForAll without entity name', () {
      const config = ForeignKeyConfig(
        mode: ForeignKeyResolutionMode.useSameForAll,
      );
      expect(config.getDisplaySummary(), 'Select...');
    });
  });

  group('ForeignKeyConfig equality', () {
    test('equal configs are equal', () {
      const a = ForeignKeyConfig(nameColumn: 'x', idColumn: 'y');
      const b = ForeignKeyConfig(nameColumn: 'x', idColumn: 'y');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different configs are not equal', () {
      const a = ForeignKeyConfig(nameColumn: 'x');
      const b = ForeignKeyConfig(nameColumn: 'y');
      expect(a, isNot(equals(b)));
    });
  });

  group('ForeignKeyConfig.copyWith', () {
    test('clearNameColumn sets to null', () {
      const config = ForeignKeyConfig(nameColumn: 'name');
      final copy = config.copyWith(clearNameColumn: true);
      expect(copy.nameColumn, isNull);
    });

    test('clearIdColumn sets to null', () {
      const config = ForeignKeyConfig(idColumn: 'id');
      final copy = config.copyWith(clearIdColumn: true);
      expect(copy.idColumn, isNull);
    });

    test('clearSelectedEntityId sets to null', () {
      const config = ForeignKeyConfig(selectedEntityId: 'cat-1');
      final copy = config.copyWith(clearSelectedEntityId: true);
      expect(copy.selectedEntityId, isNull);
    });
  });
}
