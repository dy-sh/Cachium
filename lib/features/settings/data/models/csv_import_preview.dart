/// Represents the type of CSV file being imported.
enum CsvFileType {
  settings,
  transactions,
  accounts,
  categories;

  String get displayName {
    switch (this) {
      case CsvFileType.settings:
        return 'Settings';
      case CsvFileType.transactions:
        return 'Transactions';
      case CsvFileType.accounts:
        return 'Accounts';
      case CsvFileType.categories:
        return 'Categories';
    }
  }
}

/// Represents the status of a single CSV file in the import.
class CsvFileStatus {
  final CsvFileType type;
  final bool isSelected;
  final String? filePath;
  final int recordCount;

  const CsvFileStatus({
    required this.type,
    required this.isSelected,
    this.filePath,
    this.recordCount = 0,
  });
}

/// Preview data for CSV import, showing what will be imported
/// and any potential issues.
class CsvImportPreview {
  final List<CsvFileStatus> fileStatuses;
  final int transactionCount;
  final int accountCount;
  final int categoryCount;
  final int settingsCount;
  final int duplicateTransactionCount;
  final int duplicateAccountCount;
  final int duplicateCategoryCount;
  final int newTransactionCount;
  final int newAccountCount;
  final int newCategoryCount;
  final Set<String> missingCategoryIds;
  final Set<String> missingAccountIds;
  final List<String> filePaths;

  const CsvImportPreview({
    required this.fileStatuses,
    required this.transactionCount,
    required this.accountCount,
    required this.categoryCount,
    required this.settingsCount,
    required this.duplicateTransactionCount,
    required this.duplicateAccountCount,
    required this.duplicateCategoryCount,
    required this.newTransactionCount,
    required this.newAccountCount,
    required this.newCategoryCount,
    required this.missingCategoryIds,
    required this.missingAccountIds,
    required this.filePaths,
  });

  /// Total records that will be imported (excluding duplicates).
  int get totalNewRecords =>
      newTransactionCount + newAccountCount + newCategoryCount + settingsCount;

  /// Total duplicate count across all types.
  int get totalDuplicateCount =>
      duplicateTransactionCount + duplicateAccountCount + duplicateCategoryCount;

  /// Whether there are any duplicates.
  bool get hasDuplicates => totalDuplicateCount > 0;

  /// Whether there are any missing references.
  bool get hasMissingReferences =>
      missingCategoryIds.isNotEmpty || missingAccountIds.isNotEmpty;

  /// Total count of missing references.
  int get missingReferenceCount =>
      missingCategoryIds.length + missingAccountIds.length;
}
