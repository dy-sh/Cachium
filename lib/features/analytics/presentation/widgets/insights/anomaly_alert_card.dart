import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../categories/presentation/providers/categories_provider.dart';
import '../../../data/models/spending_anomaly.dart';

class AnomalyAlertCard extends ConsumerWidget {
  final SpendingAnomaly anomaly;

  const AnomalyAlertCard({
    super.key,
    required this.anomaly,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final category = anomaly.categoryId != null
        ? categories.firstWhere(
            (c) => c.id == anomaly.categoryId,
            orElse: () => categories.first,
          )
        : null;

    Color severityColor;
    IconData severityIcon;
    switch (anomaly.severity) {
      case AnomalySeverity.high:
        severityColor = AppColors.red;
        severityIcon = LucideIcons.alertTriangle;
        break;
      case AnomalySeverity.medium:
        severityColor = AppColors.orange;
        severityIcon = LucideIcons.alertCircle;
        break;
      case AnomalySeverity.low:
        severityColor = AppColors.yellow;
        severityIcon = LucideIcons.info;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: severityColor.withValues(alpha: 0.08),
        borderRadius: AppRadius.card,
        border: Border.all(
          color: severityColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              severityIcon,
              size: 16,
              color: severityColor,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      anomaly.type.displayName,
                      style: AppTypography.labelMedium.copyWith(
                        color: severityColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          category.name,
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  anomaly.message,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
