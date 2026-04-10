import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/date_formatter.dart';
import '../providers/asset_analytics_providers.dart';

enum _TimeRange { allTime, thisYear, last12Months, custom }

/// Horizontal chip row for selecting the analytics time range on the asset
/// detail screen. Writes the chosen range into [assetDetailDateRangeProvider].
class AssetTimeRangeSelector extends ConsumerStatefulWidget {
  final String assetId;

  const AssetTimeRangeSelector({super.key, required this.assetId});

  @override
  ConsumerState<AssetTimeRangeSelector> createState() =>
      _AssetTimeRangeSelectorState();
}

class _AssetTimeRangeSelectorState
    extends ConsumerState<AssetTimeRangeSelector> {
  _TimeRange _selected = _TimeRange.allTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assetDetailDateRangeProvider.notifier).state = null;
    });
  }

  void _setRange(_TimeRange range) {
    setState(() => _selected = range);
    final now = DateTime.now();
    DateTimeRange? dateRange;
    switch (range) {
      case _TimeRange.allTime:
        dateRange = null;
      case _TimeRange.thisYear:
        dateRange = DateTimeRange(
          start: DateTime(now.year),
          end: now,
        );
      case _TimeRange.last12Months:
        dateRange = DateTimeRange(
          start: DateTime(now.year - 1, now.month, now.day),
          end: now,
        );
      case _TimeRange.custom:
        return;
    }
    ref.read(assetDetailDateRangeProvider.notifier).state = dateRange;
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final currentRange = ref.read(assetDetailDateRangeProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: currentRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month - 3, now.day),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  surface: AppColors.surface,
                  onSurface: AppColors.textPrimary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selected = _TimeRange.custom);
      ref.read(assetDetailDateRangeProvider.notifier).state = picked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _RangeChip(
            label: 'All Time',
            isSelected: _selected == _TimeRange.allTime,
            onTap: () => _setRange(_TimeRange.allTime),
          ),
          const SizedBox(width: AppSpacing.xs),
          _RangeChip(
            label: 'This Year',
            isSelected: _selected == _TimeRange.thisYear,
            onTap: () => _setRange(_TimeRange.thisYear),
          ),
          const SizedBox(width: AppSpacing.xs),
          _RangeChip(
            label: 'Last 12 Months',
            isSelected: _selected == _TimeRange.last12Months,
            onTap: () => _setRange(_TimeRange.last12Months),
          ),
          const SizedBox(width: AppSpacing.xs),
          _RangeChip(
            label: _selected == _TimeRange.custom
                ? _formatCustomRange(ref.watch(assetDetailDateRangeProvider))
                : 'Custom',
            isSelected: _selected == _TimeRange.custom,
            onTap: _pickCustomRange,
          ),
        ],
      ),
    );
  }

  String _formatCustomRange(DateTimeRange? range) {
    if (range == null) return 'Custom';
    return '${DateFormatter.formatShort(range.start)} \u2013 ${DateFormatter.formatShort(range.end)}';
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RangeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentPrimary.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: AppRadius.smAll,
          border: Border.all(
            color: isSelected ? AppColors.accentPrimary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected
                ? AppColors.accentPrimary
                : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
