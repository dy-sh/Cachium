import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../design_system/animations/animated_counter.dart';
import '../../../../design_system/animations/staggered_list.dart';
import '../../../../navigation/app_router.dart';
import '../../../settings/data/models/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/account.dart';
import '../providers/accounts_provider.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalBalance = ref.watch(totalBalanceProvider);
    final accountsByType = ref.watch(accountsByTypeProvider);
    final intensity = ref.watch(colorIntensityProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Accounts', style: AppTypography.h2),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.accountForm),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(
                      LucideIcons.plus,
                      color: ref.watch(accentColorProvider),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Total balance header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.lgAll,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Balance',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AnimatedCounter(
                    value: totalBalance,
                    style: AppTypography.moneyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Accounts list
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(
                left: AppSpacing.screenPadding,
                right: AppSpacing.screenPadding,
                bottom: AppSpacing.bottomNavHeight + AppSpacing.lg,
              ),
              children: () {
                int sectionIndex = 0;
                return AccountType.values.map((type) {
                  final accounts = accountsByType[type] ?? [];
                  if (accounts.isEmpty) return const SizedBox.shrink();

                  final currentIndex = sectionIndex;
                  sectionIndex++;
                  return StaggeredListItem(
                    index: currentIndex,
                    child: _AccountTypeSection(
                      type: type,
                      accounts: accounts,
                      intensity: intensity,
                    ),
                  );
                }).toList();
              }(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTypeSection extends StatelessWidget {
  final AccountType type;
  final List<Account> accounts;
  final ColorIntensity intensity;

  const _AccountTypeSection({
    required this.type,
    required this.accounts,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            type.displayName,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: accounts.map((account) => _AccountCard(account: account, intensity: intensity)).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _AccountCard extends ConsumerWidget {
  final Account account;
  final ColorIntensity intensity;

  const _AccountCard({
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

    return Container(
      width: 180,
      height: 72,
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
    );
  }
}
