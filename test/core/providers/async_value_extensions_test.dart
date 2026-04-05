import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cachium/core/providers/async_value_extensions.dart';

void main() {
  group('AsyncValueListExtension.valueOrEmpty', () {
    test('returns value when data is available', () {
      const AsyncValue<List<int>> value = AsyncData([1, 2, 3]);
      expect(value.valueOrEmpty, [1, 2, 3]);
    });

    test('returns empty list when loading', () {
      const AsyncValue<List<int>> value = AsyncLoading();
      expect(value.valueOrEmpty, isEmpty);
    });

    test('returns empty list when error', () {
      final AsyncValue<List<int>> value = AsyncError(
        Exception('fail'),
        StackTrace.empty,
      );
      expect(value.valueOrEmpty, isEmpty);
    });

    test('returns empty list for empty data', () {
      const AsyncValue<List<String>> value = AsyncData([]);
      expect(value.valueOrEmpty, isEmpty);
    });

    test('works with various types', () {
      const AsyncValue<List<String>> value = AsyncData(['a', 'b']);
      expect(value.valueOrEmpty, ['a', 'b']);
    });
  });
}
