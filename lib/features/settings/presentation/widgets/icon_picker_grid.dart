import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

class IconPickerGrid extends StatelessWidget {
  final IconData selectedIcon;
  final Color selectedColor;
  final ValueChanged<IconData>? onIconSelected;

  const IconPickerGrid({
    super.key,
    required this.selectedIcon,
    required this.selectedColor,
    this.onIconSelected,
  });

  static final List<IconData> availableIcons = [
    LucideIcons.shoppingCart,
    LucideIcons.utensils,
    LucideIcons.car,
    LucideIcons.home,
    LucideIcons.plane,
    LucideIcons.heartPulse,
    LucideIcons.graduationCap,
    LucideIcons.gamepad2,
    LucideIcons.music,
    LucideIcons.film,
    LucideIcons.gift,
    LucideIcons.coffee,
    LucideIcons.beer,
    LucideIcons.pizza,
    LucideIcons.dumbbell,
    LucideIcons.shirt,
    LucideIcons.scissors,
    LucideIcons.smartphone,
    LucideIcons.laptop,
    LucideIcons.wifi,
    LucideIcons.zap,
    LucideIcons.droplets,
    LucideIcons.flame,
    LucideIcons.dog,
    LucideIcons.cat,
    LucideIcons.baby,
    LucideIcons.users,
    LucideIcons.briefcase,
    LucideIcons.wallet,
    LucideIcons.receipt,
    LucideIcons.creditCard,
    LucideIcons.piggyBank,
    LucideIcons.trendingUp,
    LucideIcons.trendingDown,
    LucideIcons.dollarSign,
    LucideIcons.percent,
    LucideIcons.tag,
    LucideIcons.star,
    LucideIcons.heart,
    LucideIcons.smile,
    LucideIcons.sun,
    LucideIcons.moon,
    LucideIcons.umbrella,
    LucideIcons.snowflake,
    LucideIcons.leaf,
    LucideIcons.flower2,
    LucideIcons.bike,
    LucideIcons.bus,
    LucideIcons.train,
    LucideIcons.ship,
    LucideIcons.building,
    LucideIcons.store,
    LucideIcons.school,
    LucideIcons.church,
    LucideIcons.activity,
    LucideIcons.bookOpen,
    LucideIcons.sparkles,
    LucideIcons.gem,
    LucideIcons.crown,
    LucideIcons.moreHorizontal,
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
      ),
      itemCount: availableIcons.length,
      itemBuilder: (context, index) {
        final icon = availableIcons[index];
        final isSelected = icon == selectedIcon;
        return GestureDetector(
          onTap: onIconSelected != null ? () => onIconSelected!(icon) : null,
          child: AnimatedContainer(
            duration: AppAnimations.normal,
            decoration: BoxDecoration(
              color: isSelected
                  ? selectedColor.withOpacity(0.15)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? selectedColor : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isSelected ? selectedColor : AppColors.textSecondary,
            ),
          ),
        );
      },
    );
  }
}
