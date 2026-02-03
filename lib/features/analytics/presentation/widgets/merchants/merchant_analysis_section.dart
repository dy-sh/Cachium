import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../providers/merchant_analysis_provider.dart';
import 'top_merchants_chart.dart';

class MerchantAnalysisSection extends ConsumerWidget {
  const MerchantAnalysisSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(merchantAnalysisProvider);
    final accentColor = ref.watch(accentColorProvider);

    if (summary.topMerchants.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(
                  LucideIcons.store,
                  size: 16,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Top Merchants',
                style: AppTypography.h4,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: AppRadius.chip,
                ),
                child: Text(
                  '${summary.totalMerchants} total',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Summary stats
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total Spending',
                  value: CurrencyFormatter.format(summary.totalSpending),
                  icon: LucideIcons.dollarSign,
                  color: AppColors.expense,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  label: 'Top Merchant',
                  value: summary.topMerchant ?? '-',
                  icon: LucideIcons.trophy,
                  color: AppColors.amber,
                  isText: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Top merchants chart
          const TopMerchantsChart(limit: 5),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isText;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.xsAll,
            ),
            child: Icon(
              icon,
              size: 14,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: isText
                      ? AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        )
                      : AppTypography.moneySmall.copyWith(
                          fontSize: 12,
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
