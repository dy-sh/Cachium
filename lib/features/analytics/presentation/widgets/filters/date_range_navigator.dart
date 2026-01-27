import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../design_system/components/inputs/date_range_picker/date_range_picker.dart';
import '../../../data/models/date_range_preset.dart';
import '../../providers/analytics_filter_provider.dart';

class DateRangeNavigator extends ConsumerWidget {
  const DateRangeNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(analyticsFilterProvider);
    final isAllTime = filter.preset == DateRangePreset.allTime;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(
      filter.dateRange.end.year,
      filter.dateRange.end.month,
      filter.dateRange.end.day,
    );

    final canGoPrev = !isAllTime;
    final canGoNext = !isAllTime && endDay.isBefore(today);

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: canGoPrev
                ? () => ref.read(analyticsFilterProvider.notifier).shiftDateRange(-1)
                : null,
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Icon(
                LucideIcons.chevronLeft,
                size: 18,
                color: canGoPrev
                    ? AppColors.textSecondary
                    : AppColors.textTertiary.withValues(alpha: 0.3),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _pickCustomRange(context, ref, filter.dateRange),
              child: Text(
                _formatDateRange(filter.dateRange.start, filter.dateRange.end),
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: isAllTime ? AppColors.textSecondary : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: canGoNext
                ? () => ref.read(analyticsFilterProvider.notifier).shiftDateRange(1)
                : null,
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: canGoNext
                    ? AppColors.textSecondary
                    : AppColors.textTertiary.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomRange(
    BuildContext context,
    WidgetRef ref,
    DateRange currentRange,
  ) async {
    final picked = await showFMDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialStart: currentRange.start,
      initialEnd: currentRange.end,
    );
    if (picked == null || !context.mounted) return;

    ref.read(analyticsFilterProvider.notifier).setCustomDateRange(
      DateRange(
        start: picked.start,
        end: DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
      ),
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
