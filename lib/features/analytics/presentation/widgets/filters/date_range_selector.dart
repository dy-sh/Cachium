import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/constants/app_animations.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../design_system/components/inputs/date_range_picker/date_range_picker.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../../data/models/date_range_preset.dart';
import '../../providers/analytics_filter_provider.dart';

class DateRangeSelector extends ConsumerWidget {
  const DateRangeSelector({super.key});

  static const _presets = [
    DateRangePreset.last7Days,
    DateRangePreset.last30Days,
    DateRangePreset.thisMonth,
    DateRangePreset.last3Months,
    DateRangePreset.last12Months,
    DateRangePreset.thisYear,
    DateRangePreset.allTime,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(analyticsFilterProvider);
    final accentColor = ref.watch(accentColorProvider);
    final isCustom = filter.preset == DateRangePreset.custom;

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        itemCount: _presets.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index < _presets.length) {
            final preset = _presets[index];
            final isSelected = filter.preset == preset;

            return _PresetChip(
              label: preset.displayName,
              isSelected: isSelected,
              accentColor: accentColor,
              onTap: () {
                ref.read(analyticsFilterProvider.notifier).setDateRangePreset(preset);
              },
            );
          }

          return _PresetChip(
            label: 'Custom',
            isSelected: isCustom,
            accentColor: accentColor,
            icon: LucideIcons.calendarRange,
            onTap: () => _pickCustomRange(context, ref, filter.dateRange),
          );
        },
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
}

class _PresetChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;
  final IconData? icon;

  const _PresetChip({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
    this.icon,
  });

  @override
  State<_PresetChip> createState() => _PresetChipState();
}

class _PresetChipState extends State<_PresetChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.fast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: AppAnimations.tapScaleSmall,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.defaultCurve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isSelected ? widget.accentColor : AppColors.border;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: AppAnimations.normal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.accentColor.withValues(alpha: 0.1)
                : AppColors.surface,
            borderRadius: AppRadius.chip,
            border: Border.all(
              color: borderColor,
              width: widget.isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 14,
                  color: widget.isSelected
                      ? widget.accentColor
                      : AppColors.textPrimary,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                widget.label,
                style: AppTypography.labelMedium.copyWith(
                  color: widget.isSelected
                      ? widget.accentColor
                      : AppColors.textPrimary,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
