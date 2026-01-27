import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/async_value_extensions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/data/models/category_tree_node.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../providers/settings_provider.dart';
import 'category_form_modal.dart';

/// A modal picker for selecting a category with hierarchy support.
class CategoryPickerModal extends ConsumerStatefulWidget {
  final String? selectedCategoryId;
  final ValueChanged<String> onSelected;

  const CategoryPickerModal({
    super.key,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  @override
  ConsumerState<CategoryPickerModal> createState() => _CategoryPickerModalState();
}

class _CategoryPickerModalState extends ConsumerState<CategoryPickerModal> {
  final Set<String> _expandedIds = {};

  List<CategoryTreeNode> _buildVisibleNodes(List<CategoryTreeNode> tree) {
    final result = <CategoryTreeNode>[];

    void addWithChildren(CategoryTreeNode node) {
      result.add(node);
      if (_expandedIds.contains(node.category.id)) {
        for (final child in node.children) {
          addWithChildren(child);
        }
      }
    }

    for (final node in tree) {
      addWithChildren(node);
    }

    return result;
  }

  bool _hasChildren(CategoryTreeNode node) {
    return node.children.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final intensity = ref.watch(colorIntensityProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.valueOrEmpty;

    // Build trees for both types
    final expenseCategories = categories.where((c) => c.type == CategoryType.expense).toList();
    final incomeCategories = categories.where((c) => c.type == CategoryType.income).toList();
    final expenseTree = CategoryTreeBuilder.buildTree(expenseCategories);
    final incomeTree = CategoryTreeBuilder.buildTree(incomeCategories);

    final expenseNodes = _buildVisibleNodes(expenseTree);
    final incomeNodes = _buildVisibleNodes(incomeTree);

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
                  'Select Category',
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Create new option
                  _buildCreateOption(context),
                  const SizedBox(height: AppSpacing.md),

                  // Expense categories
                  if (expenseNodes.isNotEmpty) ...[
                    _buildSectionHeader('Expense'),
                    const SizedBox(height: AppSpacing.sm),
                    ...expenseNodes.map((node) => _buildCategoryTile(
                      context: context,
                      node: node,
                      intensity: intensity,
                    )),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Income categories
                  if (incomeNodes.isNotEmpty) ...[
                    _buildSectionHeader('Income'),
                    const SizedBox(height: AppSpacing.sm),
                    ...incomeNodes.map((node) => _buildCategoryTile(
                      context: context,
                      node: node,
                      intensity: intensity,
                    )),
                  ],

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.textTertiary,
        letterSpacing: 1.0,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildCreateOption(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // Store callback reference before popping
        final onSelected = widget.onSelected;

        // Get the root navigator before popping
        final navigator = Navigator.of(context, rootNavigator: true);

        // Pop the modal first
        navigator.pop();

        // Navigate to category form in picker mode and wait for result
        final newCategoryId = await navigator.push<String>(
          MaterialPageRoute(
            builder: (context) => _CategoryPickerFormScreen(
              type: CategoryType.expense,
              onCategoryCreated: (id) => Navigator.of(context).pop(id),
            ),
          ),
        );

        // Select the new category if one was created
        if (newCategoryId != null) {
          onSelected(newCategoryId);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 26),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                LucideIcons.plus,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Create New Category',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile({
    required BuildContext context,
    required CategoryTreeNode node,
    required intensity,
  }) {
    final category = node.category;
    final categoryColor = category.getColor(intensity);
    final bgOpacity = AppColors.getBgOpacity(intensity);
    final isSelected = widget.selectedCategoryId == category.id;
    final indentation = node.depth * 24.0;
    final hasChildren = _hasChildren(node);
    final isExpanded = _expandedIds.contains(category.id);

    return Padding(
      padding: EdgeInsets.only(
        left: indentation,
        bottom: AppSpacing.sm,
      ),
      child: GestureDetector(
        onTap: () {
          widget.onSelected(category.id);
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? categoryColor.withValues(alpha: 0.1)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? categoryColor : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Expand/collapse button
              if (hasChildren)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedIds.remove(category.id);
                      } else {
                        _expandedIds.add(category.id);
                      }
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 26),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: bgOpacity),
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
      ),
    );
  }
}

void showCategoryPickerModal({
  required BuildContext context,
  required String? selectedCategoryId,
  required ValueChanged<String> onSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => GestureDetector(
      onTap: () => Navigator.pop(ctx),
      behavior: HitTestBehavior.opaque,
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => GestureDetector(
          onTap: () {}, // Prevent tap from propagating to parent
          child: CategoryPickerModal(
            selectedCategoryId: selectedCategoryId,
            onSelected: onSelected,
          ),
        ),
      ),
    ),
  );
}

/// A screen that wraps CategoryFormModal for picker mode.
/// Returns the new category ID when created.
class _CategoryPickerFormScreen extends ConsumerWidget {
  final CategoryType type;
  final ValueChanged<String> onCategoryCreated;

  const _CategoryPickerFormScreen({
    required this.type,
    required this.onCategoryCreated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CategoryFormModal(
      type: type,
      onSave: (name, icon, colorIndex, parentId) async {
        final uuid = const Uuid();
        final newId = uuid.v4();

        final category = Category(
          id: newId,
          name: name,
          icon: icon,
          colorIndex: colorIndex,
          type: type,
          parentId: parentId,
          isCustom: true,
          sortOrder: 0,
        );

        await ref.read(categoriesProvider.notifier).addCategory(category);
        onCategoryCreated(newId);
      },
    );
  }
}
