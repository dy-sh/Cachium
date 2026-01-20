import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final accountsAsync = ref.watch(accountsProvider);
    final intensity = ref.watch(colorIntensityProvider);

    return accountsAsync.when(
      loading: () => SizedBox(
        height: 72,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      ),
      error: (error, stack) => SizedBox(
        height: 72,
        child: Center(
          child: Text(
            'Error loading accounts',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          ),
        ),
      ),
      data: (accounts) => SizedBox(
        height: 72,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          itemCount: accounts.length,
          separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            return _AccountPreviewCard(account: accounts[index], intensity: intensity);
          },
        ),
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
    final bgOpacity = AppColors.getBgOpacity(intensity);
    final cardStyle = ref.watch(accountCardStyleProvider);

    // Opacity multipliers based on card style
    final gradientStart = cardStyle == AccountCardStyle.bright ? 0.6 : 0.35;
    final gradientEnd = cardStyle == AccountCardStyle.bright ? 0.3 : 0.15;
    final circleOpacity = cardStyle == AccountCardStyle.bright ? 0.3 : 0.15;
    final shadowOpacity = cardStyle == AccountCardStyle.bright ? 0.15 : 0.08;
    final shadowBlur = cardStyle == AccountCardStyle.bright ? 12.0 : 8.0;
    final shadowOffset = cardStyle == AccountCardStyle.bright ? 4.0 : 2.0;

    return GestureDetector(
      onTap: () => context.push('/account/${account.id}'),
      child: Container(
      width: 180,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accountColor.withOpacity(bgOpacity * gradientStart),
            accountColor.withOpacity(bgOpacity * gradientEnd),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accountColor.withOpacity(shadowOpacity),
            blurRadius: shadowBlur,
            offset: Offset(0, shadowOffset),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accountColor.withOpacity(bgOpacity * circleOpacity),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
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
                        color: accountColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(
                        account.icon,
                        color: AppColors.background,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            account.name,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            account.type.displayName,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary.withOpacity(0.7),
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  CurrencyFormatter.format(account.balance),
                  style: AppTypography.moneySmall.copyWith(
                    color: account.balance >= 0 ? AppColors.textPrimary : expenseColor,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
