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
import '../../data/models/asset_category.dart';
import '../providers/asset_categories_provider.dart';
import '../widgets/asset_category_form_modal.dart';

class AssetCategoriesScreen extends ConsumerWidget {
  const AssetCategoriesScreen({super.key});

  void _openCreateModal(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AssetCategoryFormModal(
          onSave: (name, icon, colorIndex) async {
            await ref.read(assetCategoriesProvider.notifier).addCategory(
              name: name,
              icon: icon,
              colorIndex: colorIndex,
            );
            if (context.mounted) {
              Navigator.of(context).pop();
              context.showSuccessNotification('Category created');
            }
          },
        ),
      ),
    );
  }

  void _openEditModal(BuildContext context, WidgetRef ref, AssetCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AssetCategoryFormModal(
          category: category,
          onSave: (name, icon, colorIndex) async {
            final updated = category.copyWith(
              name: name,
              icon: icon,
              colorIndex: colorIndex,
            );
            await ref.read(assetCategoriesProvider.notifier).updateCategory(updated);
            if (context.mounted) {
              Navigator.of(context).pop();
              context.showSuccessNotification('Category updated');
            }
          },
          onDelete: () async {
            await ref.read(assetCategoriesProvider.notifier).deleteCategory(category.id);
            if (context.mounted) {
              Navigator.of(context).pop();
              context.showSuccessNotification('Category deleted');
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(assetCategoriesProvider);
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
                    child: Text('Asset Categories', style: AppTypography.h2),
                  ),
                  GestureDetector(
                    onTap: () => _openCreateModal(context, ref),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppRadius.iconButton,
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
            Expanded(
              child: categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return EmptyState.centered(
                      icon: LucideIcons.layoutGrid,
                      title: 'No categories yet',
                      subtitle: 'Add categories to organize your assets',
                    );
                  }
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
                      final category = categories[oldIndex];
                      ref.read(assetCategoriesProvider.notifier).moveCategoryToPosition(category.id, newIndex);
                    },
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return KeyedSubtree(
                        key: ValueKey(category.id),
                        child: _CategoryCard(
                          category: category,
                          intensity: intensity,
                          onTap: () => _openEditModal(context, ref, category),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: LoadingIndicator()),
                error: (error, _) => Center(
                  child: Text('Error loading categories', style: AppTypography.bodyMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final AssetCategory category;
  final ColorIntensity intensity;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.intensity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = category.getColor(intensity);
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
            Icon(
              LucideIcons.gripVertical,
              size: 16,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: bgOpacity),
                borderRadius: AppRadius.iconButton,
              ),
              child: Icon(
                category.icon,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                category.name,
                style: AppTypography.labelMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
