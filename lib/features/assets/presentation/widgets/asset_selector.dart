import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/animations/haptic_helper.dart';
import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/design_system.dart';
import '../../../settings/data/models/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/asset.dart';

/// A widget for optionally selecting an asset from a 3-column grid.
/// Shows active assets with a "None" option, search, expand/collapse, and sorting.
class AssetSelector extends ConsumerStatefulWidget {
  final List<Asset> assets;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final VoidCallback? onCreatePressed;
  final List<String>? recentAssetIds;
  final int initialVisibleCount;
  final AssetSortOption sortOption;

  const AssetSelector({
    super.key,
    required this.assets,
    this.selectedId,
    required this.onChanged,
    this.onCreatePressed,
    this.recentAssetIds,
    this.initialVisibleCount = 5,
    this.sortOption = AssetSortOption.lastUsed,
  });

  @override
  ConsumerState<AssetSelector> createState() => _AssetSelectorState();
}

class _AssetSelectorState extends ConsumerState<AssetSelector> {
  bool _showAll = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch({bool collapse = false}) {
    _searchController.clear();
    _searchQuery = '';
    _searchFocusNode.unfocus();
    if (collapse) {
      _showAll = false;
    }
  }

  List<Asset> _getSortedAssets() {
    final assets = widget.assets;

    switch (widget.sortOption) {
      case AssetSortOption.lastUsed:
        if (widget.recentAssetIds == null || widget.recentAssetIds!.isEmpty) {
          return assets;
        }
        final assetMap = {for (var a in assets) a.id: a};
        final sorted = <Asset>[];
        final addedIds = <String>{};
        for (final id in widget.recentAssetIds!) {
          final asset = assetMap[id];
          if (asset != null && !addedIds.contains(id)) {
            sorted.add(asset);
            addedIds.add(id);
          }
        }
        for (final asset in assets) {
          if (!addedIds.contains(asset.id)) {
            sorted.add(asset);
          }
        }
        return sorted;
      case AssetSortOption.alphabetical:
        final sorted = List<Asset>.from(assets);
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return sorted;
      case AssetSortOption.newest:
        final sorted = List<Asset>.from(assets);
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return sorted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final intensity = ref.watch(colorIntensityProvider);

    if (widget.assets.isEmpty && widget.onCreatePressed == null) {
      return const SizedBox.shrink();
    }

    final sortedAssets = _getSortedAssets();
    final filteredAssets = _searchQuery.isEmpty
        ? sortedAssets
        : sortedAssets.where((a) =>
            a.name.toLowerCase().contains(_searchQuery) ||
            (a.note?.toLowerCase().contains(_searchQuery) ?? false)).toList();
    // +1 for the "None" card when counting visible items
    final hasMore = (sortedAssets.length + 1) > widget.initialVisibleCount;

    final List<_GridItem> gridItems = [];

    if (_showAll || !hasMore) {
      // None card first
      gridItems.add(_GridItem.none());
      // All assets (filtered when searching)
      for (final asset in filteredAssets) {
        gridItems.add(_GridItem.asset(asset));
      }
      if (widget.onCreatePressed != null) {
        gridItems.add(_GridItem.create());
      }
    } else {
      // None card first
      gridItems.add(_GridItem.none());
      // Limited assets + "More" button
      final visibleCount = widget.initialVisibleCount - 1; // -1 for None card
      for (int i = 0; i < visibleCount && i < sortedAssets.length; i++) {
        gridItems.add(_GridItem.asset(sortedAssets[i]));
      }
      if (sortedAssets.length > visibleCount) {
        gridItems.add(_GridItem.more(sortedAssets.length - visibleCount));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_showAll) ...[
          InputField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            hint: 'Search assets...',
            prefix: Icon(LucideIcons.search, size: 16, color: AppColors.textSecondary),
            suffix: GestureDetector(
              onTap: () => setState(() => _clearSearch(collapse: true)),
              child: Icon(LucideIcons.x, size: 16, color: AppColors.textSecondary),
            ),
            showClearButton: false,
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        AnimatedSize(
          duration: AppAnimations.slow,
          curve: AppAnimations.defaultCurve,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.4,
              crossAxisSpacing: AppSpacing.chipGap,
              mainAxisSpacing: AppSpacing.chipGap,
            ),
            itemCount: gridItems.length,
            itemBuilder: (context, index) {
              final item = gridItems[index];
              switch (item.type) {
                case _GridItemType.none:
                  return _NoneCard(
                    isSelected: widget.selectedId == null,
                    onTap: () {
                      HapticHelper.lightImpact();
                      widget.onChanged(null);
                      setState(_clearSearch);
                    },
                  );
                case _GridItemType.asset:
                  final asset = item.asset!;
                  return _AssetCard(
                    asset: asset,
                    isSelected: asset.id == widget.selectedId,
                    intensity: intensity,
                    onTap: () {
                      HapticHelper.lightImpact();
                      widget.onChanged(asset.id);
                      setState(_clearSearch);
                    },
                  );
                case _GridItemType.more:
                  return _MoreChip(
                    count: item.moreCount!,
                    onTap: () => setState(() => _showAll = true),
                  );
                case _GridItemType.create:
                  return _CreateNewCard(onTap: widget.onCreatePressed!);
              }
            },
          ),
        ),
        if (_showAll && hasMore) ...[
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () => setState(() {
              _showAll = false;
              _clearSearch();
            }),
            child: Text(
              'Show Less',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.accentPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

enum _GridItemType { none, asset, more, create }

class _GridItem {
  final _GridItemType type;
  final Asset? asset;
  final int? moreCount;

  _GridItem._({required this.type, this.asset, this.moreCount});

  factory _GridItem.none() => _GridItem._(type: _GridItemType.none);
  factory _GridItem.asset(Asset asset) => _GridItem._(type: _GridItemType.asset, asset: asset);
  factory _GridItem.more(int count) => _GridItem._(type: _GridItemType.more, moreCount: count);
  factory _GridItem.create() => _GridItem._(type: _GridItemType.create);
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
          borderRadius: AppRadius.smAll,
          border: Border.all(
            color: isSelected ? AppColors.textSecondary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(
                LucideIcons.circleOff,
                size: 10,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
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
      content: Text(
        asset.name,
        style: AppTypography.labelSmall.copyWith(
          color: isSelected ? assetColor : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _MoreChip extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _MoreChip({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticHelper.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.smAll,
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(
                LucideIcons.moreHorizontal,
                size: 10,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '+$count',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
          borderRadius: AppRadius.smAll,
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
              size: 14,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              'New',
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
