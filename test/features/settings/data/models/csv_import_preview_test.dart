import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/features/settings/data/models/csv_import_preview.dart';

CsvImportPreview _makePreview({
  int transactionCount = 0,
  int accountCount = 0,
  int categoryCount = 0,
  int settingsCount = 0,
  int duplicateTransactionCount = 0,
  int duplicateAccountCount = 0,
  int duplicateCategoryCount = 0,
  int newTransactionCount = 0,
  int newAccountCount = 0,
  int newCategoryCount = 0,
  Set<String> missingCategoryIds = const {},
  Set<String> missingAccountIds = const {},
}) {
  return CsvImportPreview(
    fileStatuses: const [],
    transactionCount: transactionCount,
    accountCount: accountCount,
    categoryCount: categoryCount,
    settingsCount: settingsCount,
    duplicateTransactionCount: duplicateTransactionCount,
    duplicateAccountCount: duplicateAccountCount,
    duplicateCategoryCount: duplicateCategoryCount,
    newTransactionCount: newTransactionCount,
    newAccountCount: newAccountCount,
    newCategoryCount: newCategoryCount,
    missingCategoryIds: missingCategoryIds,
    missingAccountIds: missingAccountIds,
    filePaths: const [],
  );
}

void main() {
  group('CsvImportPreview.totalNewRecords', () {
    test('sums new records across types', () {
      final preview = _makePreview(
        newTransactionCount: 10,
        newAccountCount: 3,
        newCategoryCount: 5,
        settingsCount: 1,
      );
      expect(preview.totalNewRecords, 19);
    });

    test('returns 0 when no new records', () {
      final preview = _makePreview();
      expect(preview.totalNewRecords, 0);
    });
  });

  group('CsvImportPreview.totalDuplicateCount', () {
    test('sums duplicates across types', () {
      final preview = _makePreview(
        duplicateTransactionCount: 2,
        duplicateAccountCount: 1,
        duplicateCategoryCount: 3,
      );
      expect(preview.totalDuplicateCount, 6);
    });

    test('returns 0 when no duplicates', () {
      final preview = _makePreview();
      expect(preview.totalDuplicateCount, 0);
    });
  });

  group('CsvImportPreview.hasDuplicates', () {
    test('true when duplicates exist', () {
      final preview = _makePreview(duplicateTransactionCount: 1);
      expect(preview.hasDuplicates, isTrue);
    });

    test('false when no duplicates', () {
      final preview = _makePreview();
      expect(preview.hasDuplicates, isFalse);
    });
  });

  group('CsvImportPreview.hasMissingReferences', () {
    test('true when missing category ids', () {
      final preview = _makePreview(missingCategoryIds: {'cat-1'});
      expect(preview.hasMissingReferences, isTrue);
    });

    test('true when missing account ids', () {
      final preview = _makePreview(missingAccountIds: {'acc-1'});
      expect(preview.hasMissingReferences, isTrue);
    });

    test('false when no missing references', () {
      final preview = _makePreview();
      expect(preview.hasMissingReferences, isFalse);
    });
  });

  group('CsvImportPreview.missingReferenceCount', () {
    test('sums missing category and account ids', () {
      final preview = _makePreview(
        missingCategoryIds: {'cat-1', 'cat-2'},
        missingAccountIds: {'acc-1'},
      );
      expect(preview.missingReferenceCount, 3);
    });

    test('returns 0 when no missing references', () {
      final preview = _makePreview();
      expect(preview.missingReferenceCount, 0);
    });
  });
}
