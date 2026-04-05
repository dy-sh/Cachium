import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/core/database/services/import/csv_validator.dart';

void main() {
  // Suppress debugPrint from AppLogger during tests.
  late DebugPrintCallback originalDebugPrint;
  setUp(() {
    originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {};
  });
  tearDown(() => debugPrint = originalDebugPrint);

  group('hasColumn', () {
    test('finds snake_case column', () {
      final headers = {'id', 'encrypted_blob', 'date'};
      expect(hasColumn(headers, 'encrypted_blob', 'encryptedBlob'), isTrue);
    });

    test('finds camelCase column (lowercased)', () {
      final headers = {'id', 'encryptedblob', 'date'};
      expect(hasColumn(headers, 'encrypted_blob', 'encryptedBlob'), isTrue);
    });

    test('returns false when neither present', () {
      final headers = {'id', 'date'};
      expect(hasColumn(headers, 'encrypted_blob', 'encryptedBlob'), isFalse);
    });
  });

  group('validateTransactionsCsv', () {
    test('accepts valid encrypted transaction headers', () {
      final headers = {
        'id', 'date', 'last_updated_at', 'is_deleted', 'encrypted_blob',
      };
      expect(validateTransactionsCsv(headers), isNull);
    });

    test('accepts valid plaintext transaction headers', () {
      final headers = {
        'id', 'date', 'last_updated_at', 'amount', 'category_id',
        'account_id', 'type', 'currency',
      };
      expect(validateTransactionsCsv(headers), isNull);
    });

    test('reports missing encrypted columns', () {
      final headers = {'id', 'date', 'encrypted_blob'};
      final result = validateTransactionsCsv(headers);
      expect(result, isNotNull);
      expect(result, contains('missing columns'));
      expect(result, contains('last_updated_at'));
    });

    test('reports missing plaintext columns', () {
      final headers = {'id', 'date', 'last_updated_at'};
      final result = validateTransactionsCsv(headers);
      expect(result, isNotNull);
      expect(result, contains('missing columns'));
    });

    test('accepts camelCase headers for encrypted', () {
      final headers = {
        'id', 'date', 'lastupdatedat', 'isdeleted', 'encryptedblob',
      };
      expect(validateTransactionsCsv(headers), isNull);
    });
  });

  group('validateAccountsCsv', () {
    test('accepts valid encrypted account headers', () {
      final headers = {
        'id', 'created_at', 'last_updated_at', 'is_deleted', 'encrypted_blob',
      };
      expect(validateAccountsCsv(headers), isNull);
    });

    test('accepts valid plaintext account headers', () {
      final headers = {
        'id', 'created_at', 'last_updated_at', 'name', 'type', 'balance',
      };
      expect(validateAccountsCsv(headers), isNull);
    });

    test('reports missing columns', () {
      final headers = {'id', 'name'};
      final result = validateAccountsCsv(headers);
      expect(result, isNotNull);
      expect(result, contains('Accounts file missing'));
    });
  });

  group('validateCategoriesCsv', () {
    test('accepts valid encrypted category headers', () {
      final headers = {
        'id', 'sort_order', 'last_updated_at', 'is_deleted', 'encrypted_blob',
      };
      expect(validateCategoriesCsv(headers), isNull);
    });

    test('accepts valid plaintext category headers', () {
      final headers = {
        'id', 'sort_order', 'last_updated_at', 'name', 'icon_code_point',
        'icon_font_family', 'color_index', 'type', 'is_custom',
      };
      expect(validateCategoriesCsv(headers), isNull);
    });

    test('reports missing columns', () {
      final headers = {'id', 'name'};
      final result = validateCategoriesCsv(headers);
      expect(result, isNotNull);
      expect(result, contains('Categories file missing'));
    });
  });

  group('validateSettingsCsv', () {
    test('accepts valid settings headers', () {
      final headers = {'id', 'last_updated_at', 'json_data'};
      expect(validateSettingsCsv(headers), isNull);
    });

    test('accepts camelCase headers', () {
      final headers = {'id', 'lastupdatedat', 'jsondata'};
      expect(validateSettingsCsv(headers), isNull);
    });

    test('reports missing columns', () {
      final headers = {'id'};
      final result = validateSettingsCsv(headers);
      expect(result, isNotNull);
      expect(result, contains('Settings file missing'));
    });
  });

  group('validateGenericEncryptedCsv', () {
    test('accepts headers with id column', () {
      final headers = {'id', 'encrypted_blob'};
      expect(validateGenericEncryptedCsv(headers, 'Budgets'), isNull);
    });

    test('reports missing id column', () {
      final headers = {'encrypted_blob', 'date'};
      final result = validateGenericEncryptedCsv(headers, 'Budgets');
      expect(result, 'Budgets file missing required column: id');
    });
  });
}
