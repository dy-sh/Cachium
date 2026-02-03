import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../data/models/prediction_alert.dart';

class PredictionAlertCard extends StatelessWidget {
  final PredictionAlert alert;

  const PredictionAlertCard({
    super.key,
    required this.alert,
  });

  @override
  Widget build(BuildContext context) {
    Color sentimentColor;
    IconData sentimentIcon;
    switch (alert.sentiment) {
      case PredictionSentiment.positive:
        sentimentColor = AppColors.green;
        sentimentIcon = LucideIcons.trendingUp;
        break;
      case PredictionSentiment.warning:
        sentimentColor = AppColors.orange;
        sentimentIcon = LucideIcons.alertCircle;
        break;
      case PredictionSentiment.negative:
        sentimentColor = AppColors.red;
        sentimentIcon = LucideIcons.trendingDown;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: sentimentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              sentimentIcon,
              size: 16,
              color: sentimentColor,
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
                      alert.title,
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: sentimentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        alert.type.displayName,
                        style: AppTypography.labelSmall.copyWith(
                          color: sentimentColor,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
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
