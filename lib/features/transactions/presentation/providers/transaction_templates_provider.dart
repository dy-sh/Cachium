import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/exceptions/app_exception.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/providers/optimistic_notifier.dart';
import '../../data/models/transaction_template.dart';

class TransactionTemplatesNotifier
    extends AsyncNotifier<List<TransactionTemplate>>
    with OptimisticAsyncNotifier<TransactionTemplate> {
  @override
  Future<List<TransactionTemplate>> build() async {
    final repository = ref.watch(transactionTemplateRepositoryProvider);
    return repository.getAllTemplates();
  }

  Future<void> addTemplate(TransactionTemplate template) => runOptimistic(
        update: (templates) => [...templates, template],
        action: () => ref
            .read(transactionTemplateRepositoryProvider)
            .createTemplate(template),
        onError: (e) => RepositoryException.create(
            entityType: 'TransactionTemplate', cause: e),
      );

  Future<void> updateTemplate(TransactionTemplate template) => runOptimistic(
        update: (templates) => templates
            .map((t) => t.id == template.id ? template : t)
            .toList(),
        action: () => ref
            .read(transactionTemplateRepositoryProvider)
            .updateTemplate(template),
        onError: (e) => RepositoryException.update(
            entityType: 'TransactionTemplate',
            entityId: template.id,
            cause: e),
      );

  Future<void> deleteTemplate(String id) => runOptimistic(
        update: (templates) => templates.where((t) => t.id != id).toList(),
        action: () =>
            ref.read(transactionTemplateRepositoryProvider).deleteTemplate(id),
        onError: (e) => RepositoryException.delete(
            entityType: 'TransactionTemplate', entityId: id, cause: e),
      );
}

final transactionTemplatesProvider = AsyncNotifierProvider<
    TransactionTemplatesNotifier, List<TransactionTemplate>>(
  TransactionTemplatesNotifier.new,
);
