import 'dart:io';

import 'package:csv/csv.dart';

import '../../app_database.dart';

int findColumnIndex(List<String> headers, List<String> possibleNames) {
  for (final name in possibleNames) {
    final index = headers.indexOf(name);
    if (index >= 0) return index;
  }
  return -1;
}

Future<Set<String>> getExistingTransactionIds(AppDatabase database) async {
  final result = await database.select(database.transactions).get();
  return result.map((t) => t.id).toSet();
}

Future<Set<String>> getExistingCategoryIds(AppDatabase database) async {
  final result = await database.select(database.categories).get();
  return result.map((c) => c.id).toSet();
}

Future<Set<String>> getExistingAccountIds(AppDatabase database) async {
  final result = await database.select(database.accounts).get();
  return result.map((a) => a.id).toSet();
}

class ParsedCsvFile {
  final List<String> headers;
  final List<List<dynamic>> rows;
  final bool hasEncryptedBlob;

  ParsedCsvFile({
    required this.headers,
    required this.rows,
    required this.hasEncryptedBlob,
  });
}

Future<ParsedCsvFile?> parseCsvFile(String path) async {
  final content = await File(path).readAsString();
  final rows = const CsvToListConverter().convert(content);

  if (rows.isEmpty) return null;

  final headers = rows.first.map((e) => e.toString()).toList();
  final hasEncryptedBlob = headers.contains('encrypted_blob') || headers.contains('encryptedBlob');

  return ParsedCsvFile(
    headers: headers,
    rows: rows,
    hasEncryptedBlob: hasEncryptedBlob,
  );
}

Map<String, dynamic> rowToMap(List<String> headers, List<dynamic> row) {
  final data = <String, dynamic>{};
  for (int j = 0; j < headers.length; j++) {
    data[headers[j]] = row[j];
  }
  return data;
}
