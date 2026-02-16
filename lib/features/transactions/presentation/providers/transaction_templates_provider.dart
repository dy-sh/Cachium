import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/database_providers.dart';
import '../../data/models/transaction_template.dart';

class TransactionTemplatesNotifier
    extends AsyncNotifier<List<TransactionTemplate>> {
  @override
  Future<List<TransactionTemplate>> build() async {
    final repository = ref.watch(transactionTemplateRepositoryProvider);
    return repository.getAllTemplates();
  }

  Future<void> addTemplate(TransactionTemplate template) async {
    final repository = ref.read(transactionTemplateRepositoryProvider);
    await repository.createTemplate(template);
    ref.invalidateSelf();
  }

  Future<void> updateTemplate(TransactionTemplate template) async {
    final repository = ref.read(transactionTemplateRepositoryProvider);
    await repository.updateTemplate(template);
    ref.invalidateSelf();
  }

  Future<void> deleteTemplate(String id) async {
    final repository = ref.read(transactionTemplateRepositoryProvider);
    await repository.deleteTemplate(id);
    ref.invalidateSelf();
  }
}

final transactionTemplatesProvider = AsyncNotifierProvider<
    TransactionTemplatesNotifier, List<TransactionTemplate>>(
  TransactionTemplatesNotifier.new,
);
