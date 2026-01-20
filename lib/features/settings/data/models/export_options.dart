/// Configuration options for database export.
class ExportOptions {
  /// Whether to encrypt sensitive data in the export.
  /// Default: true for both SQLite and CSV exports.
  final bool encryptionEnabled;

  const ExportOptions({
    this.encryptionEnabled = true,
  });

  ExportOptions copyWith({
    bool? encryptionEnabled,
  }) {
    return ExportOptions(
      encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
    );
  }
}

/// The format to export data in.
enum ExportFormat {
  sqlite,
  csv,
}
