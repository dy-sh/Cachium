import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/transactions_provider.dart';

class AccountFilterSheet extends ConsumerWidget {
  const AccountFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];
    final filter = ref.watch(advancedTransactionFilterProvider);
    final selected = filter.selectedAccountIds;
    final intensity = ref.watch(colorIntensityProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadius.xxsAll,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filter by Account', style: AppTypography.h4),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => ref.read(advancedTransactionFilterProvider.notifier)
                          .setAccounts(accounts.map((a) => a.id).toSet()),
                      child: Text('Select All', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    GestureDetector(
                      onTap: () => ref.read(advancedTransactionFilterProvider.notifier).setAccounts({}),
                      child: Text('Clear', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: SingleChildScrollView(
                child: Column(
                  children: accounts.map((account) {
                    final isSelected = selected.contains(account.id);
                    return GestureDetector(
                      onTap: () => ref.read(advancedTransactionFilterProvider.notifier).toggleAccount(account.id),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: account.getColorWithIntensity(intensity).withValues(alpha: 0.15),
                                borderRadius: AppRadius.smAll,
                              ),
                              child: Center(
                                child: Icon(account.icon, size: 16, color: account.getColorWithIntensity(intensity)),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                account.name,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(LucideIcons.check, size: 18, color: AppColors.textPrimary),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
