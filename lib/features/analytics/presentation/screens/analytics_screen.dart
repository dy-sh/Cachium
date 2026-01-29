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
import 'package:go_router/go_router.dart';
import '../providers/analytics_filter_provider.dart';
import '../../../analytics/data/models/chart_drill_down.dart';
import '../providers/drill_down_provider.dart';
import '../widgets/filters/analytics_filter_bar.dart';
import '../widgets/filters/date_range_navigator.dart';
import '../widgets/tabs/overview_tab.dart';
import '../widgets/tabs/comparisons_tab.dart';
import '../widgets/tabs/forecasts_tab.dart';

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

  static const _tabs = [
    (label: 'Overview', icon: LucideIcons.layoutGrid),
    (label: 'Compare', icon: LucideIcons.barChart3),
    (label: 'Forecast', icon: LucideIcons.trendingUp),
  ];

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
    final hasFilter = ref.watch(hasActiveFilterProvider);

    // Watch drill-down and navigate to transactions when set
    ref.listen<ChartDrillDown?>(drillDownProvider, (_, drillDown) {
      if (drillDown != null) {
        final params = drillDown.toQueryParameters();
        context.push('/transactions', extra: params);
        // Reset after navigation
        ref.read(drillDownProvider.notifier).state = null;
      }
    });

    return PageLayout(
      title: 'Analytics',
      actions: [
        ...List.generate(_tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: _IconTab(
              label: _tabs[index].label,
              icon: _tabs[index].icon,
              isSelected: isSelected,
              accentColor: accentColor,
              onTap: () => setState(() => _selectedTab = index),
            ),
          );
        }),
        _FilterToggleButton(
          isOpen: _filtersVisible,
          hasFilter: hasFilter,
          accentColor: accentColor,
          onTap: _toggleFilters,
        ),
      ],
      body: Column(
        children: [
          const DateRangeNavigator(),
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
                ForecastsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterToggleButton extends StatefulWidget {
  final bool isOpen;
  final bool hasFilter;
  final Color accentColor;
  final VoidCallback onTap;

  const _FilterToggleButton({
    required this.isOpen,
    required this.hasFilter,
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
            color: widget.isOpen
                ? widget.accentColor.withValues(alpha: 0.1)
                : AppColors.surface,
            borderRadius: AppRadius.chip,
            border: Border.all(
              color: widget.isOpen ? widget.accentColor : AppColors.border,
              width: widget.isOpen ? 1.5 : 1,
            ),
          ),
          child: Icon(
            LucideIcons.slidersHorizontal,
            size: 16,
            color: widget.hasFilter
                ? widget.accentColor
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _IconTab extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _IconTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_IconTab> createState() => _IconTabState();
}

class _IconTabState extends State<_IconTab>
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
    final color = widget.isSelected ? widget.accentColor : AppColors.textSecondary;

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
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: color,
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: AppTypography.labelSmall.copyWith(
                  color: color,
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
