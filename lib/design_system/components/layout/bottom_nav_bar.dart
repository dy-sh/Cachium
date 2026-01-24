import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/animations/haptic_helper.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../features/settings/presentation/providers/settings_provider.dart';

class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badgeCount;

  const BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount,
  });
}

class BottomNavBar extends ConsumerStatefulWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final List<BottomNavItem> items;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
    required this.items,
  });

  static List<BottomNavItem> get defaultItems => [
        const BottomNavItem(
          icon: LucideIcons.home,
          activeIcon: LucideIcons.home,
          label: 'Home',
        ),
        const BottomNavItem(
          icon: LucideIcons.arrowLeftRight,
          activeIcon: LucideIcons.arrowLeftRight,
          label: 'Transactions',
        ),
        const BottomNavItem(
          icon: LucideIcons.wallet,
          activeIcon: LucideIcons.wallet,
          label: 'Accounts',
        ),
        const BottomNavItem(
          icon: LucideIcons.settings,
          activeIcon: LucideIcons.settings,
          label: 'Settings',
        ),
      ];

  @override
  ConsumerState<BottomNavBar> createState() => _FMBottomNavBarState();
}

class _FMBottomNavBarState extends ConsumerState<BottomNavBar> {
  @override
  Widget build(BuildContext context) {
    final accentColor = ref.watch(accentColorProvider);

    return Container(
      height: AppSpacing.bottomNavHeight + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(widget.items.length, (index) {
          final item = widget.items[index];
          final isSelected = index == widget.currentIndex;

          return _NavItem(
            item: item,
            isSelected: isSelected,
            accentColor: accentColor,
            onTap: () => widget.onTap?.call(index),
          );
        }),
      ),
    );
  }
}

class _NavItem extends ConsumerStatefulWidget {
  final BottomNavItem item;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  ConsumerState<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends ConsumerState<_NavItem> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: AppAnimations.fast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: AppAnimations.tapScaleLarge).animate(
      CurvedAnimation(parent: _scaleController, curve: AppAnimations.defaultCurve),
    );

    _bounceController = AnimationController(
      duration: AppAnimations.pageTransition,
      vsync: this,
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _bounceController,
      curve: AppAnimations.defaultCurve,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    final animationsEnabled = ref.read(tabTransitionsEnabledProvider);
    if (animationsEnabled) {
      _scaleController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    final animationsEnabled = ref.read(tabTransitionsEnabledProvider);
    if (animationsEnabled) {
      _scaleController.reverse();
      _bounceController.forward(from: 0);
    }
    HapticHelper.lightImpact();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final animationsEnabled = ref.watch(tabTransitionsEnabledProvider);
    final color = widget.isSelected ? widget.accentColor : AppColors.navInactive;
    final hasBadge = widget.item.badgeCount != null && widget.item.badgeCount! > 0;

    if (!animationsEnabled) {
      return GestureDetector(
        onTap: () {
          HapticHelper.lightImpact();
          widget.onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minWidth: 64),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    widget.isSelected ? widget.item.activeIcon : widget.item.icon,
                    color: color,
                    size: 24,
                  ),
                  if (hasBadge)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.expense,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          widget.item.badgeCount! > 9 ? '9+' : '${widget.item.badgeCount}',
                          style: AppTypography.navLabel.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 12,
                child: Opacity(
                  opacity: widget.isSelected ? 1.0 : 0.0,
                  child: Text(
                    widget.item.label,
                    style: AppTypography.navLabel.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _bounceAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              constraints: const BoxConstraints(minWidth: 64),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Transform.scale(
                        scale: _bounceAnimation.value,
                        child: AnimatedSwitcher(
                          duration: AppAnimations.normal,
                          child: Icon(
                            widget.isSelected ? widget.item.activeIcon : widget.item.icon,
                            key: ValueKey(widget.isSelected),
                            color: color,
                            size: 24,
                          ),
                        ),
                      ),
                      if (hasBadge)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.expense,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              widget.item.badgeCount! > 9 ? '9+' : '${widget.item.badgeCount}',
                              style: AppTypography.navLabel.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 12,
                    child: AnimatedOpacity(
                      duration: AppAnimations.normal,
                      opacity: widget.isSelected ? 1.0 : 0.0,
                      child: Text(
                        widget.item.label,
                        style: AppTypography.navLabel.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
