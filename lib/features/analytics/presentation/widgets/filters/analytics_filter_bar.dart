import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../providers/analytics_filter_provider.dart';
import 'account_filter_chips.dart';
import 'category_filter_popup.dart';
import 'date_range_selector.dart';
import 'type_filter_toggle.dart';

class AnalyticsFilterBar extends ConsumerWidget {
  const AnalyticsFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(analyticsFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.screenPadding,
            right: AppSpacing.screenPadding,
            bottom: AppSpacing.sm,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => ref.read(analyticsFilterProvider.notifier).shiftDateRange(-1),
                child: const Padding(
                  padding: EdgeInsets.only(right: AppSpacing.sm),
                  child: Icon(
                    LucideIcons.chevronLeft,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _formatDateRange(filter.dateRange.start, filter.dateRange.end),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => ref.read(analyticsFilterProvider.notifier).shiftDateRange(1),
                child: const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.sm),
                  child: Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const DateRangeSelector(),
        const SizedBox(height: AppSpacing.md),
        const AccountFilterChips(),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Row(
            children: const [
              CategoryFilterPopup(),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Row(
            children: const [
              TypeFilterToggle(),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final startFormat = DateFormat('MMM d');
    final endFormat = DateFormat('MMM d, yyyy');

    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return endFormat.format(end);
    }

    if (start.year == end.year) {
      return '${startFormat.format(start)} - ${endFormat.format(end)}';
    }

    return '${DateFormat('MMM d, yyyy').format(start)} - ${endFormat.format(end)}';
  }
}
