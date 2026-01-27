import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/layout/page_layout.dart';
import '../providers/analytics_filter_provider.dart';
import '../widgets/budgets/budget_progress_section.dart';
import '../widgets/calendar/cash_flow_calendar.dart';
import '../widgets/charts/balance_line_chart.dart';
import '../widgets/charts/category_pie_chart.dart';
import '../widgets/charts/income_expense_chart.dart';
import '../widgets/charts/top_categories_list.dart';
import '../widgets/filters/account_filter_chips.dart';
import '../widgets/filters/category_filter_popup.dart';
import '../widgets/filters/date_range_selector.dart';
import '../widgets/filters/type_filter_toggle.dart';
import '../widgets/insights/financial_insights_section.dart';
import '../widgets/summary/period_summary_cards.dart';
import '../widgets/comparison/year_over_year_section.dart';
import '../widgets/comparison/period_comparison_section.dart';
import '../widgets/comparison/category_comparison_section.dart';
import '../widgets/comparison/account_comparison_section.dart';
import '../widgets/flow/account_flow_section.dart';
import '../widgets/flow/sankey_flow_section.dart';
import '../widgets/trends/spending_trends_section.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(analyticsFilterProvider);

    return PageLayout(
      title: 'Analytics',
      body: CustomScrollView(
        slivers: [
          // 1. Date range header
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

          // 2. Date range presets
          const SliverToBoxAdapter(
            child: DateRangeSelector(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.md),
          ),

          // 3. Account filter
          const SliverToBoxAdapter(
            child: AccountFilterChips(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.md),
          ),

          // 4. Category filter button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Row(
                children: [
                  const CategoryFilterPopup(),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.md),
          ),

          // 5. Type filter toggle
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

          // 6. Financial Insights
          const SliverToBoxAdapter(
            child: FinancialInsightsSection(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.lg),
          ),

          // 7. Summary cards
          const SliverToBoxAdapter(
            child: PeriodSummaryCards(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.lg),
          ),

          // 8. Spending Trends
          const SliverToBoxAdapter(
            child: SpendingTrendsSection(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.lg),
          ),

          // 9. Balance line chart
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

          // 10. Income vs Expense chart
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

          // 10b. Year-over-Year Comparison
          const SliverToBoxAdapter(
            child: YearOverYearSection(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.lg),
          ),

          // 10c. Period Comparison
          const SliverToBoxAdapter(
            child: PeriodComparisonSection(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.lg),
          ),

          // 10d. Category Comparison
          const SliverToBoxAdapter(
            child: CategoryComparisonSection(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.lg),
          ),

          // 10e. Account Comparison
          const SliverToBoxAdapter(
            child: AccountComparisonSection(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.lg),
          ),

          // 10f. Sankey Flow
          const SliverToBoxAdapter(
            child: SankeyFlowSection(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.lg),
          ),

          // 11. Cash Flow Calendar
          const SliverToBoxAdapter(
            child: CashFlowCalendar(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.lg),
          ),

          // 12. Budget Progress
          const SliverToBoxAdapter(
            child: BudgetProgressSection(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.lg),
          ),

          // 13. Category pie chart
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

          // 13b. Account Flow
          const SliverToBoxAdapter(
            child: AccountFlowSection(),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.lg),
          ),

          // 14. Top categories list
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
