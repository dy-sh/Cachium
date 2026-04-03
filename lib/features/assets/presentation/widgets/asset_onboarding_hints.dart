import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';

class AssetOnboardingHints extends StatelessWidget {
  final bool hasTransactions;
  final double? purchasePrice;

  const AssetOnboardingHints({
    super.key,
    required this.hasTransactions,
    this.purchasePrice,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!hasTransactions && (purchasePrice == null || purchasePrice == 0))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.accentPrimary.withValues(alpha: 0.08),
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.info, size: 16, color: AppColors.accentPrimary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Get started by adding a purchase price or linking transactions to track this asset\'s costs.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.accentPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (purchasePrice != null && purchasePrice! > 0 && !hasTransactions)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.accentPrimary.withValues(alpha: 0.08),
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: AppColors.accentPrimary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.info, size: 16, color: AppColors.accentPrimary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Create a purchase transaction to track this asset\'s cost in your finances.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.accentPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
