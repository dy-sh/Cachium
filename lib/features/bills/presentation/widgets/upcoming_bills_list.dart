import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/formatting_providers.dart';
import '../../../../navigation/app_router.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/bill.dart';
import '../providers/bill_provider.dart';

/// Shows the next 3 upcoming bills on the home screen.
class UpcomingBillsList extends ConsumerWidget {
  const UpcomingBillsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingBillsProvider);
    final overdue = ref.watch(overdueBillsProvider);
    final formatter = ref.watch(currencyFormatterProvider);
    final intensity = ref.watch(colorIntensityProvider);

    // Combine overdue + upcoming, limit to 3
    final allBills = [...overdue, ...upcoming];
    // Remove duplicates (overdue are also in upcoming by definition)
    final seen = <String>{};
    final uniqueBills = allBills.where((b) => seen.add(b.id)).take(3).toList();

    if (uniqueBills.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.checkCircle,
                size: 20,
                color: AppColors.income,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'No upcoming bills',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        children: uniqueBills.map((bill) {
          final isOverdue = bill.isOverdue;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.bills),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: AppRadius.mdAll,
                  border: Border.all(
                    color: isOverdue
                        ? AppColors.expense.withValues(alpha: 0.5)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? AppColors.expense.withValues(alpha: 0.15)
                            : AppColors.getAccentColor(3, intensity)
                                .withValues(alpha: 0.15),
                        borderRadius: AppRadius.smAll,
                      ),
                      child: Icon(
                        isOverdue
                            ? LucideIcons.alertCircle
                            : LucideIcons.bellRing,
                        size: 16,
                        color: isOverdue
                            ? AppColors.expense
                            : AppColors.getAccentColor(3, intensity),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill.name,
                            style: AppTypography.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _formatDueLabel(bill),
                            style: AppTypography.labelSmall.copyWith(
                              color: isOverdue
                                  ? AppColors.expense
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatter.formatInCurrency(bill.amount, bill.currencyCode),
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatDueLabel(Bill bill) {
    final days = bill.daysUntilDue;
    if (days < 0) return 'Overdue by ${-days} days';
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    if (days < 7) return 'Due in $days days';
    return 'Due ${bill.dueDate.month}/${bill.dueDate.day}';
  }
}
