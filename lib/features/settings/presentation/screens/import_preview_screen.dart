import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/design_system.dart';
import '../../../../navigation/app_router.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/flexible_csv_import_state.dart';
import '../providers/flexible_csv_import_providers.dart';
import '../providers/settings_provider.dart';
import '../widgets/import_summary_card.dart';

/// Screen for previewing import before execution.
class ImportPreviewScreen extends ConsumerWidget {
  const ImportPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(flexibleCsvImportProvider);
    final intensity = ref.watch(colorIntensityProvider);

    // Handle completion
    if (state.step == ImportWizardStep.complete) {
      return _buildCompleteView(context, ref, state);
    }

    if (state.parseResult == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final parseResult = state.parseResult!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: state.isLoading
                            ? null
                            : () {
                                ref.read(flexibleCsvImportProvider.notifier)
                                    .goBackToMapping();
                                context.pop();
                              },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Icon(
                            LucideIcons.chevronLeft,
                            size: 20,
                            color: state.isLoading
                                ? AppColors.textTertiary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Import Preview', style: AppTypography.h3),
                            Text(
                              state.config?.entityType.displayName ?? '',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary card
                    ImportSummaryCard(
                      parseResult: parseResult,
                      entityTypeName: state.config?.entityType.displayName ?? '',
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Invalid rows (if any)
                    if (parseResult.invalidRows.isNotEmpty) ...[
                      Text(
                        'INVALID ROWS',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildInvalidRowsList(parseResult.invalidRows),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // Sample valid rows
                    if (parseResult.validRows.isNotEmpty) ...[
                      Text(
                        'SAMPLE DATA',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildSampleDataList(
                        parseResult.validRows.take(5).toList(),
                        state.config!.entityType,
                        intensity,
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),

            // Bottom action
            _buildBottomAction(context, ref, parseResult, state.isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildInvalidRowsList(List<ParsedImportRow> invalidRows) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.expense.withOpacity(0.3)),
      ),
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(AppSpacing.sm),
        itemCount: invalidRows.take(10).length,
        separatorBuilder: (_, __) => Divider(
          color: AppColors.border,
          height: AppSpacing.md,
        ),
        itemBuilder: (context, index) {
          final row = invalidRows[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Row ${row.rowIndex}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.expense,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ...row.errors.map((error) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.x,
                        size: 12,
                        color: AppColors.expense,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          error,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.expense,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSampleDataList(
    List<ParsedImportRow> sampleRows,
    dynamic entityType,
    ColorIntensity intensity,
  ) {
    return Column(
      children: sampleRows.map((row) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.card,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.income.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Row ${row.rowIndex}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.income,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildParsedValues(row.parsedValues, intensity),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildParsedValues(Map<String, dynamic> values, ColorIntensity intensity) {
    final displayFields = ['name', 'amount', 'type', 'date', 'note', 'balance'];

    final entries = values.entries
        .where((e) => displayFields.contains(e.key) || !values.containsKey('amount'))
        .take(4)
        .toList();

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: entries.map((entry) {
        String valueStr;
        if (entry.value is DateTime) {
          final dt = entry.value as DateTime;
          valueStr = '${dt.month}/${dt.day}/${dt.year}';
        } else if (entry.value is double) {
          valueStr = '\$${entry.value.toStringAsFixed(2)}';
        } else if (entry.value?.toString().startsWith('CREATE:') == true) {
          valueStr = entry.value.toString().substring(7) + ' (new)';
        } else {
          valueStr = entry.value?.toString() ?? 'null';
        }

        if (valueStr.length > 30) {
          valueStr = '${valueStr.substring(0, 27)}...';
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${entry.key}: ',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            Text(
              valueStr,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBottomAction(
    BuildContext context,
    WidgetRef ref,
    ParseResult parseResult,
    bool isLoading,
  ) {
    final canImport = parseResult.validCount > 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (parseResult.invalidCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  '${parseResult.invalidCount} rows will be skipped due to errors',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.yellow,
                  ),
                ),
              ),
            PrimaryButton(
              label: 'Import ${parseResult.validCount} ${parseResult.validCount == 1 ? 'Row' : 'Rows'}',
              onPressed: canImport && !isLoading
                  ? () async {
                      await ref.read(flexibleCsvImportProvider.notifier)
                          .executeImport();
                    }
                  : null,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteView(
    BuildContext context,
    WidgetRef ref,
    FlexibleCsvImportState state,
  ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const SizedBox(width: 36 + AppSpacing.md),
                      Text('Import Complete', style: AppTypography.h3),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    if (state.importResult != null)
                      ImportResultCard(result: state.importResult!),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),

            // Bottom action
            Container(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: SafeArea(
                top: false,
                child: PrimaryButton(
                  label: 'Done',
                  onPressed: () {
                    ref.read(flexibleCsvImportProvider.notifier).reset();
                    // Go back to main settings (preserves navigation hierarchy)
                    context.go(AppRoutes.settings);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
