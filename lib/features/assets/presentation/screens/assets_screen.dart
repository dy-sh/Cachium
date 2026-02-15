import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../design_system/design_system.dart';
import '../../../settings/data/models/app_settings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/asset.dart';
import '../providers/assets_provider.dart';

enum _AssetFilter { all, active, sold }

class AssetsScreen extends ConsumerStatefulWidget {
  const AssetsScreen({super.key});

  @override
  ConsumerState<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends ConsumerState<AssetsScreen> {
  _AssetFilter _filter = _AssetFilter.all;
  AssetSortOption _sortOption = AssetSortOption.lastUsed;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(assetsProvider);
    final intensity = ref.watch(colorIntensityProvider);
    final recentAssetIds = ref.watch(recentlyUsedAssetIdsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Row(
                children: [
                  IconBtn(
                    icon: LucideIcons.arrowLeft,
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text('Assets', style: AppTypography.h2),
                  ),
                  GestureDetector(
                    onTap: () => _showSortPicker(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        LucideIcons.arrowUpDown,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: () => context.push('/asset/new'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        LucideIcons.plus,
                        color: ref.watch(accentColorProvider),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: ToggleChip(
                options: const ['All', 'Active', 'Sold'],
                selectedIndex: _filter.index,
                onChanged: (index) {
                  setState(() => _filter = _AssetFilter.values[index]);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: InputField(
                controller: _searchController,
                hint: 'Search assets...',
                prefix: Icon(LucideIcons.search, size: 16, color: AppColors.textSecondary),
                suffix: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: Icon(LucideIcons.x, size: 16, color: AppColors.textSecondary),
                      )
                    : null,
                showClearButton: false,
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: assetsAsync.when(
                data: (assets) {
                  final filtered = _filterAndSortAssets(assets, recentAssetIds);
                  if (filtered.isEmpty) {
                    return Center(
                      child: EmptyState(
                        icon: LucideIcons.box,
                        title: assets.isEmpty ? 'No assets yet' : 'No matching assets',
                        subtitle: assets.isEmpty
                            ? 'Track your physical assets and their total cost'
                            : 'Try a different filter or search',
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _AssetCard(
                      asset: filtered[index],
                      intensity: intensity,
                      onTap: () => context.push('/asset/${filtered[index].id}'),
                    ),
                  );
                },
                loading: () => const Center(child: LoadingIndicator()),
                error: (error, _) => Center(
                  child: Text('Error loading assets', style: AppTypography.bodyMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Asset> _filterAndSortAssets(List<Asset> assets, List<String> recentAssetIds) {
    // Filter by status
    var filtered = switch (_filter) {
      _AssetFilter.all => assets,
      _AssetFilter.active => assets.where((a) => a.status == AssetStatus.active).toList(),
      _AssetFilter.sold => assets.where((a) => a.status == AssetStatus.sold).toList(),
    };

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((a) =>
          a.name.toLowerCase().contains(_searchQuery) ||
          (a.note?.toLowerCase().contains(_searchQuery) ?? false)).toList();
    }

    // Sort
    final sorted = List<Asset>.from(filtered);
    switch (_sortOption) {
      case AssetSortOption.lastUsed:
        final idOrder = {for (int i = 0; i < recentAssetIds.length; i++) recentAssetIds[i]: i};
        sorted.sort((a, b) {
          final aIdx = idOrder[a.id];
          final bIdx = idOrder[b.id];
          if (aIdx != null && bIdx != null) return aIdx.compareTo(bIdx);
          if (aIdx != null) return -1;
          if (bIdx != null) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });
      case AssetSortOption.alphabetical:
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case AssetSortOption.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return sorted;
  }

  void _showSortPicker(BuildContext context) {
    final animationsEnabled = ref.read(formAnimationsEnabledProvider);
    final options = AssetSortOption.values.map((e) => e.displayName).toList();
    final selectedIndex = AssetSortOption.values.indexOf(_sortOption);
    final modalContent = _SortPickerSheet(
      options: options,
      selectedIndex: selectedIndex,
      onSelected: (index) {
        setState(() => _sortOption = AssetSortOption.values[index]);
        Navigator.pop(context);
      },
    );

    if (!animationsEnabled) {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: modalContent,
              ),
            );
          },
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => modalContent,
      );
    }
  }
}

class _SortPickerSheet extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _SortPickerSheet({
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Sort By', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.lg),
            ...List.generate(options.length, (index) {
              final isSelected = index == selectedIndex;
              return GestureDetector(
                onTap: () => onSelected(index),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          options[index],
                          style: AppTypography.bodyMedium.copyWith(
                            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          LucideIcons.check,
                          size: 18,
                          color: AppColors.textPrimary,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _AssetCard extends ConsumerWidget {
  final Asset asset;
  final ColorIntensity intensity;
  final VoidCallback onTap;

  const _AssetCard({
    required this.asset,
    required this.intensity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = asset.getColor(intensity);
    final bgOpacity = AppColors.getBgOpacity(intensity);
    final netCost = ref.watch(assetNetCostProvider(asset.id));
    final txCount = ref.watch(assetTransactionCountProvider(asset.id));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: bgOpacity),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                asset.icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asset.name,
                    style: AppTypography.labelMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        CurrencyFormatter.format(netCost.abs()),
                        style: AppTypography.bodySmall.copyWith(
                          color: netCost > 0
                              ? AppColors.getTransactionColor('expense', intensity)
                              : AppColors.getTransactionColor('income', intensity),
                        ),
                      ),
                      Text(
                        ' net cost',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      if (txCount > 0) ...[
                        Text(
                          '  \u00B7  $txCount txn${txCount != 1 ? 's' : ''}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: asset.status.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                asset.status.displayName,
                style: AppTypography.labelSmall.copyWith(
                  color: asset.status.color,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
