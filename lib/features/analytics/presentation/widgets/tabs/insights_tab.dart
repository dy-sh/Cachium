import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../providers/anomaly_detection_provider.dart';
import '../../providers/prediction_alerts_provider.dart';
import '../../providers/streaks_provider.dart';
import '../../providers/financial_insights_provider.dart';
import '../insights/anomaly_alert_card.dart';
import '../insights/prediction_alert_card.dart';
import '../insights/financial_insights_section.dart';
import '../achievements/streak_card.dart';
import '../subscriptions/subscription_tracker_section.dart';
import '../scroll_anchored_list.dart';

class InsightsTab extends ConsumerWidget {
  const InsightsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anomalies = ref.watch(anomalyDetectionProvider);
    final predictions = ref.watch(predictionAlertsProvider);
    final streaks = ref.watch(streaksProvider);
    final insights = ref.watch(financialInsightsProvider);

    return ScrollAnchoredList(
      sections: [
        // Streaks
        if (streaks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: _SectionCard(
              title: 'Streaks',
              icon: LucideIcons.flame,
              iconColor: AppColors.orange,
              child: Column(
                children: streaks.map((streak) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: StreakCard(streak: streak),
                )).toList(),
              ),
            ),
          ),

        // Anomaly Alerts
        if (anomalies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: _SectionCard(
              title: 'Anomaly Alerts',
              icon: LucideIcons.alertTriangle,
              iconColor: AppColors.orange,
              child: Column(
                children: anomalies.take(5).map((anomaly) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AnomalyAlertCard(anomaly: anomaly),
                )).toList(),
              ),
            ),
          ),

        // Predictions
        if (predictions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: _SectionCard(
              title: 'Predictions',
              icon: LucideIcons.sparkles,
              iconColor: AppColors.purple,
              child: Column(
                children: predictions.map((prediction) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: PredictionAlertCard(alert: prediction),
                )).toList(),
              ),
            ),
          ),

        // Smart Insights
        if (insights.isNotEmpty)
          const FinancialInsightsSection(),

        // Subscriptions
        const SubscriptionTrackerSection(),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
            children: [
              Icon(
                icon,
                size: 18,
                color: iconColor,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: AppTypography.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
