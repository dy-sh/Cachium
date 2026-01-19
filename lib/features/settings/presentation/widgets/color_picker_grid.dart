import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

class ColorPickerGrid extends StatelessWidget {
  final List<Color> colors;
  final Color selectedColor;
  final ValueChanged<Color>? onColorSelected;
  final int crossAxisCount;
  final double itemSize;

  const ColorPickerGrid({
    super.key,
    required this.colors,
    required this.selectedColor,
    this.onColorSelected,
    this.crossAxisCount = 8,
    this.itemSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: colors.map((color) {
        final isSelected = color.value == selectedColor.value;
        return GestureDetector(
          onTap: onColorSelected != null ? () => onColorSelected!(color) : null,
          child: AnimatedContainer(
            duration: AppAnimations.normal,
            width: itemSize,
            height: itemSize,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.textPrimary : Colors.transparent,
                width: 2,
              ),
            ),
            child: isSelected
                ? Icon(
                    LucideIcons.check,
                    size: 18,
                    color: _getContrastColor(color),
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
