import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../providers/asset_analytics_providers.dart';

class AssetStatsCards extends ConsumerWidget {
  final String assetId;

  const AssetStatsCards({super.key, required this.assetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(assetStatsProvider(assetId));

    final timeOwnedText = _formatDuration(stats.timeOwned);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Monthly Avg',
                value: CurrencyFormatter.format(stats.monthlyAverage),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                label: 'Per Day',
                value: CurrencyFormatter.format(stats.costPerDay),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Time Owned',
                value: timeOwnedText,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                label: 'Transactions',
                value: stats.totalTransactions.toString(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    if (days < 30) return '${days}d';
    final months = days ~/ 30;
    if (months < 12) return '${months}mo';
    final years = months ~/ 12;
    final remainingMonths = months % 12;
    if (remainingMonths == 0) return '${years}y';
    return '${years}y ${remainingMonths}mo';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.labelMedium,
          ),
        ],
      ),
    );
  }
}
