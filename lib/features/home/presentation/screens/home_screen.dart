import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/animations/staggered_list.dart';
import '../../../../navigation/app_router.dart';
import '../widgets/account_preview_list.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recent_transactions_list.dart';
import '../widgets/total_balance_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                GestureDetector(
                  onTap: () => context.push(AppRoutes.transactionForm),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      LucideIcons.plus,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: AppSpacing.bottomNavHeight + AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Balance Card
                  StaggeredListItem(
                    index: 0,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                      child: TotalBalanceCard(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Quick Actions
                  StaggeredListItem(
                    index: 1,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                      child: QuickActions(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Accounts Preview
                  StaggeredListItem(
                    index: 2,
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
                  const SizedBox(height: AppSpacing.xxl),

                  // Recent Transactions
                  StaggeredListItem(
                    index: 3,
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
                ],
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
