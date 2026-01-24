import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../chips/selection_chip.dart';

class InlineSelectorItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Color? color;

  const InlineSelectorItem({
    required this.value,
    required this.label,
    this.icon,
    this.color,
  });
}

class InlineSelector<T> extends StatelessWidget {
  final String? label;
  final List<InlineSelectorItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T>? onChanged;
  final EdgeInsets? padding;

  const InlineSelector({
    super.key,
    this.label,
    required this.items,
    this.selectedValue,
    this.onChanged,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: Text(
              label!,
              style: AppTypography.labelMedium,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.chipGap),
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = item.value == selectedValue;

              return SelectionChip(
                label: item.label,
                icon: item.icon,
                iconColor: item.color,
                isSelected: isSelected,
                selectedColor: item.color ?? AppColors.textPrimary,
                onTap: () => onChanged?.call(item.value),
              );
            },
          ),
        ),
      ],
    );
  }
}
