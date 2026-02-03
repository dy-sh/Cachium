import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../providers/recurring_transactions_provider.dart';
import 'subscription_card.dart';
import 'subscription_timeline.dart';

class SubscriptionTrackerSection extends ConsumerWidget {
  const SubscriptionTrackerSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(recurringTransactionsProvider);
    final accentColor = ref.watch(accentColorProvider);

    if (summary.subscriptions.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with totals
          Container(
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
                      LucideIcons.repeat,
                      size: 18,
                      color: accentColor,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Subscriptions',
                      style: AppTypography.labelLarge,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: AppRadius.chip,
                      ),
                      child: Text(
                        '${summary.count} detected',
                        style: AppTypography.labelSmall.copyWith(
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Monthly',
                        value: CurrencyFormatter.format(summary.totalMonthly),
                        color: AppColors.orange,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Yearly',
                        value: CurrencyFormatter.format(summary.totalYearly),
                        color: AppColors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Timeline
          const SubscriptionTimeline(),
          const SizedBox(height: AppSpacing.md),

          // Subscription list
          Text(
            'All Subscriptions',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...summary.subscriptions.take(10).map((sub) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: SubscriptionCard(subscription: sub),
              )),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(
              LucideIcons.repeat,
              size: 32,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No Subscriptions Detected',
              style: AppTypography.labelLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Add more transactions to detect recurring payments',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.moneySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
