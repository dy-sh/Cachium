import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../settings/data/models/app_settings.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../../data/models/financial_insight.dart';
import '../../providers/financial_insights_provider.dart';

class FinancialInsightsSection extends ConsumerWidget {
  const FinancialInsightsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(financialInsightsProvider);
    final colorIntensity = ref.watch(colorIntensityProvider);

    if (insights.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Insights', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.md),
            ...insights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _InsightRow(
                    insight: insight,
                    colorIntensity: colorIntensity,
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final FinancialInsight insight;
  final ColorIntensity colorIntensity;

  const _InsightRow({
    required this.insight,
    required this.colorIntensity,
  });

  Color get _color {
    switch (insight.sentiment) {
      case InsightSentiment.positive:
        return AppColors.getTransactionColor('income', colorIntensity);
      case InsightSentiment.negative:
        return AppColors.getTransactionColor('expense', colorIntensity);
      case InsightSentiment.neutral:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: AppRadius.xsAll,
          ),
          child: Icon(insight.icon, size: 14, color: color),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            insight.message,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
