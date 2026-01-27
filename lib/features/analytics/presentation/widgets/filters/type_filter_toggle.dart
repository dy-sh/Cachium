import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_animations.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../../data/models/analytics_filter.dart';
import '../../providers/analytics_filter_provider.dart';

class TypeFilterToggle extends ConsumerWidget {
  const TypeFilterToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(analyticsFilterProvider);
    final accentColor = ref.watch(accentColorProvider);
    final colorIntensity = ref.watch(colorIntensityProvider);

    final incomeColor = AppColors.getTransactionColor('income', colorIntensity);
    final expenseColor = AppColors.getTransactionColor('expense', colorIntensity);

    return Container(
      height: 36,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.chip,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleItem(
            label: 'All',
            isSelected: filter.typeFilter == AnalyticsTypeFilter.all,
            color: accentColor,
            onTap: () {
              ref.read(analyticsFilterProvider.notifier)
                  .setTypeFilter(AnalyticsTypeFilter.all);
            },
          ),
          _ToggleItem(
            label: 'Income',
            isSelected: filter.typeFilter == AnalyticsTypeFilter.income,
            color: incomeColor,
            onTap: () {
              ref.read(analyticsFilterProvider.notifier)
                  .setTypeFilter(AnalyticsTypeFilter.income);
            },
          ),
          _ToggleItem(
            label: 'Expense',
            isSelected: filter.typeFilter == AnalyticsTypeFilter.expense,
            color: expenseColor,
            onTap: () {
              ref.read(analyticsFilterProvider.notifier)
                  .setTypeFilter(AnalyticsTypeFilter.expense);
            },
          ),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ToggleItem({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ToggleItem> createState() => _ToggleItemState();
}

class _ToggleItemState extends State<_ToggleItem>
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
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: AppRadius.smAll,
          ),
          child: Text(
            widget.label,
            style: AppTypography.labelMedium.copyWith(
              color: widget.isSelected ? widget.color : AppColors.textSecondary,
              fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
