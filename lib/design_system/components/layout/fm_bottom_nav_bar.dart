import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';

class FMBottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const FMBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class FMBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final List<FMBottomNavItem> items;

  const FMBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
    required this.items,
  });

  static List<FMBottomNavItem> get defaultItems => [
        const FMBottomNavItem(
          icon: LucideIcons.home,
          activeIcon: LucideIcons.home,
          label: 'Home',
        ),
        const FMBottomNavItem(
          icon: LucideIcons.arrowLeftRight,
          activeIcon: LucideIcons.arrowLeftRight,
          label: 'Transactions',
        ),
        const FMBottomNavItem(
          icon: LucideIcons.wallet,
          activeIcon: LucideIcons.wallet,
          label: 'Accounts',
        ),
        const FMBottomNavItem(
          icon: LucideIcons.settings,
          activeIcon: LucideIcons.settings,
          label: 'Settings',
        ),
      ];

  @override
  Widget build(BuildContext context) {
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
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == currentIndex;

          return _NavItem(
            item: item,
            isSelected: isSelected,
            onTap: () => onTap?.call(index),
          );
        }),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final FMBottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected ? AppColors.navActive : AppColors.navInactive;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: SizedBox(
              width: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.isSelected ? widget.item.activeIcon : widget.item.icon,
                      key: ValueKey(widget.isSelected),
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.item.label,
                    style: AppTypography.navLabel.copyWith(
                      color: color,
                      fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
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
