import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../../data/models/analytics_filter.dart';
import '../../providers/analytics_filter_provider.dart';
import '../../providers/category_breakdown_provider.dart';

class TopCategoriesList extends ConsumerWidget {
  final int limit;

  const TopCategoriesList({
    super.key,
    this.limit = 5,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdowns = ref.watch(topCategoriesProvider(limit));
    final filter = ref.watch(analyticsFilterProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    if (breakdowns.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxAmount = breakdowns.first.amount;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            filter.typeFilter == AnalyticsTypeFilter.income
                ? 'Top Income Sources'
                : 'Top Spending Categories',
            style: AppTypography.labelLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          ...breakdowns.asMap().entries.map((entry) {
            final index = entry.key;
            final breakdown = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < breakdowns.length - 1 ? AppSpacing.md : 0,
              ),
              child: _CategoryRow(
                rank: index + 1,
                icon: breakdown.icon,
                name: breakdown.name,
                amount: breakdown.amount,
                percentage: breakdown.percentage,
                color: breakdown.color,
                maxAmount: maxAmount,
                currencySymbol: currencySymbol,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final int rank;
  final IconData icon;
  final String name;
  final double amount;
  final double percentage;
  final Color color;
  final double maxAmount;
  final String currencySymbol;

  const _CategoryRow({
    required this.rank,
    required this.icon,
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.maxAmount,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final progress = maxAmount > 0 ? amount / maxAmount : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            '$rank',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: AppTypography.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$currencySymbol${_formatAmount(amount)}',
                    style: AppTypography.moneyTiny.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatAmount(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(2);
  }
}
