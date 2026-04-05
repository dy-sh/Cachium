import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/core/database/services/import/csv_row_parser.dart';

void main() {
  group('findColumnIndex', () {
    test('finds first matching name', () {
      final headers = ['id', 'name', 'amount', 'type'];
      expect(findColumnIndex(headers, ['amount']), 2);
    });

    test('tries multiple possible names in order', () {
      final headers = ['id', 'category_id', 'amount'];
      expect(
        findColumnIndex(headers, ['categoryId', 'category_id']),
        1,
      );
    });

    test('returns -1 when not found', () {
      final headers = ['id', 'name'];
      expect(findColumnIndex(headers, ['amount', 'value']), -1);
    });

    test('returns -1 for empty headers', () {
      expect(findColumnIndex([], ['id']), -1);
    });

    test('returns -1 for empty possible names', () {
      expect(findColumnIndex(['id', 'name'], []), -1);
    });

    test('finds first match from possible names', () {
      final headers = ['id', 'amount', 'value'];
      // 'amount' appears at index 1, 'value' at index 2
      expect(findColumnIndex(headers, ['amount', 'value']), 1);
    });
  });

  group('rowToMap', () {
    test('maps headers to values', () {
      final headers = ['id', 'name', 'amount'];
      final row = ['tx-1', 'Groceries', 42.50];
      final result = rowToMap(headers, row);
      expect(result, {
        'id': 'tx-1',
        'name': 'Groceries',
        'amount': 42.50,
      });
    });

    test('handles empty row', () {
      final result = rowToMap([], []);
      expect(result, isEmpty);
    });

    test('maps with matching lengths', () {
      final headers = ['a', 'b'];
      final row = [1, 2];
      expect(rowToMap(headers, row), {'a': 1, 'b': 2});
    });
  });
}
