import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../summary/period_summary_cards.dart';
import '../insights/financial_insights_section.dart';
import '../trends/spending_trends_section.dart';
import '../charts/balance_line_chart.dart';
import '../charts/income_expense_chart.dart';
import '../charts/category_pie_chart.dart';
import '../charts/top_categories_list.dart';
import '../flow/sankey_flow_section.dart';
import '../flow/account_flow_section.dart';
import '../calendar/cash_flow_calendar.dart';
import '../budgets/budget_progress_section.dart';
import '../scroll_anchored_list.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ScrollAnchoredList(
      sections: [
        const PeriodSummaryCards(),
        const FinancialInsightsSection(),
        const SpendingTrendsSection(),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: const BalanceLineChart(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: const IncomeExpenseChart(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: const CategoryPieChart(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: const TopCategoriesList(limit: 5),
        ),
        const SankeyFlowSection(),
        const AccountFlowSection(),
        const CashFlowCalendar(),
        const BudgetProgressSection(),
      ],
    );
  }
}
