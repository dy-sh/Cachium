import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/formatting_providers.dart';
import '../../../../design_system/components/feedback/confirmation_dialog.dart';
import '../../../../design_system/components/feedback/empty_state.dart';
import '../../../../design_system/components/feedback/notification.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/recurring_rule.dart';
import '../../data/models/transaction.dart';
import '../providers/recurring_rules_provider.dart';

class RecurringRulesScreen extends ConsumerWidget {
  const RecurringRulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(recurringRulesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Icon(
                            LucideIcons.chevronLeft,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text('Recurring Transactions', style: AppTypography.h3),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
            Expanded(
              child: rulesAsync.when(
                data: (rules) {
                  if (rules.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: EmptyState.centered(
                        icon: LucideIcons.repeat,
                        title: 'No Recurring Transactions',
                        subtitle:
                            'Create recurring rules from the transaction form to auto-generate transactions.',
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    itemCount: rules.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final rule = rules[index];
                      return _RecurringRuleCard(rule: rule);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.textSecondary,
                  ),
                ),
                error: (_, __) => const Center(
                  child: Text('Failed to load recurring rules'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurringRuleCard extends ConsumerWidget {
  final RecurringRule rule;

  const _RecurringRuleCard({required this.rule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final category = categories.where((c) => c.id == rule.categoryId).firstOrNull;
    final intensity = ref.watch(colorIntensityProvider);
    final typeColor = rule.type == TransactionType.income
        ? AppColors.getTransactionColor('income', intensity)
        : AppColors.getTransactionColor('expense', intensity);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rule.isActive ? AppColors.border : AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              rule.frequency.icon,
              size: 20,
              color: rule.isActive ? typeColor : AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.name,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: rule.isActive
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${rule.frequency.displayName} \u2022 ${category?.name ?? 'Unknown'}',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            ref.watch(currencyFormatterProvider).formatWithSign(rule.amount, rule.type.name),
            style: AppTypography.bodyMedium.copyWith(
              color: rule.isActive ? typeColor : AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          PopupMenuButton<String>(
            icon: Icon(
              LucideIcons.moreVertical,
              size: 18,
              color: AppColors.textSecondary,
            ),
            color: AppColors.surface,
            onSelected: (value) async {
              if (value == 'toggle') {
                await ref
                    .read(recurringRulesProvider.notifier)
                    .toggleActive(rule.id);
              } else if (value == 'delete') {
                final confirmed = await showConfirmationDialog(
                  context: context,
                  title: 'Delete Rule',
                  message:
                      'Are you sure you want to delete "${rule.name}"? This will not affect already generated transactions.',
                  confirmLabel: 'Delete',
                  isDestructive: true,
                );
                if (confirmed && context.mounted) {
                  await ref
                      .read(recurringRulesProvider.notifier)
                      .deleteRule(rule.id);
                  if (context.mounted) {
                    context.showSuccessNotification('Recurring rule deleted');
                  }
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      rule.isActive ? LucideIcons.pause : LucideIcons.play,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      rule.isActive ? 'Pause' : 'Resume',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.trash2,
                      size: 16,
                      color: AppColors.expense,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Delete',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.expense,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
