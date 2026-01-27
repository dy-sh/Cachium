import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/async_value_extensions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/buttons/primary_button.dart';
import '../../../../design_system/components/layout/form_header.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/data/models/category_tree_node.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/models/app_settings.dart';
import '../providers/settings_provider.dart';
import 'category_form_modal.dart';

/// Represents the user's decision for a single category's transactions
class CategoryTransactionDecision {
  final String categoryId;
  final String? targetCategoryId; // null = delete transactions

  const CategoryTransactionDecision({
    required this.categoryId,
    this.targetCategoryId,
  });
}

/// Shows a screen for reassigning transactions from multiple categories being deleted
Future<List<CategoryTransactionDecision>?> showCategoryTransactionsReassignDialog({
  required BuildContext context,
  required List<Category> categoriesToDelete,
  required CategoryType categoryType,
}) {
  return Navigator.of(context).push<List<CategoryTransactionDecision>>(
    MaterialPageRoute(
      builder: (context) => CategoryTransactionsReassignScreen(
        categoriesToDelete: categoriesToDelete,
        categoryType: categoryType,
      ),
    ),
  );
}

class CategoryTransactionsReassignScreen extends ConsumerStatefulWidget {
  final List<Category> categoriesToDelete;
  final CategoryType categoryType;

  const CategoryTransactionsReassignScreen({
    super.key,
    required this.categoriesToDelete,
    required this.categoryType,
  });

  @override
  ConsumerState<CategoryTransactionsReassignScreen> createState() =>
      _CategoryTransactionsReassignScreenState();
}

class _CategoryTransactionsReassignScreenState
    extends ConsumerState<CategoryTransactionsReassignScreen> {
  final _uuid = const Uuid();
  // Maps categoryId -> targetCategoryId (null means "delete transactions", empty string means "not selected")
  final Map<String, String?> _decisions = {};

  @override
  void initState() {
    super.initState();
    // Initialize all decisions as empty (not selected)
    for (final category in widget.categoriesToDelete) {
      _decisions[category.id] = ''; // Empty string = not selected
    }
  }

  bool get _allDecisionsMade {
    return _decisions.values.every((decision) => decision != '');
  }

  List<Category> _getAvailableCategories() {
    final allCategories = ref.read(categoriesProvider).valueOrEmpty;
    final deletingIds = widget.categoriesToDelete.map((c) => c.id).toSet();

    return allCategories
        .where((c) =>
            c.type == widget.categoryType && !deletingIds.contains(c.id))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  void _showCreateCategoryModal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryFormModal(
          type: widget.categoryType,
          onSave: (name, icon, colorIndex, parentId) {
            final categories = ref.read(categoriesProvider).valueOrEmpty;
            final siblings = categories
                .where(
                    (c) => c.parentId == parentId && c.type == widget.categoryType)
                .toList();
            final sortOrder = siblings.isEmpty
                ? 0
                : siblings.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) +
                    1;

            final category = Category(
              id: _uuid.v4(),
              name: name,
              icon: icon,
              colorIndex: colorIndex,
              type: widget.categoryType,
              isCustom: true,
              parentId: parentId,
              sortOrder: sortOrder,
            );
            ref.read(categoriesProvider.notifier).addCategory(category);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _confirm() {
    final decisions = _decisions.entries.map((entry) {
      return CategoryTransactionDecision(
        categoryId: entry.key,
        targetCategoryId: entry.value,
      );
    }).toList();

    Navigator.pop(context, decisions);
  }

  @override
  Widget build(BuildContext context) {
    final intensity = ref.watch(colorIntensityProvider);
    // Watch categories to get reactive updates when new categories are created
    ref.watch(categoriesProvider);
    final availableCategories = _getAvailableCategories();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            FormHeader(
              title: 'Reassign Transactions',
              onClose: () => Navigator.pop(context, null),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The following categories have transactions. Choose where to move them or delete:',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Category rows
                    ...widget.categoriesToDelete.map((category) {
                      final txCount =
                          ref.watch(transactionCountByCategoryProvider(category.id));
                      return _CategoryReassignRow(
                        category: category,
                        transactionCount: txCount,
                        intensity: intensity,
                        availableCategories: availableCategories,
                        selectedTargetId: _decisions[category.id],
                        onTargetSelected: (targetId) {
                          setState(() {
                            _decisions[category.id] = targetId;
                          });
                        },
                      );
                    }),

                    const SizedBox(height: AppSpacing.lg),

                    // Create new category button
                    GestureDetector(
                      onTap: _showCreateCategoryModal,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.plus,
                              size: 18,
                              color: ref.watch(accentColorProvider),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Create New Category',
                              style: AppTypography.bodyMedium.copyWith(
                                color: ref.watch(accentColorProvider),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.8),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.only(
                    left: AppSpacing.screenPadding,
                    right: AppSpacing.screenPadding,
                    top: AppSpacing.md,
                    bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context, null),
                          child: Container(
                            height: AppSpacing.buttonHeight,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: AppTypography.button.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Confirm',
                          onPressed: _allDecisionsMade ? _confirm : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryReassignRow extends ConsumerStatefulWidget {
  final Category category;
  final int transactionCount;
  final ColorIntensity intensity;
  final List<Category> availableCategories;
  final String? selectedTargetId; // null = delete, empty = not selected, id = move to
  final ValueChanged<String?> onTargetSelected;

  const _CategoryReassignRow({
    required this.category,
    required this.transactionCount,
    required this.intensity,
    required this.availableCategories,
    required this.selectedTargetId,
    required this.onTargetSelected,
  });

  @override
  ConsumerState<_CategoryReassignRow> createState() => _CategoryReassignRowState();
}

class _CategoryReassignRowState extends ConsumerState<_CategoryReassignRow> {
  final _dropdownKey = GlobalKey<CategoryDropdownState>();

  @override
  Widget build(BuildContext context) {
    final categoryColor = widget.category.getColor(widget.intensity);
    final bgOpacity = AppColors.getBgOpacity(widget.intensity);
    final txText = widget.transactionCount == 1 ? 'transaction' : 'transactions';
    final isDeleteSelected = widget.selectedTargetId == null;
    final isMoveSelected = widget.selectedTargetId != null && widget.selectedTargetId!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category info row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: bgOpacity),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.category.icon,
                  size: 20,
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.category.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${widget.transactionCount} $txText',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Option 1: Move to another category
          GestureDetector(
            onTap: () {
              // Show category picker when clicking "Move to"
              if (widget.availableCategories.isNotEmpty) {
                _dropdownKey.currentState?.showPicker();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isMoveSelected
                    ? ref.watch(accentColorProvider).withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isMoveSelected
                      ? ref.watch(accentColorProvider).withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  // Radio indicator
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isMoveSelected
                            ? ref.watch(accentColorProvider)
                            : AppColors.textTertiary,
                        width: 2,
                      ),
                    ),
                    child: isMoveSelected
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ref.watch(accentColorProvider),
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    LucideIcons.folderInput,
                    size: 16,
                    color: isMoveSelected
                        ? ref.watch(accentColorProvider)
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Move to:',
                    style: AppTypography.bodySmall.copyWith(
                      color: isMoveSelected
                          ? ref.watch(accentColorProvider)
                          : AppColors.textSecondary,
                      fontWeight: isMoveSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _CategoryDropdown(
                      key: _dropdownKey,
                      categories: widget.availableCategories,
                      selectedCategoryId: isMoveSelected ? widget.selectedTargetId : null,
                      intensity: widget.intensity,
                      onSelected: (categoryId) {
                        widget.onTargetSelected(categoryId);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Option 2: Delete transactions
          GestureDetector(
            onTap: () => widget.onTargetSelected(null),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isDeleteSelected
                    ? AppColors.expense.withValues(alpha: 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDeleteSelected
                      ? AppColors.expense.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  // Radio indicator
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDeleteSelected
                            ? AppColors.expense
                            : AppColors.textTertiary,
                        width: 2,
                      ),
                    ),
                    child: isDeleteSelected
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.expense,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    LucideIcons.trash2,
                    size: 16,
                    color: isDeleteSelected
                        ? AppColors.expense
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Delete transactions permanently',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDeleteSelected
                            ? AppColors.expense
                            : AppColors.textSecondary,
                        fontWeight: isDeleteSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryDropdown extends ConsumerStatefulWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final ColorIntensity intensity;
  final ValueChanged<String> onSelected;

  const _CategoryDropdown({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.intensity,
    required this.onSelected,
  });

  @override
  ConsumerState<_CategoryDropdown> createState() => CategoryDropdownState();
}

class CategoryDropdownState extends ConsumerState<_CategoryDropdown> {
  void showPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CategoryPickerSheet(
        categories: widget.categories,
        selectedCategoryId: widget.selectedCategoryId,
        intensity: widget.intensity,
        onSelected: (categoryId) {
          widget.onSelected(categoryId);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = widget.selectedCategoryId != null
        ? widget.categories.firstWhere(
            (c) => c.id == widget.selectedCategoryId,
            orElse: () => widget.categories.first,
          )
        : null;

    final categoryColor = selectedCategory?.getColor(widget.intensity);
    final bgOpacity = AppColors.getBgOpacity(widget.intensity);

    return GestureDetector(
      onTap: widget.categories.isNotEmpty ? showPicker : null,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selectedCategory != null
              ? categoryColor!.withValues(alpha: bgOpacity * 0.5)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selectedCategory != null
                ? categoryColor!.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            if (selectedCategory != null) ...[
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: categoryColor!.withValues(alpha: bgOpacity),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  selectedCategory.icon,
                  size: 14,
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  selectedCategory.name,
                  style: AppTypography.bodySmall.copyWith(
                    color: categoryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else ...[
              Icon(
                LucideIcons.folderInput,
                size: 16,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  widget.categories.isEmpty
                      ? 'No categories available'
                      : 'Select category',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            Icon(
              LucideIcons.chevronDown,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPickerSheet extends StatefulWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final ColorIntensity intensity;
  final ValueChanged<String> onSelected;

  const _CategoryPickerSheet({
    required this.categories,
    required this.selectedCategoryId,
    required this.intensity,
    required this.onSelected,
  });

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  final Set<String> _expandedIds = {};

  List<CategoryTreeNode> _buildFlatTreeWithVisibility() {
    final tree = CategoryTreeBuilder.buildTree(widget.categories);
    final result = <CategoryTreeNode>[];

    void addWithChildren(CategoryTreeNode node) {
      result.add(node);
      // Only add children if this node is expanded
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

  @override
  Widget build(BuildContext context) {
    final visibleNodes = _buildFlatTreeWithVisibility();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Move to Category',
              style: AppTypography.h4,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: visibleNodes.length,
              itemBuilder: (context, index) {
                final node = visibleNodes[index];
                final category = node.category;
                final isSelected = category.id == widget.selectedCategoryId;
                final categoryColor = category.getColor(widget.intensity);
                final bgOpacity = AppColors.getBgOpacity(widget.intensity);
                final hasChildren = node.hasChildren;
                final isExpanded = _expandedIds.contains(category.id);
                final indentation = node.depth * 24.0;

                return Padding(
                  padding: EdgeInsets.only(left: indentation),
                  child: GestureDetector(
                    onTap: () => widget.onSelected(category.id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? categoryColor.withValues(alpha: bgOpacity)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? categoryColor.withValues(alpha: 0.5)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Expand/collapse button for categories with children
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
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: bgOpacity),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              category.icon,
                              size: 18,
                              color: categoryColor,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              category.name,
                              style: AppTypography.bodyMedium.copyWith(
                                color: isSelected ? categoryColor : AppColors.textPrimary,
                                fontWeight:
                                    isSelected ? FontWeight.w600 : FontWeight.normal,
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
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.md),
        ],
      ),
    );
  }
}
