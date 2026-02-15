import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
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
            const SizedBox(height: AppSpacing.xl),
            Expanded(
              child: assetsAsync.when(
                data: (assets) {
                  final filtered = _filterAssets(assets);
                  if (filtered.isEmpty) {
                    return Center(
                      child: EmptyState(
                        icon: LucideIcons.box,
                        title: assets.isEmpty ? 'No assets yet' : 'No ${_filter.name} assets',
                        subtitle: assets.isEmpty
                            ? 'Track your physical assets and their total cost'
                            : 'Try a different filter',
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

  List<Asset> _filterAssets(List<Asset> assets) {
    switch (_filter) {
      case _AssetFilter.all:
        return assets;
      case _AssetFilter.active:
        return assets.where((a) => a.status == AssetStatus.active).toList();
      case _AssetFilter.sold:
        return assets.where((a) => a.status == AssetStatus.sold).toList();
    }
  }
}

class _AssetCard extends StatelessWidget {
  final Asset asset;
  final ColorIntensity intensity;
  final VoidCallback onTap;

  const _AssetCard({
    required this.asset,
    required this.intensity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = asset.getColor(intensity);
    final bgOpacity = AppColors.getBgOpacity(intensity);

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
                  if (asset.note != null && asset.note!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      asset.note!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
