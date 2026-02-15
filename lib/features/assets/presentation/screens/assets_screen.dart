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
import '../widgets/asset_form_modal.dart';

enum _AssetTab { active, sold }

class AssetsScreen extends ConsumerStatefulWidget {
  const AssetsScreen({super.key});

  @override
  ConsumerState<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends ConsumerState<AssetsScreen> {
  _AssetTab _tab = _AssetTab.active;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateModal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AssetFormModal(
          onSave: (name, icon, colorIndex, status, note) async {
            await ref.read(assetsProvider.notifier).addAsset(
              name: name,
              icon: icon,
              colorIndex: colorIndex,
              note: note,
            );
            if (context.mounted) {
              Navigator.of(context).pop();
              context.showSuccessNotification('Asset created');
            }
          },
        ),
      ),
    );
  }

  void _openEditModal(Asset asset) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AssetFormModal(
          asset: asset,
          onSave: (name, icon, colorIndex, status, note) async {
            final updatedAsset = asset.copyWith(
              name: name,
              icon: icon,
              colorIndex: colorIndex,
              status: status,
              note: note,
              clearNote: note == null,
            );
            await ref.read(assetsProvider.notifier).updateAsset(updatedAsset);
            if (context.mounted) {
              Navigator.of(context).pop();
              context.showSuccessNotification('Asset updated');
            }
          },
          onDelete: () async {
            await ref.read(assetsProvider.notifier).deleteAsset(asset.id);
            if (context.mounted) {
              Navigator.of(context).pop();
              context.showSuccessNotification('Asset deleted');
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(assetsProvider);
    final intensity = ref.watch(colorIntensityProvider);

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
                    onTap: _openCreateModal,
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
                options: const ['Active', 'Sold'],
                selectedIndex: _tab.index,
                onChanged: (index) {
                  setState(() => _tab = _AssetTab.values[index]);
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
                  final filtered = _filterAssets(assets);
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
                  return _buildAssetList(filtered, assets, intensity);
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

  List<Asset> _filterAssets(List<Asset> assets) {
    // Filter by status tab
    var filtered = switch (_tab) {
      _AssetTab.active => assets.where((a) => a.status == AssetStatus.active).toList(),
      _AssetTab.sold => assets.where((a) => a.status == AssetStatus.sold).toList(),
    };

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((a) =>
          a.name.toLowerCase().contains(_searchQuery) ||
          (a.note?.toLowerCase().contains(_searchQuery) ?? false)).toList();
    }

    return filtered;
  }

  Widget _buildAssetList(List<Asset> filtered, List<Asset> allAssets, ColorIntensity intensity) {
    // Only allow reordering on the Active tab with no search query
    final canReorder = _tab == _AssetTab.active && _searchQuery.isEmpty;

    if (canReorder) {
      return ReorderableListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) => Material(
              color: Colors.transparent,
              elevation: 0,
              child: child,
            ),
            child: child,
          );
        },
        onReorder: (oldIndex, newIndex) {
          if (oldIndex < newIndex) newIndex--;
          final asset = filtered[oldIndex];
          // Calculate the new index in the full assets list
          ref.read(assetsProvider.notifier).moveAssetToPosition(asset.id, newIndex);
        },
        itemCount: filtered.length + 1, // +1 for add tile
        itemBuilder: (context, index) {
          if (index == filtered.length) {
            return KeyedSubtree(
              key: const ValueKey('add_asset_tile'),
              child: _buildAddAssetTile(),
            );
          }
          final asset = filtered[index];
          return KeyedSubtree(
            key: ValueKey(asset.id),
            child: _AssetCard(
              asset: asset,
              intensity: intensity,
              onTap: () => _openEditModal(asset),
              onDetailTap: () => context.push('/asset/${asset.id}'),
              showDragHandle: true,
            ),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      itemCount: filtered.length + (_tab == _AssetTab.active ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filtered.length) {
          return _buildAddAssetTile();
        }
        final asset = filtered[index];
        return _AssetCard(
          asset: asset,
          intensity: intensity,
          onTap: () => _openEditModal(asset),
          onDetailTap: () => context.push('/asset/${asset.id}'),
          showDragHandle: false,
        );
      },
    );
  }

  Widget _buildAddAssetTile() {
    return GestureDetector(
      onTap: _openCreateModal,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xxl),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.plus,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Add Asset',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
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
  final VoidCallback onDetailTap;
  final bool showDragHandle;

  const _AssetCard({
    required this.asset,
    required this.intensity,
    required this.onTap,
    required this.onDetailTap,
    this.showDragHandle = false,
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
            if (showDragHandle) ...[
              Icon(
                LucideIcons.gripVertical,
                size: 16,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
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
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: onDetailTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
