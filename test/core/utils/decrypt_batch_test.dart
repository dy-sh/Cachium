import 'package:flutter_test/flutter_test.dart';
import 'package:cachium/core/utils/decrypt_batch.dart';

void main() {
  group('decryptBatch', () {
    test('returns empty list for empty input', () async {
      final result = await decryptBatch<int>([]);
      expect(result, isEmpty);
    });

    test('processes single task', () async {
      final result = await decryptBatch<int>([() async => 42]);
      expect(result, [42]);
    });

    test('processes multiple tasks within one chunk', () async {
      final result = await decryptBatch<int>(
        [() async => 1, () async => 2, () async => 3],
        concurrency: 10,
      );
      expect(result, [1, 2, 3]);
    });

    test('processes multiple chunks', () async {
      final result = await decryptBatch<int>(
        List.generate(5, (i) => () async => i),
        concurrency: 2,
      );
      expect(result, [0, 1, 2, 3, 4]);
    });

    test('preserves order', () async {
      final result = await decryptBatch<int>(
        [() async => 3, () async => 1, () async => 2],
        concurrency: 1,
      );
      expect(result, [3, 1, 2]);
    });

    test('concurrency of 1 processes sequentially', () async {
      final order = <int>[];
      final result = await decryptBatch<int>(
        List.generate(4, (i) => () async {
          order.add(i);
          return i * 10;
        }),
        concurrency: 1,
      );
      expect(result, [0, 10, 20, 30]);
      expect(order, [0, 1, 2, 3]);
    });

    test('handles tasks that return different types', () async {
      final result = await decryptBatch<String>(
        [() async => 'hello', () async => 'world'],
      );
      expect(result, ['hello', 'world']);
    });

    test('exact chunk boundary', () async {
      // 4 tasks with concurrency 2 = exactly 2 chunks
      final result = await decryptBatch<int>(
        List.generate(4, (i) => () async => i),
        concurrency: 2,
      );
      expect(result, [0, 1, 2, 3]);
    });
  });
}
