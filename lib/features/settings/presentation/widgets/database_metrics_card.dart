import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../data/models/database_metrics.dart';
import '../providers/database_providers.dart';

class DatabaseMetricsCard extends ConsumerWidget {
  const DatabaseMetricsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(databaseMetricsProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: metricsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            'Failed to load metrics',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.expense,
            ),
          ),
        ),
        data: (metrics) => _buildMetricsContent(metrics),
      ),
    );
  }

  Widget _buildMetricsContent(DatabaseMetrics metrics) {
    return Column(
      children: [
        _MetricRow(
          label: 'Transactions',
          value: metrics.transactionCount.toString(),
        ),
        _buildDivider(),
        _MetricRow(
          label: 'Categories',
          value: metrics.categoryCount.toString(),
        ),
        _buildDivider(),
        _MetricRow(
          label: 'Accounts',
          value: metrics.accountCount.toString(),
        ),
        if (metrics.oldestRecord != null) ...[
          _buildDivider(),
          _MetricRow(
            label: 'Created',
            value: DateFormatter.formatFull(metrics.oldestRecord!),
          ),
        ],
        if (metrics.newestRecord != null) ...[
          _buildDivider(),
          _MetricRow(
            label: 'Last Updated',
            value: DateFormatter.formatFull(metrics.newestRecord!),
          ),
        ],
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.border,
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium,
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
