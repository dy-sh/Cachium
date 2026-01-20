import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/data/models/category_tree_node.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../providers/settings_provider.dart';

class ParentCategoryPicker extends ConsumerWidget {
  final CategoryType type;
  final String? currentCategoryId;
  final String? selectedParentId;
  final ValueChanged<String?> onSelected;

  const ParentCategoryPicker({
    super.key,
    required this.type,
    this.currentCategoryId,
    required this.selectedParentId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intensity = ref.watch(colorIntensityProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? [];
    final filteredCategories = categories.where((c) => c.type == type).toList();
    final treeNodes = CategoryTreeBuilder.buildFlatTree(filteredCategories);

    final excludedIds = <String>{};
    if (currentCategoryId != null) {
      excludedIds.add(currentCategoryId!);
      excludedIds.addAll(
        CategoryTreeBuilder.getDescendantIds(categories, currentCategoryId!),
      );
    }

    final selectableNodes = treeNodes
        .where((node) => !excludedIds.contains(node.category.id))
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
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
                Text(
                  'Select Parent Category',
                  style: AppTypography.h4,
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
              ),
              child: Column(
                children: [
                  // None option (root level)
                  _buildOptionTile(
                    context: context,
                    label: '(None - Root Level)',
                    isSelected: selectedParentId == null,
                    onTap: () {
                      onSelected(null);
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Category tree
                  ...selectableNodes.map((node) {
                    final category = node.category;
                    final categoryColor = category.getColor(intensity);
                    final bgOpacity = AppColors.getBgOpacity(intensity);
                    final isSelected = selectedParentId == category.id;
                    final indentation = node.depth * 24.0;

                    return Padding(
                      padding: EdgeInsets.only(
                        left: indentation,
                        bottom: AppSpacing.sm,
                      ),
                      child: _buildCategoryOptionTile(
                        context: context,
                        category: category,
                        categoryColor: categoryColor,
                        bgOpacity: bgOpacity,
                        isSelected: isSelected,
                        onTap: () {
                          onSelected(category.id);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  }),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentPrimary.withOpacity(0.1)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accentPrimary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                LucideIcons.folderRoot,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: isSelected
                      ? AppColors.accentPrimary
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                LucideIcons.check,
                size: 18,
                color: AppColors.accentPrimary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryOptionTile({
    required BuildContext context,
    required Category category,
    required Color categoryColor,
    required double bgOpacity,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? categoryColor.withOpacity(0.1)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? categoryColor : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(bgOpacity),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                category.icon,
                size: 20,
                color: categoryColor,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                category.name,
                style: AppTypography.bodyMedium.copyWith(
                  color: isSelected ? categoryColor : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                LucideIcons.check,
                size: 18,
                color: categoryColor,
              ),
          ],
        ),
      ),
    );
  }
}

void showParentCategoryPicker({
  required BuildContext context,
  required CategoryType type,
  String? currentCategoryId,
  required String? selectedParentId,
  required ValueChanged<String?> onSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, scrollController) => ParentCategoryPicker(
        type: type,
        currentCategoryId: currentCategoryId,
        selectedParentId: selectedParentId,
        onSelected: onSelected,
      ),
    ),
  );
}
