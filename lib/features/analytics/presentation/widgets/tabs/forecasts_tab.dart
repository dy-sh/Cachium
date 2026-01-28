import 'package:flutter/material.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../forecast/spending_projection_chart.dart';
import '../forecast/budget_forecast_cards.dart';
import '../forecast/trend_extrapolation_section.dart';
import '../forecast/recurring_timeline.dart';
import '../forecast/what_if_simulator.dart';
import '../forecast/savings_goal_section.dart';
import '../scroll_anchored_list.dart';

class ForecastsTab extends StatelessWidget {
  const ForecastsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ScrollAnchoredList(
      sections: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: const SpendingProjectionChart(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: const BudgetForecastCards(),
        ),
        const TrendExtrapolationSection(),
        const RecurringTimeline(),
        const WhatIfSimulator(),
        const SavingsGoalSection(),
      ],
    );
  }
}
