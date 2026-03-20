import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/formatting_providers.dart';
import '../../../../design_system/design_system.dart';
import '../../../../navigation/app_router.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/data/models/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/bill.dart';
import '../providers/bill_provider.dart';

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billsProvider);
    final intensity = ref.watch(colorIntensityProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SettingsHeader(
              title: 'Bills',
              actions: [
                CircularButton(
                  onTap: () => context.push(AppRoutes.billForm),
                  icon: LucideIcons.plus,
                  size: AppSpacing.settingsBackButtonSize,
                ),
              ],
            ),
            Expanded(
              child: billsAsync.when(
                data: (bills) {
                  if (bills.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: EmptyState.centered(
                        icon: LucideIcons.bellRing,
                        title: 'No bills yet',
                        subtitle:
                            'Add your recurring bills to track due dates and never miss a payment.',
                        actionLabel: 'Add Bill',
                        onTap: () => context.push(AppRoutes.billForm),
                      ),
                    );
                  }

                  // Separate overdue, upcoming unpaid, and paid
                  final overdue = bills
                      .where((b) => b.isOverdue)
                      .toList()
                    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
                  final unpaid = bills
                      .where((b) => !b.isPaid && !b.isOverdue)
                      .toList()
                    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
                  final paid = bills
                      .where((b) => b.isPaid)
                      .toList()
                    ..sort((a, b) => b.paidDate!.compareTo(a.paidDate!));

                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    children: [
                      if (overdue.isNotEmpty) ...[
                        _SectionHeader(
                          title: 'Overdue',
                          count: overdue.length,
                          color: AppColors.expense,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...overdue.map((bill) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: _BillCard(
                                bill: bill,
                                intensity: intensity,
                                isOverdue: true,
                              ),
                            )),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      if (unpaid.isNotEmpty) ...[
                        _SectionHeader(
                          title: 'Upcoming',
                          count: unpaid.length,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...unpaid.map((bill) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: _BillCard(
                                bill: bill,
                                intensity: intensity,
                              ),
                            )),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      if (paid.isNotEmpty) ...[
                        _SectionHeader(
                          title: 'Paid',
                          count: paid.length,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ...paid.map((bill) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: _BillCard(
                                bill: bill,
                                intensity: intensity,
                                isPaid: true,
                              ),
                            )),
                      ],
                      const SizedBox(height: AppSpacing.xxxl),
                    ],
                  );
                },
                loading: () => const Center(child: LoadingIndicator()),
                error: (_, __) => EmptyState.centered(
                  icon: LucideIcons.alertCircle,
                  title: 'Failed to load bills',
                  subtitle: 'Tap to try again',
                  actionLabel: 'Retry',
                  onTap: () => ref.invalidate(billsProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color? color;

  const _SectionHeader({
    required this.title,
    required this.count,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTypography.h4.copyWith(
            color: color ?? AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: (color ?? AppColors.textSecondary).withValues(alpha: 0.15),
            borderRadius: AppRadius.smAll,
          ),
          child: Text(
            '$count',
            style: AppTypography.labelSmall.copyWith(
              color: color ?? AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _BillCard extends ConsumerWidget {
  final Bill bill;
  final ColorIntensity intensity;
  final bool isOverdue;
  final bool isPaid;

  const _BillCard({
    required this.bill,
    required this.intensity,
    this.isOverdue = false,
    this.isPaid = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = ref.watch(currencyFormatterProvider);
    final dateFormatter = ref.watch(dateFormatterProvider);
    final categoryMap = ref.watch(categoryMapProvider);
    final category = bill.categoryId != null
        ? categoryMap[bill.categoryId]
        : null;

    final borderColor = isOverdue
        ? AppColors.expense.withValues(alpha: 0.5)
        : AppColors.border;

    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.billEdit.replaceFirst(':id', bill.id),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isOverdue
                    ? AppColors.expense.withValues(alpha: 0.15)
                    : isPaid
                        ? AppColors.income.withValues(alpha: 0.15)
                        : AppColors.getAccentColor(3, intensity)
                            .withValues(alpha: 0.15),
                borderRadius: AppRadius.smAll,
              ),
              child: Icon(
                isPaid
                    ? LucideIcons.checkCircle
                    : isOverdue
                        ? LucideIcons.alertCircle
                        : LucideIcons.bellRing,
                size: 20,
                color: isOverdue
                    ? AppColors.expense
                    : isPaid
                        ? AppColors.income
                        : AppColors.getAccentColor(3, intensity),
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Name and details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.name,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isPaid
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                      decoration:
                          isPaid ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (category != null) ...[
                        Text(
                          category.name,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        Text(
                          ' \u2022 ',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                      Text(
                        isPaid
                            ? 'Paid ${dateFormatter.formatShort(bill.paidDate!)}'
                            : isOverdue
                                ? 'Due ${dateFormatter.formatShort(bill.dueDate)}'
                                : _formatDueLabel(bill),
                        style: AppTypography.bodySmall.copyWith(
                          color: isOverdue
                              ? AppColors.expense
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatter.formatInCurrency(bill.amount, bill.currencyCode),
                  style: AppTypography.bodyMedium.copyWith(
                    color: isPaid
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!isPaid) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _markAsPaid(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.income.withValues(alpha: 0.15),
                        borderRadius: AppRadius.smAll,
                      ),
                      child: Text(
                        'Pay',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.income,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDueLabel(Bill bill) {
    final days = bill.daysUntilDue;
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    if (days < 7) return 'Due in $days days';
    return 'Due ${bill.dueDate.month}/${bill.dueDate.day}';
  }

  Future<void> _markAsPaid(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(billsProvider.notifier).markAsPaid(bill.id);
      if (context.mounted) {
        context.showSuccessNotification('${bill.name} marked as paid');
      }
    } catch (e) {
      if (context.mounted) {
        context.showErrorNotification('Failed to mark bill as paid');
      }
    }
  }
}
