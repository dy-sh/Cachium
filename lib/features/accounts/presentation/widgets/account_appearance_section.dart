import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/widgets/color_picker_grid.dart';
import '../providers/account_form_provider.dart';

class AccountAppearanceSection extends ConsumerWidget {
  final AccountFormState formState;

  const AccountAppearanceSection({super.key, required this.formState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intensity = ref.watch(colorIntensityProvider);
    final accentColors = AppColors.getAccentOptions(intensity);

    final defaultColor = formState.type != null
        ? AppColors.getAccountColor(formState.type!.name, intensity)
        : null;

    Color? selectedColor;
    bool hasCustomColor = formState.hasCustomColor;

    if (formState.customColorIndex != null) {
      selectedColor = accentColors[formState.customColorIndex!.clamp(0, accentColors.length - 1)];
    } else if (formState.originalCustomColor != null) {
      final originalColorIndex = accentColors.indexWhere(
        (c) => c.toARGB32() == formState.originalCustomColor!.toARGB32(),
      );
      if (originalColorIndex != -1) {
        selectedColor = accentColors[originalColorIndex];
        hasCustomColor = true;
      } else {
        selectedColor = defaultColor;
      }
    } else {
      selectedColor = defaultColor;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Color', style: AppTypography.labelMedium),
            if (hasCustomColor || formState.originalCustomColor != null) ...[
              const Spacer(),
              GestureDetector(
                onTap: () {
                  ref.read(accountFormProvider.notifier).setCustomColorIndex(null);
                },
                child: Text(
                  'Reset to default',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.accentPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ColorPickerGrid(
          colors: accentColors,
          selectedColor: selectedColor ?? accentColors[0],
          crossAxisCount: 8,
          itemSize: 36,
          onColorSelected: (color) {
            final index = accentColors.indexOf(color);
            if (index != -1) {
              ref.read(accountFormProvider.notifier).setCustomColorIndex(index);
            }
          },
        ),
      ],
    );
  }
}
