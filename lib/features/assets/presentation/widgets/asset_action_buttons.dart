import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../navigation/app_router.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/presentation/providers/transaction_form_provider.dart';
import '../providers/asset_analytics_providers.dart';
import 'asset_link_transactions_sheet.dart';

class AssetActionButtons extends ConsumerWidget {
  final String assetId;

  const AssetActionButtons({
    super.key,
    required this.assetId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intensity = ref.watch(colorIntensityProvider);
    final topCategoryId = ref.watch(assetTopCategoryProvider(assetId));

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  context.push('${AppRoutes.transactionForm}?type=expense');
                  Future.microtask(() {
                    final formNotifier = ref.read(transactionFormProvider.notifier);
                    formNotifier.setAsset(assetId);
                    if (topCategoryId != null) {
                      formNotifier.setCategory(topCategoryId);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.minus, size: 16, color: AppColors.getTransactionColor('expense', intensity)),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Add Expense',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.getTransactionColor('expense', intensity),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  context.push('${AppRoutes.transactionForm}?type=income');
                  Future.microtask(() {
                    final formNotifier = ref.read(transactionFormProvider.notifier);
                    formNotifier.setAsset(assetId);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.plus, size: 16, color: AppColors.getTransactionColor('income', intensity)),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Add Income',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.getTransactionColor('income', intensity),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: () => showLinkTransactionsSheet(context, ref, assetId),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.link, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Link Existing Transactions',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
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
