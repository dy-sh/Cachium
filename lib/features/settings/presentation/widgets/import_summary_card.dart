import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/flexible_csv_import_state.dart';
import '../providers/settings_provider.dart';

/// Card showing import preview summary.
class ImportSummaryCard extends ConsumerWidget {
  final ParseResult parseResult;
  final String entityTypeName;

  const ImportSummaryCard({
    super.key,
    required this.parseResult,
    required this.entityTypeName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intensity = ref.watch(colorIntensityProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: parseResult.hasErrors
                        ? AppColors.yellow.withValues(alpha: 0.15)
                        : AppColors.income.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    parseResult.hasErrors
                        ? LucideIcons.alertTriangle
                        : LucideIcons.checkCircle,
                    size: 20,
                    color: parseResult.hasErrors
                        ? AppColors.yellow
                        : AppColors.income,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Preview',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${parseResult.totalRows} total rows',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(color: AppColors.border, height: 1),

          // Stats
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _buildStatRow(
                  icon: LucideIcons.checkCircle,
                  iconColor: AppColors.income,
                  label: 'Valid rows',
                  value: parseResult.validCount.toString(),
                  valueColor: AppColors.income,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildStatRow(
                  icon: LucideIcons.xCircle,
                  iconColor: AppColors.expense,
                  label: 'Invalid rows',
                  value: parseResult.invalidCount.toString(),
                  valueColor: parseResult.invalidCount > 0
                      ? AppColors.expense
                      : AppColors.textTertiary,
                ),
              ],
            ),
          ),

          // Entities to create
          if (parseResult.categoriesToCreate.isNotEmpty ||
              parseResult.accountsToCreate.isNotEmpty) ...[
            Divider(color: AppColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.plusCircle,
                        size: 16,
                        color: AppColors.cyan,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Will be created',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.cyan,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (parseResult.categoriesToCreate.isNotEmpty) ...[
                    _buildCreateList(
                      'Categories',
                      parseResult.categoriesToCreate,
                      intensity,
                    ),
                  ],
                  if (parseResult.accountsToCreate.isNotEmpty) ...[
                    if (parseResult.categoriesToCreate.isNotEmpty)
                      const SizedBox(height: AppSpacing.sm),
                    _buildCreateList(
                      'Accounts',
                      parseResult.accountsToCreate,
                      intensity,
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Global errors
          if (parseResult.globalErrors.isNotEmpty) ...[
            Divider(color: AppColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.alertCircle,
                        size: 16,
                        color: AppColors.expense,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Errors',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...parseResult.globalErrors.take(5).map((error) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        error,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.expense,
                        ),
                      ),
                    );
                  }),
                  if (parseResult.globalErrors.length > 5)
                    Text(
                      '... and ${parseResult.globalErrors.length - 5} more',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateList(
    String title,
    List<String> items,
    ColorIntensity intensity,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${items.length})',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items.take(10).map((item) {
            // Parse display name from format: "ID:uuid:name" or "NAME:name"
            String displayName = item;
            if (item.startsWith('ID:')) {
              final parts = item.substring(3).split(':');
              displayName = parts.length > 1 ? parts.sublist(1).join(':') : parts[0];
            } else if (item.startsWith('NAME:')) {
              displayName = item.substring(5);
            }

            return Container(
              constraints: const BoxConstraints(maxWidth: 150),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.getAccentColor(0, intensity).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.getAccentColor(0, intensity).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.plus,
                    size: 12,
                    color: AppColors.getAccentColor(0, intensity),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      displayName,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.getAccentColor(0, intensity),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        if (items.length > 10)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '... and ${items.length - 10} more',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

/// Card showing final import results.
class ImportResultCard extends ConsumerWidget {
  final FlexibleImportResult result;

  const ImportResultCard({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasErrors = result.hasErrors;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: hasErrors
                        ? AppColors.yellow.withValues(alpha: 0.15)
                        : AppColors.income.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasErrors
                        ? LucideIcons.alertTriangle
                        : LucideIcons.checkCircle,
                    size: 24,
                    color: hasErrors ? AppColors.yellow : AppColors.income,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasErrors ? 'Import Complete (with issues)' : 'Import Complete',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${result.imported} records imported',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.income,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(color: AppColors.border, height: 1),

          // Stats
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _buildStatRow(
                  icon: LucideIcons.checkCircle,
                  iconColor: AppColors.income,
                  label: 'Imported',
                  value: result.imported.toString(),
                ),
                if (result.skipped > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _buildStatRow(
                    icon: LucideIcons.skipForward,
                    iconColor: AppColors.textTertiary,
                    label: 'Skipped',
                    value: result.skipped.toString(),
                  ),
                ],
                if (result.failed > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _buildStatRow(
                    icon: LucideIcons.xCircle,
                    iconColor: AppColors.expense,
                    label: 'Failed',
                    value: result.failed.toString(),
                  ),
                ],
                if (result.categoriesCreated > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _buildStatRow(
                    icon: LucideIcons.tag,
                    iconColor: AppColors.cyan,
                    label: 'Categories created',
                    value: result.categoriesCreated.toString(),
                  ),
                ],
                if (result.accountsCreated > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _buildStatRow(
                    icon: LucideIcons.wallet,
                    iconColor: AppColors.cyan,
                    label: 'Accounts created',
                    value: result.accountsCreated.toString(),
                  ),
                ],
              ],
            ),
          ),

          // Errors
          if (result.errors.isNotEmpty) ...[
            Divider(color: AppColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.alertCircle,
                        size: 16,
                        color: AppColors.expense,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Errors (${result.errors.length})',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: result.errors.map((error) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              error,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.expense,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium,
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
