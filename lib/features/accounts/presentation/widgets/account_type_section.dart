import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/account.dart';
import '../providers/account_form_provider.dart';

class AccountTypeSection extends ConsumerWidget {
  final AccountFormState formState;

  const AccountTypeSection({super.key, required this.formState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intensity = ref.watch(colorIntensityProvider);
    final accentColors = AppColors.getAccentOptions(intensity);
    Color? customColor;
    if (formState.customColorIndex != null) {
      customColor = accentColors[formState.customColorIndex!.clamp(0, accentColors.length - 1)];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account Type', style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.md),
        AccountTypeGrid(
          selectedType: formState.type,
          customColor: customColor,
          onChanged: (type) {
            ref.read(accountFormProvider.notifier).setType(type);
          },
        ),
      ],
    );
  }
}

class AccountTypeGrid extends ConsumerWidget {
  final AccountType? selectedType;
  final ValueChanged<AccountType> onChanged;
  final Color? customColor;

  const AccountTypeGrid({
    super.key,
    this.selectedType,
    required this.onChanged,
    this.customColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intensity = ref.watch(colorIntensityProvider);
    final bgOpacity = AppColors.getBgOpacity(intensity);

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2.2,
      children: AccountType.values.map((type) {
        final isSelected = type == selectedType;
        final defaultTypeColor = AppColors.getAccountColor(type.name, intensity);
        final displayColor = isSelected && customColor != null
            ? customColor!
            : defaultTypeColor;
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: AppAnimations.normal,
            decoration: BoxDecoration(
              color: isSelected
                  ? displayColor.withValues(alpha: bgOpacity)
                  : AppColors.surface,
              borderRadius: AppRadius.mdAll,
              border: Border.all(
                color: isSelected ? displayColor : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type.icon,
                  color: isSelected ? displayColor : AppColors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  type.displayName,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? displayColor : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
