import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/layout/page_layout.dart';
import '../providers/analytics_filter_provider.dart';
import '../widgets/charts/balance_line_chart.dart';
import '../widgets/charts/category_pie_chart.dart';
import '../widgets/charts/income_expense_chart.dart';
import '../widgets/charts/top_categories_list.dart';
import '../widgets/filters/account_filter_chips.dart';
import '../widgets/filters/date_range_selector.dart';
import '../widgets/filters/type_filter_toggle.dart';
import '../widgets/summary/period_summary_cards.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(analyticsFilterProvider);

    return PageLayout(
      title: 'Analytics',
      body: CustomScrollView(
        slivers: [
          // Date range header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.screenPadding,
                right: AppSpacing.screenPadding,
                bottom: AppSpacing.sm,
              ),
              child: Text(
                _formatDateRange(filter.dateRange.start, filter.dateRange.end),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),

          // Date range presets
          const SliverToBoxAdapter(
            child: DateRangeSelector(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.md),
          ),

          // Account filter
          const SliverToBoxAdapter(
            child: AccountFilterChips(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.md),
          ),

          // Type filter toggle
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Row(
                children: [
                  const TypeFilterToggle(),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.lg),
          ),

          // Summary cards
          const SliverToBoxAdapter(
            child: PeriodSummaryCards(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.lg),
          ),

          // Balance line chart
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: const BalanceLineChart(),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.lg),
          ),

          // Income vs Expense chart
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: const IncomeExpenseChart(),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.lg),
          ),

          // Category pie chart
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: const CategoryPieChart(),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.lg),
          ),

          // Top categories list
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: const TopCategoriesList(limit: 5),
            ),
          ),

          // Bottom padding
          SliverToBoxAdapter(
            child: SizedBox(
              height: AppSpacing.bottomNavHeight + AppSpacing.lg,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final startFormat = DateFormat('MMM d');
    final endFormat = DateFormat('MMM d, yyyy');

    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return endFormat.format(end);
    }

    if (start.year == end.year) {
      return '${startFormat.format(start)} - ${endFormat.format(end)}';
    }

    return '${DateFormat('MMM d, yyyy').format(start)} - ${endFormat.format(end)}';
  }
}
