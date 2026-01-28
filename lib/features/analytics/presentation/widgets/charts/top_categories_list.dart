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
import '../../providers/chart_highlight_provider.dart';

enum _SortMode { byAmount, byCount }

class TopCategoriesList extends ConsumerStatefulWidget {
  final int limit;

  const TopCategoriesList({
    super.key,
    this.limit = 5,
  });

  @override
  ConsumerState<TopCategoriesList> createState() => _TopCategoriesListState();
}

class _TopCategoriesListState extends ConsumerState<TopCategoriesList> {
  _SortMode _sortMode = _SortMode.byAmount;

  @override
  Widget build(BuildContext context) {
    var breakdowns = ref.watch(topCategoriesProvider(widget.limit));
    final filter = ref.watch(analyticsFilterProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final highlightedCategory = ref.watch(chartHighlightProvider);

    if (breakdowns.isEmpty) {
      return const SizedBox.shrink();
    }

    // Apply sort
    if (_sortMode == _SortMode.byCount) {
      breakdowns = List.from(breakdowns)
        ..sort((a, b) => b.transactionCount.compareTo(a.transactionCount));
    }

    final maxAmount = breakdowns.fold(0.0, (max, b) => b.amount > max ? b.amount : max);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                filter.typeFilter == AnalyticsTypeFilter.income
                    ? 'Top Income Sources'
                    : 'Top Spending Categories',
                style: AppTypography.labelLarge,
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _sortMode = _sortMode == _SortMode.byAmount
                        ? _SortMode.byCount
                        : _SortMode.byAmount;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _sortMode == _SortMode.byAmount ? 'By amount' : 'By count',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...breakdowns.asMap().entries.map((entry) {
            final index = entry.key;
            final breakdown = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < breakdowns.length - 1 ? AppSpacing.md : 0,
              ),
              child: GestureDetector(
                onTap: () {
                  ref.read(analyticsFilterProvider.notifier).setCategories({breakdown.categoryId});
                  final notifier = ref.read(chartHighlightProvider.notifier);
                  notifier.state = notifier.state == breakdown.categoryId
                      ? null
                      : breakdown.categoryId;
                },
                child: _CategoryRow(
                  rank: index + 1,
                  icon: breakdown.icon,
                  name: breakdown.name,
                  amount: breakdown.amount,
                  percentage: breakdown.percentage,
                  color: breakdown.color,
                  maxAmount: maxAmount,
                  currencySymbol: currencySymbol,
                  transactionCount: breakdown.transactionCount,
                  sortMode: _sortMode,
                  isHighlighted: highlightedCategory == null || highlightedCategory == breakdown.categoryId,
                ),
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
  final int transactionCount;
  final _SortMode sortMode;
  final bool isHighlighted;

  const _CategoryRow({
    required this.rank,
    required this.icon,
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.maxAmount,
    required this.currencySymbol,
    required this.transactionCount,
    required this.sortMode,
    this.isHighlighted = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = maxAmount > 0 ? amount / maxAmount : 0.0;

    return Opacity(
      opacity: isHighlighted ? 1.0 : 0.3,
      child: Row(
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
            color: color.withValues(alpha: 0.15),
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
                    sortMode == _SortMode.byCount
                        ? '$transactionCount txns'
                        : '$currencySymbol${_formatAmount(amount)}',
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
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      builder: (context, value, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: value,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 4,
                          ),
                        );
                      },
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
    ),
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
