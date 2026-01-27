import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/layout/page_layout.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../widgets/tabs/overview_tab.dart';
import '../widgets/tabs/comparisons_tab.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _selectedTab = 0;

  static const _tabs = ['Overview', 'Comparisons'];

  @override
  Widget build(BuildContext context) {
    final accentColor = ref.watch(accentColorProvider);

    return PageLayout(
      title: 'Analytics',
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_tabs.length, (index) {
            final isSelected = _selectedTab == index;
            return Padding(
              padding: EdgeInsets.only(
                right: index < _tabs.length - 1 ? AppSpacing.sm : AppSpacing.sm,
              ),
              child: _TabChip(
                label: _tabs[index],
                isSelected: isSelected,
                accentColor: accentColor,
                onTap: () => setState(() => _selectedTab = index),
              ),
            );
          }),
        ),
      ],
      body: IndexedStack(
        index: _selectedTab,
        children: const [
          OverviewTab(),
          ComparisonsTab(),
        ],
      ),
    );
  }
}

class _TabChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_TabChip> createState() => _TabChipState();
}

class _TabChipState extends State<_TabChip>
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
    final borderColor =
        widget.isSelected ? widget.accentColor : AppColors.border;

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
          child: Text(
            widget.label,
            style: AppTypography.labelMedium.copyWith(
              color: widget.isSelected
                  ? widget.accentColor
                  : AppColors.textPrimary,
              fontWeight:
                  widget.isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
