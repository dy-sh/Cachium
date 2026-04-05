import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/core/database/services/import/import_helpers.dart';
import 'package:cachium/core/exceptions/app_exception.dart';

void main() {
  group('FilePickResult', () {
    test('success has paths and no error', () {
      const result = FilePickResult.success(['/tmp/file.csv']);
      expect(result.isSuccess, isTrue);
      expect(result.isError, isFalse);
      expect(result.isCancelled, isFalse);
      expect(result.paths, ['/tmp/file.csv']);
    });

    test('error has error and no paths', () {
      const result = FilePickResult.error('Permission denied');
      expect(result.isSuccess, isFalse);
      expect(result.isError, isTrue);
      expect(result.isCancelled, isFalse);
      expect(result.error, 'Permission denied');
    });

    test('cancelled has no paths and no error', () {
      const result = FilePickResult.success(null);
      expect(result.isSuccess, isFalse);
      expect(result.isError, isFalse);
      expect(result.isCancelled, isTrue);
    });
  });

  group('ImportResult', () {
    test('totalImported sums all entity counts', () {
      const result = ImportResult(
        transactionsImported: 10,
        accountsImported: 3,
        categoriesImported: 5,
        settingsImported: 1,
        budgetsImported: 2,
        assetsImported: 4,
        recurringRulesImported: 1,
        savingsGoalsImported: 2,
        templatesImported: 1,
      );
      expect(result.totalImported, 29);
    });

    test('totalImported with defaults', () {
      const result = ImportResult(
        transactionsImported: 10,
        accountsImported: 3,
        categoriesImported: 5,
      );
      expect(result.totalImported, 18);
    });

    test('hasErrors true when errors non-empty', () {
      const result = ImportResult(
        transactionsImported: 0,
        accountsImported: 0,
        categoriesImported: 0,
        errors: ['something failed'],
      );
      expect(result.hasErrors, isTrue);
    });

    test('hasErrors false when no errors', () {
      const result = ImportResult(
        transactionsImported: 10,
        accountsImported: 0,
        categoriesImported: 0,
      );
      expect(result.hasErrors, isFalse);
    });
  });

  group('validateTableName', () {
    test('accepts valid table names', () {
      expect(validateTableName('transactions'), 'transactions');
      expect(validateTableName('accounts'), 'accounts');
      expect(validateTableName('categories'), 'categories');
      expect(validateTableName('budgets'), 'budgets');
      expect(validateTableName('assets'), 'assets');
      expect(validateTableName('recurring_rules'), 'recurring_rules');
      expect(validateTableName('savings_goals'), 'savings_goals');
      expect(validateTableName('transaction_templates'), 'transaction_templates');
      expect(validateTableName('app_settings'), 'app_settings');
    });

    test('rejects invalid table name', () {
      expect(
        () => validateTableName('users'),
        throwsA(isA<ImportException>()),
      );
    });

    test('rejects SQL injection attempt', () {
      expect(
        () => validateTableName('transactions; DROP TABLE accounts'),
        throwsA(isA<ImportException>()),
      );
    });

    test('rejects empty string', () {
      expect(
        () => validateTableName(''),
        throwsA(isA<ImportException>()),
      );
    });
  });

  group('validateColumnName', () {
    test('accepts valid column names', () {
      expect(validateColumnName('id'), 'id');
      expect(validateColumnName('is_deleted'), 'is_deleted');
      expect(validateColumnName('isDeleted'), 'isDeleted');
      expect(validateColumnName('encrypted_blob'), 'encrypted_blob');
      expect(validateColumnName('date'), 'date');
      expect(validateColumnName('name'), 'name');
    });

    test('rejects invalid column name', () {
      expect(
        () => validateColumnName('password'),
        throwsA(isA<ImportException>()),
      );
    });

    test('rejects SQL injection attempt', () {
      expect(
        () => validateColumnName('id; DROP TABLE'),
        throwsA(isA<ImportException>()),
      );
    });
  });

  group('safe casting helpers', () {
    test('safeString accepts String', () {
      expect(safeString('hello', 'field'), 'hello');
    });

    test('safeString throws on null', () {
      expect(() => safeString(null, 'name'), throwsFormatException);
    });

    test('safeString throws on non-String', () {
      expect(() => safeString(42, 'name'), throwsFormatException);
    });

    test('safeString includes rowId in error', () {
      expect(
        () => safeString(null, 'name', 'row-5'),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('row-5'),
        )),
      );
    });

    test('safeInt accepts int', () {
      expect(safeInt(42, 'field'), 42);
    });

    test('safeInt throws on null', () {
      expect(() => safeInt(null, 'count'), throwsFormatException);
    });

    test('safeInt throws on String', () {
      expect(() => safeInt('42', 'count'), throwsFormatException);
    });

    test('safeDouble accepts int', () {
      expect(safeDouble(42, 'amount'), 42.0);
    });

    test('safeDouble accepts double', () {
      expect(safeDouble(3.14, 'amount'), 3.14);
    });

    test('safeDouble throws on null', () {
      expect(() => safeDouble(null, 'amount'), throwsFormatException);
    });

    test('safeDouble throws on String', () {
      expect(() => safeDouble('3.14', 'amount'), throwsFormatException);
    });

    test('safeStringOrNull returns null for null', () {
      expect(safeStringOrNull(null), isNull);
    });

    test('safeStringOrNull returns String as-is', () {
      expect(safeStringOrNull('hello'), 'hello');
    });

    test('safeStringOrNull converts non-String to String', () {
      expect(safeStringOrNull(42), '42');
    });

    test('safeIntOrNull returns null for null', () {
      expect(safeIntOrNull(null), isNull);
    });

    test('safeIntOrNull returns int as-is', () {
      expect(safeIntOrNull(42), 42);
    });

    test('safeIntOrNull throws on non-int', () {
      expect(() => safeIntOrNull('42'), throwsFormatException);
    });

    test('safeDoubleOrNull returns null for null', () {
      expect(safeDoubleOrNull(null), isNull);
    });

    test('safeDoubleOrNull returns double for num', () {
      expect(safeDoubleOrNull(3.14), 3.14);
      expect(safeDoubleOrNull(42), 42.0);
    });

    test('safeDoubleOrNull throws on non-num', () {
      expect(() => safeDoubleOrNull('3.14'), throwsFormatException);
    });

    test('safeBlob accepts Uint8List', () {
      final blob = Uint8List.fromList([1, 2, 3]);
      expect(safeBlob(blob, 'data'), blob);
    });

    test('safeBlob throws on null', () {
      expect(() => safeBlob(null, 'data'), throwsFormatException);
    });

    test('safeBlob throws on non-Uint8List', () {
      expect(() => safeBlob([1, 2, 3], 'data'), throwsFormatException);
    });
  });
}
