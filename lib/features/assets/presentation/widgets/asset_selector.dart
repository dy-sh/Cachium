import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/animations/haptic_helper.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/design_system.dart';
import '../../../settings/data/models/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/asset.dart';

/// A widget for optionally selecting an asset from a grid.
/// Shows active assets with a "None" option and a "Create New" button.
class AssetSelector extends ConsumerWidget {
  final List<Asset> assets;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final VoidCallback? onCreatePressed;

  const AssetSelector({
    super.key,
    required this.assets,
    this.selectedId,
    required this.onChanged,
    this.onCreatePressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intensity = ref.watch(colorIntensityProvider);

    if (assets.isEmpty && onCreatePressed == null) {
      return const SizedBox.shrink();
    }

    final gridItems = <Widget>[];

    // "None" card
    gridItems.add(_NoneCard(
      isSelected: selectedId == null,
      onTap: () {
        HapticHelper.lightImpact();
        onChanged(null);
      },
    ));

    // Asset cards
    for (final asset in assets) {
      gridItems.add(_AssetCard(
        asset: asset,
        isSelected: asset.id == selectedId,
        intensity: intensity,
        onTap: () {
          HapticHelper.lightImpact();
          onChanged(asset.id);
        },
      ));
    }

    // Create new card
    if (onCreatePressed != null) {
      gridItems.add(_CreateNewCard(onTap: onCreatePressed!));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.2,
        crossAxisSpacing: AppSpacing.chipGap,
        mainAxisSpacing: AppSpacing.chipGap,
      ),
      itemCount: gridItems.length,
      itemBuilder: (context, index) => gridItems[index],
    );
  }
}

class _NoneCard extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _NoneCard({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.textSecondary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.textSecondary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                LucideIcons.circleOff,
                size: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'None',
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  final Asset asset;
  final bool isSelected;
  final ColorIntensity intensity;
  final VoidCallback onTap;

  const _AssetCard({
    required this.asset,
    required this.isSelected,
    required this.intensity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final assetColor = asset.getColor(intensity);
    final bgOpacity = AppColors.getBgOpacity(intensity);

    return SelectableCard(
      isSelected: isSelected,
      color: assetColor,
      bgOpacity: bgOpacity,
      icon: asset.icon,
      onTap: onTap,
      unselectedIconBgColor: assetColor.withValues(alpha: 0.6),
      unselectedIconColor: AppColors.background,
      selectedIconColor: AppColors.background,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            asset.name,
            style: AppTypography.labelSmall.copyWith(
              color: isSelected ? assetColor : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CreateNewCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateNewCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.textTertiary.withValues(alpha: 0.3),
            width: 1,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.plus,
              size: 16,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              'New Asset',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
