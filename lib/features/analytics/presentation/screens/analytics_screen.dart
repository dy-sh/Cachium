import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/layout/page_layout.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../widgets/filters/analytics_filter_bar.dart';
import '../widgets/tabs/overview_tab.dart';
import '../widgets/tabs/comparisons_tab.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  bool _filtersVisible = true;

  late AnimationController _filterAnimController;
  late Animation<double> _filterSlideAnimation;
  late Animation<double> _filterFadeAnimation;

  static const _tabs = ['Overview', 'Comparisons'];

  @override
  void initState() {
    super.initState();
    _filterAnimController = AnimationController(
      duration: AppAnimations.slow,
      vsync: this,
      value: 1.0,
    );
    _filterSlideAnimation = CurvedAnimation(
      parent: _filterAnimController,
      curve: AppAnimations.defaultCurve,
    );
    _filterFadeAnimation = CurvedAnimation(
      parent: _filterAnimController,
      curve: AppAnimations.defaultCurve,
    );
  }

  @override
  void dispose() {
    _filterAnimController.dispose();
    super.dispose();
  }

  void _toggleFilters() {
    setState(() => _filtersVisible = !_filtersVisible);
    if (_filtersVisible) {
      _filterAnimController.forward();
    } else {
      _filterAnimController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = ref.watch(accentColorProvider);

    return PageLayout(
      title: 'Analytics',
      actions: [
        ...List.generate(_tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: _TabChip(
              label: _tabs[index],
              isSelected: isSelected,
              accentColor: accentColor,
              onTap: () => setState(() => _selectedTab = index),
            ),
          );
        }),
        _FilterToggleButton(
          isActive: _filtersVisible,
          accentColor: accentColor,
          onTap: _toggleFilters,
        ),
      ],
      body: Column(
        children: [
          SizeTransition(
            sizeFactor: _filterSlideAnimation,
            axisAlignment: -1.0,
            child: FadeTransition(
              opacity: _filterFadeAnimation,
              child: const AnalyticsFilterBar(),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: const [
                OverviewTab(),
                ComparisonsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterToggleButton extends StatefulWidget {
  final bool isActive;
  final Color accentColor;
  final VoidCallback onTap;

  const _FilterToggleButton({
    required this.isActive,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_FilterToggleButton> createState() => _FilterToggleButtonState();
}

class _FilterToggleButtonState extends State<_FilterToggleButton>
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
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: widget.isActive
                ? widget.accentColor.withValues(alpha: 0.1)
                : AppColors.surface,
            borderRadius: AppRadius.chip,
            border: Border.all(
              color: widget.isActive ? widget.accentColor : AppColors.border,
              width: widget.isActive ? 1.5 : 1,
            ),
          ),
          child: Icon(
            LucideIcons.slidersHorizontal,
            size: 16,
            color: widget.isActive
                ? widget.accentColor
                : AppColors.textSecondary,
          ),
        ),
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
