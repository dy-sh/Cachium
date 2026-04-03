/// Processes a batch of async tasks with bounded concurrency.
///
/// Instead of launching all tasks simultaneously via `Future.wait()`,
/// this processes them in chunks to limit memory pressure and CPU usage
/// on devices with large datasets.
Future<List<T>> decryptBatch<T>(
  Iterable<Future<T> Function()> tasks, {
  int concurrency = 50,
}) async {
  final taskList = tasks.toList();
  final results = <T>[];

  for (int i = 0; i < taskList.length; i += concurrency) {
    final end = (i + concurrency).clamp(0, taskList.length);
    final chunk = taskList.sublist(i, end);
    final chunkResults = await Future.wait(chunk.map((task) => task()));
    results.addAll(chunkResults);
  }

  return results;
}
