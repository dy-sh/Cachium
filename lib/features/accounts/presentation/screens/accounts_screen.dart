import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../design_system/design_system.dart';
import '../../../../navigation/app_router.dart';
import '../../../settings/data/models/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/account.dart';
import '../providers/accounts_provider.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final accountsByType = ref.watch(accountsByTypeProvider);
    final intensity = ref.watch(colorIntensityProvider);
    final isLoading = accountsAsync.isLoading;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          FMScreenHeader(
            title: 'Accounts',
            onActionPressed: () => context.push(AppRoutes.accountForm),
            actionIconColor: ref.watch(accentColorProvider),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Total balance header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                borderRadius: AppRadius.lgAll,
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.surfaceLight.withOpacity(0.5),
                    AppColors.surface.withOpacity(0.3),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with label
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: totalBalance >= 0
                              ? AppColors.getTransactionColor('income', intensity)
                              : AppColors.getTransactionColor('expense', intensity),
                          boxShadow: [
                            BoxShadow(
                              color: (totalBalance >= 0
                                      ? AppColors.getTransactionColor('income', intensity)
                                      : AppColors.getTransactionColor('expense', intensity))
                                  .withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'TOTAL BALANCE',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Main balance amount
                  AnimatedCounter(
                    value: totalBalance,
                    style: AppTypography.moneyLarge.copyWith(
                      fontSize: 38,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Accounts list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
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

    return GestureDetector(
      onTap: () => context.push('/account/${account.id}'),
      child: Container(
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
      ),
    );
  }
}
