import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/database/services/flexible_csv_import_service.dart';
import '../../../../../core/providers/database_providers.dart';
import '../../../data/models/field_mapping_options.dart';
import '../../../data/models/flexible_csv_import_config.dart';
import '../../../data/models/flexible_csv_import_state.dart';
import '../../../data/models/import_preset.dart';
import 'csv_import_notifier.dart';

final flexibleCsvImportServiceProvider = Provider<FlexibleCsvImportService>((ref) {
  return FlexibleCsvImportService(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    accountRepository: ref.watch(accountRepositoryProvider),
    categoryRepository: ref.watch(categoryRepositoryProvider),
  );
});

final fieldDefinitionsProvider = Provider.family<List<AppFieldDefinition>, ImportEntityType>((ref, type) {
  return ImportFieldDefinitions.getFieldsForType(type);
});

final presetsForTypeProvider = Provider.family<List<ImportPreset>, ImportEntityType>((ref, type) {
  return BuiltInPresets.getPresetsForType(type);
});

final flexibleCsvImportProvider =
    NotifierProvider.autoDispose<FlexibleCsvImportNotifier, FlexibleCsvImportState>(
  FlexibleCsvImportNotifier.new,
);

final canProceedToPreviewProvider = Provider<bool>((ref) {
  final state = ref.watch(flexibleCsvImportProvider);
  return state.canProceedToPreview;
});

final unmappedCsvColumnsProvider = Provider<List<String>>((ref) {
  final state = ref.watch(flexibleCsvImportProvider);
  return state.unmappedCsvColumns;
});

final selectedFieldKeyProvider = Provider<String?>((ref) {
  final state = ref.watch(flexibleCsvImportProvider);
  return state.selectedFieldKey;
});

final connectionBadgesProvider = Provider<Map<String, int>>((ref) {
  final state = ref.watch(flexibleCsvImportProvider);
  return state.connectionBadges;
});

final expandedForeignKeyProvider = Provider<String?>((ref) {
  final state = ref.watch(flexibleCsvImportProvider);
  return state.expandedForeignKey;
});

final categoryConfigProvider = Provider<ForeignKeyConfig>((ref) {
  final state = ref.watch(flexibleCsvImportProvider);
  return state.categoryConfig;
});

final accountConfigProvider = Provider<ForeignKeyConfig>((ref) {
  final state = ref.watch(flexibleCsvImportProvider);
  return state.accountConfig;
});

final amountConfigProvider = Provider<AmountConfig>((ref) {
  final state = ref.watch(flexibleCsvImportProvider);
  return state.amountConfig;
});

final mappingProgressProvider = Provider<(int mapped, int total)>((ref) {
  final state = ref.watch(flexibleCsvImportProvider);
  return (state.mappedFieldCount, state.totalFieldCount);
});

final currentCsvFileNameProvider = Provider<String?>((ref) {
  final state = ref.watch(flexibleCsvImportProvider);
  if (state.config == null) return null;
  return state.config!.filePath.split('/').last;
});
