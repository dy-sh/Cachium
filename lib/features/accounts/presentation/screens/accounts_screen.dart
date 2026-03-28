import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../design_system/design_system.dart';
import '../../../../navigation/app_router.dart';
import '../../../../core/providers/exchange_rate_provider.dart';
import '../../../settings/data/models/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/account.dart';
import '../providers/accounts_provider.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  bool _isReorderMode = false;

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final mainCurrency = ref.watch(mainCurrencyCodeProvider);
    final accountsByType = ref.watch(accountsByTypeProvider);
    final intensity = ref.watch(colorIntensityProvider);
    final cardStyle = ref.watch(accountCardStyleProvider);
    final rates = ref.watch(exchangeRatesProvider).valueOrNull ?? {};
    final isLoading = accountsAsync.isLoading;

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
                Row(
                  children: [
                    IconBtn(
                      icon: _isReorderMode ? LucideIcons.check : LucideIcons.arrowUpDown,
                      onPressed: () => setState(() => _isReorderMode = !_isReorderMode),
                      iconColor: _isReorderMode ? ref.watch(accentColorProvider) : AppColors.textSecondary,
                      showBorder: true,
                      semanticLabel: _isReorderMode ? 'Done reordering' : 'Reorder accounts',
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconBtn(
                      icon: LucideIcons.plus,
                      onPressed: () => context.push(AppRoutes.accountForm),
                      iconColor: ref.watch(accentColorProvider),
                      showBorder: true,
                      semanticLabel: 'Add account',
                    ),
                  ],
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
                    AppColors.surfaceLight.withValues(alpha: 0.5),
                    AppColors.surface.withValues(alpha: 0.3),
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
                                  .withValues(alpha: 0.5),
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
                  GestureDetector(
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(
                        text: CurrencyFormatter.format(totalBalance, currencyCode: mainCurrency),
                      ));
                      context.showSuccessNotification('Balance copied');
                    },
                    child: AnimatedCounter(
                      value: totalBalance,
                      currencyCode: mainCurrency,
                      style: AppTypography.moneyLarge.copyWith(
                        fontSize: 38,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Exchange rate staleness indicator
          if (!isLoading) Builder(builder: (context) {
            final ratesStale = ref.watch(exchangeRatesStaleProvider);
            final hasMultipleCurrencies = accountsAsync.valueOrNull
                ?.any((a) => a.currencyCode != mainCurrency) ?? false;
            if (!ratesStale || !hasMultipleCurrencies) return const SizedBox(height: AppSpacing.lg);
            final rateAge = ref.watch(exchangeRateAgeProvider);
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.sm,
              ),
              child: GestureDetector(
                onTap: () => ref.read(exchangeRatesProvider.notifier).refresh(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.alertCircle, size: 12, color: AppColors.textTertiary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      rateAge != null ? '$rateAge — tap to refresh' : 'Rates unavailable — tap to refresh',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (isLoading) const SizedBox(height: AppSpacing.lg),

          // Accounts list
          Expanded(
            child: isLoading
                ? ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                    children: List.generate(5, (_) => const ShimmerAccountCard()),
                  )
                : accountsByType.values.every((list) => list.isEmpty)
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                        child: EmptyState.centered(
                          icon: LucideIcons.wallet,
                          title: 'No accounts yet',
                          subtitle: 'Add your first account to start tracking your finances',
                          actionLabel: 'Add Account',
                          onTap: () => context.push(AppRoutes.accountForm),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.textPrimary,
                        backgroundColor: AppColors.surface,
                        onRefresh: () async {
                          await ref.read(accountsProvider.notifier).refresh();
                        },
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
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
                                child: _isReorderMode
                                    ? _ReorderableAccountTypeSection(
                                        type: type,
                                        accounts: accounts,
                                        intensity: intensity,
                                      )
                                    : _AccountTypeSection(
                                        type: type,
                                        accounts: accounts,
                                        intensity: intensity,
                                        cardStyle: cardStyle,
                                        mainCurrency: mainCurrency,
                                        rates: rates,
                                      ),
                              );
                            }).toList();
                          }(),
                        ),
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
  final AccountCardStyle cardStyle;
  final String mainCurrency;
  final Map<String, double> rates;

  const _AccountTypeSection({
    required this.type,
    required this.accounts,
    required this.intensity,
    required this.cardStyle,
    required this.mainCurrency,
    required this.rates,
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
          children: accounts.map((account) => _AccountCard(
            account: account,
            intensity: intensity,
            cardStyle: cardStyle,
            mainCurrency: mainCurrency,
            rates: rates,
          )).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _ReorderableAccountTypeSection extends ConsumerWidget {
  final AccountType type;
  final List<Account> accounts;
  final ColorIntensity intensity;

  const _ReorderableAccountTypeSection({
    required this.type,
    required this.accounts,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          proxyDecorator: (child, index, animation) {
            return Material(
              color: Colors.transparent,
              child: child,
            );
          },
          itemCount: accounts.length,
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) newIndex--;
            ref.read(accountsProvider.notifier).reorderAccount(oldIndex, newIndex, type);
          },
          itemBuilder: (context, index) {
            final account = accounts[index];
            final accountColor = account.getColorWithIntensity(intensity);
            final bgOpacity = AppColors.getBgOpacity(intensity);
            return Container(
              key: ValueKey(account.id),
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: accountColor.withValues(alpha: bgOpacity * 0.3),
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: accountColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.gripVertical,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: accountColor.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(
                      account.icon,
                      color: AppColors.background,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      account.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(account.balance, currencyCode: account.currencyCode),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _AccountCard extends ConsumerWidget {
  final Account account;
  final ColorIntensity intensity;
  final AccountCardStyle cardStyle;
  final String mainCurrency;
  final Map<String, double> rates;

  const _AccountCard({
    required this.account,
    required this.intensity,
    required this.cardStyle,
    required this.mainCurrency,
    required this.rates,
  });

  String _accountSubtitle(WidgetRef ref) {
    final txCount = ref.watch(transactionCountByAccountProvider(account.id));
    if (txCount > 0) {
      return '${account.type.displayName} \u2022 $txCount tx';
    }
    return account.type.displayName;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountColor = account.getColorWithIntensity(intensity);
    final expenseColor = AppColors.getTransactionColor('expense', intensity);
    final bgOpacity = AppColors.getBgOpacity(intensity);

    // Opacity multipliers based on card style
    final gradientStart = cardStyle == AccountCardStyle.bright ? 0.6 : 0.35;
    final gradientEnd = cardStyle == AccountCardStyle.bright ? 0.3 : 0.15;
    final circleOpacity = cardStyle == AccountCardStyle.bright ? 0.3 : 0.15;
    final shadowOpacity = cardStyle == AccountCardStyle.bright ? 0.15 : 0.08;
    final shadowBlur = cardStyle == AccountCardStyle.bright ? 12.0 : 8.0;
    final shadowOffset = cardStyle == AccountCardStyle.bright ? 4.0 : 2.0;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.accountDetailPath(account.id)),
      child: Container(
      width: 180,
      height: account.currencyCode != mainCurrency ? 84 : 72,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accountColor.withValues(alpha: bgOpacity * gradientStart),
            accountColor.withValues(alpha: bgOpacity * gradientEnd),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accountColor.withValues(alpha: shadowOpacity),
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
                color: accountColor.withValues(alpha: bgOpacity * circleOpacity),
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
                        color: accountColor.withValues(alpha: 0.9),
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
                            _accountSubtitle(ref),
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary.withValues(alpha: 0.7),
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
                  CurrencyFormatter.format(account.balance, currencyCode: account.currencyCode),
                  style: AppTypography.moneySmall.copyWith(
                    color: account.balance >= 0 ? AppColors.textPrimary : expenseColor,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (account.currencyCode != mainCurrency)
                  Builder(builder: (context) {
                    final converted = convertToMainCurrency(account.balance, account.currencyCode, mainCurrency, rates);
                    return Text(
                      '\u2248 ${CurrencyFormatter.format(converted, currencyCode: mainCurrency)}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 9,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
