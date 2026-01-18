import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../accounts/data/models/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../settings/data/models/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class AccountPreviewList extends ConsumerWidget {
  const AccountPreviewList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final intensity = ref.watch(colorIntensityProvider);

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        itemCount: accounts.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          return _AccountPreviewCard(account: accounts[index], intensity: intensity);
        },
      ),
    );
  }
}

class _AccountPreviewCard extends ConsumerWidget {
  final Account account;
  final ColorIntensity intensity;

  const _AccountPreviewCard({
    required this.account,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountColor = account.getColorWithIntensity(intensity);
    final expenseColor = AppColors.getTransactionColor('expense', intensity);

    return Container(
      width: 160,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: accountColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accountColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  account.icon,
                  color: accountColor,
                  size: 14,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  account.name,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            CurrencyFormatter.format(account.balance),
            style: AppTypography.moneySmall.copyWith(
              color: account.balance >= 0 ? AppColors.textPrimary : expenseColor,
            ),
          ),
        ],
      ),
    );
  }
}
