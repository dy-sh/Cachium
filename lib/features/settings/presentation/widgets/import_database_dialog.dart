import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/models/database_metrics.dart';

class ImportDatabaseDialog extends StatelessWidget {
  final DatabaseMetrics currentMetrics;
  final DatabaseMetrics importMetrics;
  final String fileName;

  const ImportDatabaseDialog({
    super.key,
    required this.currentMetrics,
    required this.importMetrics,
    required this.fileName,
  });

  bool get _hasCurrentData => !currentMetrics.isEmpty;

  @override
  Widget build(BuildContext context) {
    final accentColor = _hasCurrentData ? AppColors.expense : AppColors.income;

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
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _hasCurrentData ? LucideIcons.alertTriangle : LucideIcons.databaseBackup,
              size: 20,
              color: accentColor,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              _hasCurrentData ? 'Replace Database?' : 'Import Database?',
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
            if (_hasCurrentData) ...[
              Text(
                'All current data will be permanently deleted and replaced with the imported database.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Current database section
              _buildSectionHeader(
                icon: LucideIcons.trash2,
                title: 'Will be deleted',
                color: AppColors.expense,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildMetricsBox(currentMetrics, isCurrentDb: true),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Import database section
            _buildSectionHeader(
              icon: LucideIcons.download,
              title: _hasCurrentData ? 'Will be imported' : 'Database to import',
              color: AppColors.income,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              fileName,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildMetricsBox(importMetrics, isCurrentDb: false),
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
            _hasCurrentData ? 'Replace' : 'Import',
            style: AppTypography.button.copyWith(
              color: accentColor,
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

  Widget _buildMetricsBox(DatabaseMetrics metrics, {required bool isCurrentDb}) {
    final bgColor = isCurrentDb
        ? AppColors.expense.withValues(alpha: 0.05)
        : AppColors.income.withValues(alpha: 0.05);
    final borderColor = isCurrentDb
        ? AppColors.expense.withValues(alpha: 0.2)
        : AppColors.income.withValues(alpha: 0.2);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _buildMetricRow('Transactions', metrics.transactionCount.toString()),
          _buildMetricRow('Categories', metrics.categoryCount.toString()),
          _buildMetricRow('Accounts', metrics.accountCount.toString()),
          if (metrics.oldestRecord != null)
            _buildMetricRow(
              'Created',
              DateFormatter.formatShort(metrics.oldestRecord!),
            ),
          if (metrics.newestRecord != null)
            _buildMetricRow(
              'Last updated',
              DateFormatter.formatShort(metrics.newestRecord!),
            ),
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
}

Future<bool?> showImportDatabaseDialog({
  required BuildContext context,
  required DatabaseMetrics currentMetrics,
  required DatabaseMetrics importMetrics,
  required String fileName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => ImportDatabaseDialog(
      currentMetrics: currentMetrics,
      importMetrics: importMetrics,
      fileName: fileName,
    ),
  );
}
