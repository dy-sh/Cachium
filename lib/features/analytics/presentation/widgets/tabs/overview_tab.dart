import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../summary/period_summary_cards.dart';
import '../charts/savings_gauge.dart';
import '../health/financial_health_section.dart';
import '../insights/financial_insights_section.dart';
import '../trends/spending_trends_section.dart';
import '../charts/balance_line_chart.dart';
import '../charts/net_worth_chart.dart';
import '../charts/holding_liability_pie_chart.dart';
import '../charts/income_expense_chart.dart';
import '../charts/waterfall_chart.dart';
import '../charts/category_pie_chart.dart';
import '../charts/treemap_chart.dart';
import '../charts/top_categories_list.dart';
import '../merchants/merchant_analysis_section.dart';
import '../flow/sankey_flow_section.dart';
import '../flow/account_flow_section.dart';
import '../calendar/cash_flow_calendar.dart';
import '../charts/spending_heatmap.dart';
import '../budgets/budget_progress_section.dart';
import '../currency/conversion_gain_loss_card.dart';
import '../scroll_anchored_list.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScrollAnchoredList(
      sections: [
        PeriodSummaryCards(),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: ConversionGainLossCard(),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: SavingsGauge(),
        ),
        FinancialHealthSection(),
        FinancialInsightsSection(),
        SpendingTrendsSection(),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: BalanceLineChart(),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: NetWorthChart(),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: HoldingLiabilityPieChart(),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: IncomeExpenseChart(),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: WaterfallChart(),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: CategoryPieChart(),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: TreemapChart(),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: TopCategoriesList(limit: 5),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: MerchantAnalysisSection(),
        ),
        SankeyFlowSection(),
        AccountFlowSection(),
        CashFlowCalendar(),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: SpendingHeatmap(),
        ),
        BudgetProgressSection(),
      ],
    );
  }
}
