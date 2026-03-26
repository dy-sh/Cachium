import 'package:cachium/core/exceptions/app_exception.dart';
import 'package:cachium/core/providers/optimistic_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestNotifier extends AsyncNotifier<List<String>>
    with OptimisticAsyncNotifier<String> {
  @override
  Future<List<String>> build() async => ['a', 'b', 'c'];

  Future<void> addItem(String item, {bool shouldFail = false}) =>
      runOptimistic(
        update: (items) => [...items, item],
        action: () async {
          if (shouldFail) throw Exception('repo error');
        },
        onError: (e) =>
            RepositoryException.create(entityType: 'Test', cause: e),
      );

  Future<String> addAndReturn(String item) => runOptimistic<String>(
        update: (items) => [...items, item],
        action: () async => 'created-$item',
        onError: (e) =>
            RepositoryException.create(entityType: 'Test', cause: e),
      );

  Future<void> removeItem(String item, {bool shouldFail = false}) =>
      runOptimistic(
        update: (items) => items.where((i) => i != item).toList(),
        action: () async {
          if (shouldFail) throw Exception('repo error');
        },
        onError: (e) =>
            RepositoryException.delete(entityType: 'Test', cause: e),
      );
}

final _testProvider =
    AsyncNotifierProvider<_TestNotifier, List<String>>(_TestNotifier.new);

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('optimistic add updates state immediately', () async {
    // Wait for initial build
    await container.read(_testProvider.future);

    await container.read(_testProvider.notifier).addItem('d');
    final items = container.read(_testProvider).valueOrNull;
    expect(items, equals(['a', 'b', 'c', 'd']));
  });

  test('optimistic add rolls back on failure', () async {
    await container.read(_testProvider.future);

    await expectLater(
      container.read(_testProvider.notifier).addItem('d', shouldFail: true),
      throwsA(isA<RepositoryException>()),
    );

    // State should be rolled back
    final items = container.read(_testProvider).valueOrNull;
    expect(items, equals(['a', 'b', 'c']));
  });

  test('runOptimistic returns action result', () async {
    await container.read(_testProvider.future);

    final result =
        await container.read(_testProvider.notifier).addAndReturn('x');
    expect(result, equals('created-x'));
  });

  test('optimistic remove updates state', () async {
    await container.read(_testProvider.future);

    await container.read(_testProvider.notifier).removeItem('b');
    final items = container.read(_testProvider).valueOrNull;
    expect(items, equals(['a', 'c']));
  });

  test('optimistic remove rolls back on failure', () async {
    await container.read(_testProvider.future);

    await expectLater(
      container.read(_testProvider.notifier).removeItem('b', shouldFail: true),
      throwsA(isA<RepositoryException>()),
    );

    final items = container.read(_testProvider).valueOrNull;
    expect(items, equals(['a', 'b', 'c']));
  });

  test('AppException passes through without wrapping', () async {
    await container.read(_testProvider.future);

    final notifier = container.read(_testProvider.notifier);
    await expectLater(
      notifier.runOptimistic(
        update: (items) => items,
        action: () async {
          throw const ValidationException(message: 'bad input');
        },
        onError: (e) =>
            RepositoryException.create(entityType: 'Test', cause: e),
      ),
      throwsA(
        isA<ValidationException>()
            .having((e) => e.message, 'message', 'bad input'),
      ),
    );
  });
}
