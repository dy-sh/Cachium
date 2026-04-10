import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../design_system/animations/shimmer_loading.dart';
import '../../../../../design_system/components/feedback/error_placeholder.dart';
import '../../../../transactions/presentation/providers/transactions_provider.dart';
import '../forecast/spending_projection_chart.dart';
import '../forecast/budget_forecast_cards.dart';
import '../forecast/trend_extrapolation_section.dart';
import '../forecast/recurring_timeline.dart';
import '../forecast/what_if_simulator.dart';
import '../forecast/savings_goal_section.dart';
import '../scroll_anchored_list.dart';

class ForecastsTab extends ConsumerWidget {
  const ForecastsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return transactionsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.lg,
        ),
        child: ShimmerList(count: 3, itemHeight: 120),
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: ErrorPlaceholder(
          message: 'Unable to load forecasts',
          onRetry: () => ref.invalidate(transactionsProvider),
        ),
      ),
      data: (_) => _buildContent(),
    );
  }

  Widget _buildContent() {
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
