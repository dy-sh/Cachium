import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/models/csv_import_preview.dart';

class ImportCsvPreviewDialog extends StatelessWidget {
  final CsvImportPreview preview;

  const ImportCsvPreviewDialog({
    super.key,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.income.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              LucideIcons.fileUp,
              size: 20,
              color: AppColors.income,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Import CSV Files',
              style: AppTypography.h4,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File Status Section
            _buildSectionHeader(
              icon: LucideIcons.files,
              title: 'Selected files',
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildFileStatusList(),
            const SizedBox(height: AppSpacing.lg),

            // Metrics Box
            _buildSectionHeader(
              icon: LucideIcons.download,
              title: 'Will be imported',
              color: AppColors.income,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildMetricsBox(),

            // Duplicates Warning
            if (preview.hasDuplicates) ...[
              const SizedBox(height: AppSpacing.lg),
              _buildWarningBox(
                icon: LucideIcons.copy,
                color: AppColors.yellow,
                message: '${preview.duplicateTransactionCount} transaction${preview.duplicateTransactionCount == 1 ? '' : 's'} already exist and will be skipped',
              ),
            ],

            // Invalid References Warning
            if (preview.hasMissingReferences) ...[
              const SizedBox(height: AppSpacing.md),
              _buildWarningBox(
                icon: LucideIcons.link2Off,
                color: AppColors.orange,
                message: _buildMissingReferencesMessage(),
                subMessage: 'You can import them later',
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: AppTypography.button.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            'Import',
            style: AppTypography.button.copyWith(
              color: AppColors.income,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          title,
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFileStatusList() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: preview.fileStatuses.map((status) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  status.isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                  size: 16,
                  color: status.isSelected ? AppColors.income : AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    status.type.displayName,
                    style: AppTypography.bodySmall.copyWith(
                      color: status.isSelected
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
                Text(
                  status.isSelected
                      ? '${status.recordCount} record${status.recordCount == 1 ? '' : 's'}'
                      : 'Not selected',
                  style: AppTypography.bodySmall.copyWith(
                    color: status.isSelected
                        ? AppColors.textSecondary
                        : AppColors.textTertiary,
                    fontWeight: status.isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricsBox() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.income.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.income.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          if (preview.transactionCount > 0)
            _buildMetricRow(
              'Transactions',
              preview.hasDuplicates
                  ? '${preview.newTransactionCount} new'
                  : preview.newTransactionCount.toString(),
            ),
          if (preview.accountCount > 0)
            _buildMetricRow('Accounts', preview.accountCount.toString()),
          if (preview.categoryCount > 0)
            _buildMetricRow('Categories', preview.categoryCount.toString()),
          if (preview.settingsCount > 0)
            _buildMetricRow('Settings', preview.settingsCount.toString()),
          if (preview.totalNewRecords == 0)
            _buildMetricRow('Total', '0 new records'),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBox({
    required IconData icon,
    required Color color,
    required String message,
    String? subMessage,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: AppTypography.bodySmall.copyWith(
                    color: color,
                  ),
                ),
                if (subMessage != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subMessage,
                    style: AppTypography.labelSmall.copyWith(
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildMissingReferencesMessage() {
    final parts = <String>[];
    if (preview.missingCategoryIds.isNotEmpty) {
      final count = preview.missingCategoryIds.length;
      parts.add('$count ${count == 1 ? 'category' : 'categories'}');
    }
    if (preview.missingAccountIds.isNotEmpty) {
      final count = preview.missingAccountIds.length;
      parts.add('$count ${count == 1 ? 'account' : 'accounts'}');
    }
    return '${parts.join(' and ')} referenced by transactions don\'t exist';
  }
}

Future<bool?> showImportCsvPreviewDialog({
  required BuildContext context,
  required CsvImportPreview preview,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => ImportCsvPreviewDialog(preview: preview),
  );
}
