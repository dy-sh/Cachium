import '../../../../features/settings/data/models/csv_import_preview.dart';
import '../../../../features/settings/data/models/database_metrics.dart';
import '../../app_database.dart';
import '../encryption_service.dart';
import 'csv_importer.dart';
import 'import_helpers.dart';
import 'sqlite_importer.dart';

export 'import_helpers.dart' show FilePickResult, ImportResult;

/// Service for importing database data from SQLite or CSV formats.
class DatabaseImportService {
  final AppDatabase database;
  final EncryptionService encryptionService;

  late final SqliteImporter _sqliteImporter;
  late final CsvImporter _csvImporter;

  DatabaseImportService({
    required this.database,
    required this.encryptionService,
  }) {
    _sqliteImporter = SqliteImporter(
      database: database,
      encryptionService: encryptionService,
    );
    _csvImporter = CsvImporter(
      database: database,
      encryptionService: encryptionService,
    );
  }

  // SQLite methods

  Future<FilePickResult> pickSqliteFile() => _sqliteImporter.pickSqliteFile();

  Future<ImportResult?> pickAndImportSqlite() => _sqliteImporter.pickAndImportSqlite();

  Future<ImportResult> clearAndImportFromSqlite(String path) =>
      _sqliteImporter.clearAndImportFromSqlite(path);

  Future<ImportResult> importFromSqlite(String path) =>
      _sqliteImporter.importFromSqlite(path);

  DatabaseMetrics getMetricsFromSqliteFile(String path) =>
      _sqliteImporter.getMetricsFromSqliteFile(path);

  // CSV methods

  Future<ImportResult?> pickAndImportCsv() => _csvImporter.pickAndImportCsv();

  Future<ImportResult> importFromCsv(List<String> paths) =>
      _csvImporter.importFromCsv(paths);

  Future<FilePickResult> pickCsvFiles() => _csvImporter.pickCsvFiles();

  Future<CsvImportPreview> generateCsvPreview(List<String> paths) =>
      _csvImporter.generateCsvPreview(paths);

  Future<ImportResult> importFromCsvWithSkipDuplicates(List<String> paths) =>
      _csvImporter.importFromCsvWithSkipDuplicates(paths);
}
