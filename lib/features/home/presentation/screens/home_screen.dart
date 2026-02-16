import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/buttons/circular_button.dart';
import '../../../../design_system/animations/staggered_list.dart';
import '../../../../navigation/app_router.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../../budgets/presentation/providers/budget_provider.dart';
import '../widgets/account_preview_list.dart';
import '../widgets/budget_progress_list.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recent_transactions_list.dart';
import '../widgets/total_balance_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showAccountsList = ref.watch(homeShowAccountsListProvider);
    final showTotalBalance = ref.watch(homeShowTotalBalanceProvider);
    final showQuickActions = ref.watch(homeShowQuickActionsProvider);
    final showRecentTransactions = ref.watch(homeShowRecentTransactionsProvider);

    // Build visible sections list for staggered animation indexing
    final visibleSections = <Widget>[];
    int staggerIndex = 0;

    if (showAccountsList) {
      visibleSections.add(
        StaggeredListItem(
          index: staggerIndex++,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Accounts', style: AppTypography.h4),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.accounts),
                      child: Text(
                        'See all',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const AccountPreviewList(),
            ],
          ),
        ),
      );
      visibleSections.add(const SizedBox(height: AppSpacing.xxl));
    }

    if (showTotalBalance) {
      visibleSections.add(
        StaggeredListItem(
          index: staggerIndex++,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: TotalBalanceCard(),
          ),
        ),
      );
      visibleSections.add(const SizedBox(height: AppSpacing.xxl));
    }

    if (showQuickActions) {
      visibleSections.add(
        StaggeredListItem(
          index: staggerIndex++,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: QuickActions(),
          ),
        ),
      );
      visibleSections.add(const SizedBox(height: AppSpacing.xxl));
    }

    // Budget progress - always shown if budgets exist
    final now = DateTime.now();
    final budgetProgress = ref.watch(
      budgetProgressProvider((year: now.year, month: now.month)),
    );
    if (budgetProgress.isNotEmpty) {
      visibleSections.add(
        StaggeredListItem(
          index: staggerIndex++,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Budget', style: AppTypography.h4),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const BudgetProgressList(),
            ],
          ),
        ),
      );
      visibleSections.add(const SizedBox(height: AppSpacing.xxl));
    }

    if (showRecentTransactions) {
      visibleSections.add(
        StaggeredListItem(
          index: staggerIndex++,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Transactions', style: AppTypography.h4),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.transactions),
                      child: Text(
                        'See all',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const RecentTransactionsList(),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          // Fixed Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good ${_getGreeting()}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cachium',
                      style: AppTypography.h2,
                    ),
                  ],
                ),
                Row(
                  children: [
                    CircularButton(
                      onTap: () => context.push(AppRoutes.search),
                      icon: LucideIcons.search,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    CircularButton.add(
                      onTap: () => context.push(AppRoutes.transactionForm),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Scrollable Content
          Expanded(
            child: RefreshIndicator(
              color: AppColors.textPrimary,
              backgroundColor: AppColors.surface,
              onRefresh: () async {
                await Future.wait([
                  ref.read(transactionsProvider.notifier).refresh(),
                  ref.read(accountsProvider.notifier).refresh(),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AppSpacing.bottomNavHeight + AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: visibleSections,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}
