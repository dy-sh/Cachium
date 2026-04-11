import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cachium/core/database/app_database.dart';
import 'package:cachium/core/database/services/database_export_service.dart';
import 'package:cachium/core/database/services/encryption_service.dart';
import 'package:cachium/data/encryption/account_data.dart';
import 'package:cachium/data/encryption/budget_data.dart';
import 'package:cachium/data/encryption/category_data.dart';
import 'package:cachium/data/encryption/transaction_data.dart';
import 'package:cachium/features/settings/data/models/export_options.dart';
import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

import '../../../_helpers/in_memory_database.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final String tempPath;
  _FakePathProvider(this.tempPath);

  @override
  Future<String?> getTemporaryPath() async => tempPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppDatabase database;
  late EncryptionService encryption;
  late DatabaseExportService service;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('cachium_export_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);

    database = buildInMemoryDatabase();
    encryption = buildTestEncryptionService();
    service = DatabaseExportService(
      database: database,
      encryptionService: encryption,
    );
  });

  tearDown(() async {
    await database.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // --- Seed helpers ---------------------------------------------------------

  Future<Uint8List> encryptJson(Map<String, dynamic> json) =>
      encryption.encryptJson(json);

  final seedTimestamp = DateTime(2025, 1, 1).millisecondsSinceEpoch;
  final txDateMillis = DateTime(2025, 6, 1).millisecondsSinceEpoch;

  Future<void> seedTransaction({
    required String id,
    required double amount,
    required String categoryId,
    required String accountId,
    required String currency,
  }) async {
    final data = TransactionData(
      id: id,
      amount: amount,
      type: 'expense',
      categoryId: categoryId,
      accountId: accountId,
      currency: currency,
      conversionRate: 1.0,
      mainCurrencyCode: 'USD',
      mainCurrencyAmount: amount,
      dateMillis: txDateMillis,
      createdAtMillis: txDateMillis,
      isAcquisitionCost: false,
    );
    final blob = await encryptJson(data.toJson());
    await database.insertTransaction(
      id: id,
      date: data.dateMillis,
      lastUpdatedAt: data.createdAtMillis,
      encryptedBlob: blob,
    );
  }

  Future<void> seedAccount({
    required String id,
    required String name,
    required double balance,
    required String currencyCode,
  }) async {
    final data = AccountData(
      id: id,
      name: name,
      type: 'checking',
      balance: balance,
      initialBalance: balance,
      currencyCode: currencyCode,
      createdAtMillis: seedTimestamp,
    );
    final blob = await encryptJson(data.toJson());
    await database.insertAccount(
      id: id,
      createdAt: seedTimestamp,
      sortOrder: 0,
      lastUpdatedAt: seedTimestamp,
      encryptedBlob: blob,
    );
  }

  Future<void> seedCategory({
    required String id,
    required String name,
  }) async {
    final data = CategoryData(
      id: id,
      name: name,
      iconCodePoint: 0xe25a,
      iconFontFamily: 'MaterialIcons',
      colorIndex: 0,
      type: 'expense',
      sortOrder: 0,
    );
    final blob = await encryptJson(data.toJson());
    await database.insertCategory(
      id: id,
      sortOrder: 0,
      lastUpdatedAt: seedTimestamp,
      encryptedBlob: blob,
    );
  }

  Future<void> seedBudget({
    required String id,
    required String categoryId,
    required double amount,
  }) async {
    final data = BudgetData(
      id: id,
      categoryId: categoryId,
      amount: amount,
      year: 2025,
      month: 6,
      createdAtMillis: seedTimestamp,
    );
    final blob = await encryptJson(data.toJson());
    await database.insertBudget(
      id: id,
      createdAt: seedTimestamp,
      lastUpdatedAt: seedTimestamp,
      encryptedBlob: blob,
    );
  }

  Future<void> seedSettingsWithCredentials() async {
    final settingsJson = jsonEncode({
      'mainCurrencyCode': 'USD',
      'themeMode': 'dark',
      'appPinCode': 'pbkdf2:100000:c2FsdA==:aGFzaA==',
      'appPassword': 'pbkdf2:100000:c2FsdA==:cGFzc3dkaGFzaA==',
    });
    await database.upsertSettings(
      id: 'main',
      lastUpdatedAt: DateTime(2025, 1, 1).millisecondsSinceEpoch,
      jsonData: settingsJson,
    );
  }

  // --- Tests ----------------------------------------------------------------

  group('exportToSqlite (encrypted)', () {
    test('roundtrips a seeded database: decrypting blobs matches source',
        () async {
      await seedAccount(
        id: 'acc-1',
        name: 'Checking',
        balance: 1000,
        currencyCode: 'USD',
      );
      await seedCategory(id: 'cat-1', name: 'Food');
      await seedTransaction(
        id: 'tx-1',
        amount: 42.5,
        categoryId: 'cat-1',
        accountId: 'acc-1',
        currency: 'USD',
      );
      await seedBudget(id: 'bud-1', categoryId: 'cat-1', amount: 500);

      final path = await service.exportToSqlite(const ExportOptions());

      expect(File(path).existsSync(), isTrue);
      expect(path, contains('cachium_export_'));

      // Open the exported file with raw sqlite3, read blobs, decrypt them,
      // and assert round-trip fidelity.
      final exported = sql.sqlite3.open(path);
      try {
        final txRows =
            exported.select('SELECT id, encrypted_blob FROM transactions');
        expect(txRows.length, 1);
        expect(txRows.first['id'], 'tx-1');

        final txBlob = txRows.first['encrypted_blob'] as Uint8List;
        final txJson = await encryption.decryptJson(txBlob);
        expect(txJson['amount'], 42.5);
        expect(txJson['accountId'], 'acc-1');
        expect(txJson['categoryId'], 'cat-1');

        final accRows =
            exported.select('SELECT id, encrypted_blob FROM accounts');
        expect(accRows.length, 1);
        final accBlob = accRows.first['encrypted_blob'] as Uint8List;
        final accJson = await encryption.decryptJson(accBlob);
        expect(accJson['name'], 'Checking');
        expect(accJson['balance'], 1000);

        final budRows =
            exported.select('SELECT id, encrypted_blob FROM budgets');
        expect(budRows.length, 1);
        final budBlob = budRows.first['encrypted_blob'] as Uint8List;
        final budJson = await encryption.decryptJson(budBlob);
        expect(budJson['amount'], 500);
        expect(budJson['categoryId'], 'cat-1');
      } finally {
        exported.dispose();
      }
    });

    test('strips appPinCode and appPassword from exported settings JSON',
        () async {
      await seedSettingsWithCredentials();

      final path = await service.exportToSqlite(const ExportOptions());

      final exported = sql.sqlite3.open(path);
      try {
        final rows =
            exported.select('SELECT id, json_data FROM app_settings');
        expect(rows.length, 1);

        final jsonData = rows.first['json_data'] as String;
        final parsed = jsonDecode(jsonData) as Map<String, dynamic>;

        expect(parsed.containsKey('appPinCode'), isFalse,
            reason: 'Credentials must never appear in exports');
        expect(parsed.containsKey('appPassword'), isFalse,
            reason: 'Credentials must never appear in exports');
        // Non-credential fields survive.
        expect(parsed['mainCurrencyCode'], 'USD');
        expect(parsed['themeMode'], 'dark');
      } finally {
        exported.dispose();
      }
    });

    test('empty database produces a valid file with empty tables', () async {
      final path = await service.exportToSqlite(const ExportOptions());

      expect(File(path).existsSync(), isTrue);

      final exported = sql.sqlite3.open(path);
      try {
        expect(exported.select('SELECT COUNT(*) AS c FROM transactions').first['c'],
            0);
        expect(exported.select('SELECT COUNT(*) AS c FROM accounts').first['c'],
            0);
        expect(exported.select('SELECT COUNT(*) AS c FROM budgets').first['c'],
            0);
      } finally {
        exported.dispose();
      }
    });
  });

  group('exportToCsv', () {
    test('plaintext CSV contains decrypted human-readable values', () async {
      await seedAccount(
        id: 'acc-1',
        name: 'Checking',
        balance: 1000,
        currencyCode: 'USD',
      );
      await seedCategory(id: 'cat-1', name: 'Food');
      await seedTransaction(
        id: 'tx-1',
        amount: 42.5,
        categoryId: 'cat-1',
        accountId: 'acc-1',
        currency: 'USD',
      );

      final paths =
          await service.exportToCsv(const ExportOptions(encryptionEnabled: false));

      final txPath = paths.firstWhere((p) => p.endsWith('transactions.csv'));
      final txCsv = await File(txPath).readAsString();
      final txRows = const CsvToListConverter().convert(txCsv);

      // Header row + one data row.
      expect(txRows.length, 2);
      // Amount is somewhere in the data row as a plain number.
      final dataRow = txRows[1];
      expect(dataRow.contains(42.5), isTrue,
          reason: 'Plaintext CSV should expose raw amount');
      expect(dataRow.contains('cat-1'), isTrue);
      expect(dataRow.contains('acc-1'), isTrue);

      final accPath = paths.firstWhere((p) => p.endsWith('accounts.csv'));
      final accCsv = await File(accPath).readAsString();
      final accRows = const CsvToListConverter().convert(accCsv);
      expect(accRows.length, 2);
      expect(accRows[1].contains('Checking'), isTrue);
    });

    test('encrypted CSV contains base64 blobs, not plaintext values',
        () async {
      await seedTransaction(
        id: 'tx-1',
        amount: 99.99,
        categoryId: 'cat-1',
        accountId: 'acc-1',
        currency: 'USD',
      );

      final paths =
          await service.exportToCsv(const ExportOptions(encryptionEnabled: true));

      final txPath = paths.firstWhere((p) => p.endsWith('transactions.csv'));
      final txCsv = await File(txPath).readAsString();

      // Plaintext amount should NOT appear.
      expect(txCsv.contains('99.99'), isFalse,
          reason: 'Encrypted CSV must not leak plaintext values');

      final txRows = const CsvToListConverter().convert(txCsv);
      // Header + data row.
      expect(txRows.length, 2);
      final header = txRows.first;
      expect(header, contains('encrypted_blob'));

      // Verify the blob column parses as valid base64.
      final blobColIdx = header.indexOf('encrypted_blob');
      final blobStr = txRows[1][blobColIdx] as String;
      expect(() => base64Decode(blobStr), returnsNormally);
    });

    test('settings CSV never contains plaintext credentials', () async {
      await seedSettingsWithCredentials();

      final paths =
          await service.exportToCsv(const ExportOptions(encryptionEnabled: false));

      final settingsPath =
          paths.firstWhere((p) => p.endsWith('app_settings.csv'));
      final csvContent = await File(settingsPath).readAsString();

      expect(csvContent.contains('appPinCode'), isFalse);
      expect(csvContent.contains('appPassword'), isFalse);
    });
  });

  group('cleanupPreviousExports', () {
    test('removes prior cachium_export_ files from temp dir', () async {
      final stale = File('${tempDir.path}/cachium_export_123.db');
      stale.writeAsStringSync('stale');
      final otherFile = File('${tempDir.path}/unrelated.txt');
      otherFile.writeAsStringSync('keep me');

      expect(stale.existsSync(), isTrue);
      await service.cleanupPreviousExports();

      expect(stale.existsSync(), isFalse);
      expect(otherFile.existsSync(), isTrue,
          reason: 'Cleanup must not touch non-export files');
    });

    test('removes prior cachium_csv_ directories from temp dir', () async {
      final staleDir = Directory('${tempDir.path}/cachium_csv_456');
      staleDir.createSync();
      File('${staleDir.path}/x.csv').writeAsStringSync('data');

      await service.cleanupPreviousExports();

      expect(staleDir.existsSync(), isFalse);
    });
  });
}
