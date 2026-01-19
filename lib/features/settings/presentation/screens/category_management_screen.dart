import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/buttons/fm_icon_button.dart';
import '../../../../design_system/components/chips/fm_toggle_chip.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/data/models/category_tree_node.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../data/models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../widgets/category_form_modal.dart';
import '../widgets/category_tree_tile.dart';
import '../widgets/category_drop_zone.dart';
import '../widgets/delete_category_dialog.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends ConsumerState<CategoryManagementScreen> {
  int _selectedTypeIndex = 1; // 0 = Income, 1 = Expense
  final Set<String> _expandedIds = {};
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listKey = GlobalKey();
  Offset? _lastDragPosition;
  Timer? _scrollTimer;

  static const _scrollAreaHeight = 80.0;
  static const _scrollSpeed = 5.0;

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startDrag() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _performAutoScroll();
    });
  }

  void _endDrag() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
    _lastDragPosition = null;
  }

  void _updateDragPosition(Offset globalPosition) {
    _lastDragPosition = globalPosition;
  }

  void _performAutoScroll() {
    if (_lastDragPosition == null || !mounted) return;

    final box = _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !_scrollController.hasClients) return;

    final localPosition = box.globalToLocal(_lastDragPosition!);
    final listHeight = box.size.height;

    if (localPosition.dy < _scrollAreaHeight) {
      // Near or above top of list - scroll up
      final intensity = (1 - (localPosition.dy / _scrollAreaHeight)).clamp(0.0, 1.0);
      final offset = _scrollController.offset - (_scrollSpeed * intensity);
      _scrollController.jumpTo(offset.clamp(0.0, _scrollController.position.maxScrollExtent));
    } else if (localPosition.dy > listHeight - _scrollAreaHeight) {
      // Near or below bottom of list - scroll down
      final intensity = (1 - ((listHeight - localPosition.dy) / _scrollAreaHeight)).clamp(0.0, 1.0);
      final offset = _scrollController.offset + (_scrollSpeed * intensity);
      _scrollController.jumpTo(offset.clamp(0.0, _scrollController.position.maxScrollExtent));
    }
  }

  CategoryType get _selectedType =>
      _selectedTypeIndex == 0 ? CategoryType.income : CategoryType.expense;

  @override
  Widget build(BuildContext context) {
    final intensity = ref.watch(colorIntensityProvider);
    final treeNodes = ref.watch(flatCategoryTreeProvider(_selectedType));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerMove: (event) {
          if (_scrollTimer != null) {
            _updateDragPosition(event.position);
          }
        },
        onPointerDown: (event) {
          _lastDragPosition = event.position;
        },
        child: SafeArea(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      FMIconButton(
                        icon: LucideIcons.arrowLeft,
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text('Categories', style: AppTypography.h2),
                      ),
                      GestureDetector(
                        onTap: () => _showAddModal(),
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
                  const SizedBox(height: AppSpacing.xl),
                  // Type toggle
                  Center(
                    child: FMToggleChip(
                      options: const ['Income', 'Expense'],
                      selectedIndex: _selectedTypeIndex,
                      colors: [
                        AppColors.getTransactionColor('income', intensity),
                        AppColors.getTransactionColor('expense', intensity),
                      ],
                      onChanged: (index) {
                        setState(() => _selectedTypeIndex = index);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),

            // Categories tree
            Expanded(
              child: ListView.builder(
                key: _listKey,
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                itemCount: treeNodes.length + 2, // +1 for root drop zone, +1 for add button
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildRootDropZone(intensity);
                  }
                  if (index == treeNodes.length + 1) {
                    return _buildAddCategoryTile();
                  }
                  final node = treeNodes[index - 1];
                  return _buildTreeItem(node, intensity);
                },
              ),
            ),

            // Reorder hint
            _buildReorderHint(),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildReorderHint() {
    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.xs,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.gripVertical,
            size: 12,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: 4),
          Text(
            'Hold to reorder',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRootDropZone(ColorIntensity intensity) {
    return CategoryDropZone(
      label: 'Move to root level',
      intensity: intensity,
      canAccept: (node) => node.category.parentId != null,
      onAccept: (node) {
        ref.read(categoriesProvider.notifier).updateParent(
          node.category.id,
          null,
        );
      },
    );
  }

  Widget _buildTreeItem(CategoryTreeNode node, ColorIntensity intensity) {
    final isExpanded = _expandedIds.contains(node.category.id);
    final shouldShow = _shouldShowNode(node);

    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    return CategoryItemDropTarget(
      targetNode: node,
      canAccept: (dragged, target) {
        if (dragged.category.id == target.category.id) return false;
        if (dragged.category.parentId == target.category.id) return false;
        final descendants = CategoryTreeBuilder.getDescendantIds(
          ref.read(categoriesProvider),
          dragged.category.id,
        );
        if (descendants.contains(target.category.id)) return false;
        return true;
      },
      onAccept: (dragged, target) {
        ref.read(categoriesProvider.notifier).updateParent(
          dragged.category.id,
          target.category.id,
        );
        setState(() {
          _expandedIds.add(target.category.id);
        });
      },
      child: DraggableCategoryTreeTile(
        node: node,
        intensity: intensity,
        isExpanded: isExpanded,
        onTap: () => _showEditModal(node.category),
        onExpandToggle: node.hasChildren
            ? () {
                setState(() {
                  if (_expandedIds.contains(node.category.id)) {
                    _expandedIds.remove(node.category.id);
                  } else {
                    _expandedIds.add(node.category.id);
                  }
                });
              }
            : null,
        onDragStarted: _startDrag,
        onDragEnd: _endDrag,
        onDragUpdate: _updateDragPosition,
      ),
    );
  }

  Widget _buildAddCategoryTile() {
    return GestureDetector(
      onTap: () => _showAddModal(),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xxl),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
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
              'Add Category',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowNode(CategoryTreeNode node) {
    if (node.depth == 0) return true;

    final categories = ref.read(categoriesProvider);
    String? currentParentId = node.category.parentId;

    while (currentParentId != null) {
      if (!_expandedIds.contains(currentParentId)) {
        return false;
      }
      final parent = categories.firstWhere(
        (c) => c.id == currentParentId,
        orElse: () => node.category,
      );
      currentParentId = parent.parentId;
    }

    return true;
  }

  void _showAddModal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryFormModal(
          type: _selectedType,
          onSave: (name, icon, colorIndex, parentId) {
            final categories = ref.read(categoriesProvider);
            final siblings = categories
                .where((c) => c.parentId == parentId && c.type == _selectedType)
                .toList();
            final sortOrder = siblings.isEmpty
                ? 0
                : siblings.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

            final category = Category(
              id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
              name: name,
              icon: icon,
              colorIndex: colorIndex,
              type: _selectedType,
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

  void _showEditModal(Category category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryFormModal(
          category: category,
          type: category.type,
          onSave: (name, icon, colorIndex, parentId) {
            final updated = category.copyWith(
              name: name,
              icon: icon,
              colorIndex: colorIndex,
              parentId: parentId,
              clearParentId: parentId == null,
            );
            ref.read(categoriesProvider.notifier).updateCategory(updated);
            Navigator.pop(context);
          },
          onDelete: () async {
            Navigator.pop(context);
            await _handleDelete(category);
          },
          onAddChild: () {
            Navigator.pop(context);
            _showAddChildModal(category);
          },
        ),
      ),
    );
  }

  void _showAddChildModal(Category parentCategory) {
    setState(() {
      _expandedIds.add(parentCategory.id);
    });
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryFormModal(
          type: parentCategory.type,
          initialParentId: parentCategory.id,
          onSave: (name, icon, colorIndex, parentId) {
            final categories = ref.read(categoriesProvider);
            final effectiveParentId = parentId ?? parentCategory.id;
            final siblings = categories
                .where((c) => c.parentId == effectiveParentId && c.type == parentCategory.type)
                .toList();
            final sortOrder = siblings.isEmpty
                ? 0
                : siblings.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

            final category = Category(
              id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
              name: name,
              icon: icon,
              colorIndex: colorIndex,
              type: parentCategory.type,
              isCustom: true,
              parentId: effectiveParentId,
              sortOrder: sortOrder,
            );
            ref.read(categoriesProvider.notifier).addCategory(category);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _handleDelete(Category category) async {
    final hasChildren = ref.read(hasChildrenProvider(category.id));

    if (hasChildren) {
      final childCount = ref.read(childCategoriesProvider(category.id)).length;
      final action = await showDeleteCategoryDialog(
        context: context,
        category: category,
        childCount: childCount,
      );

      if (action == null || action == DeleteCategoryAction.cancel) {
        return;
      }

      if (action == DeleteCategoryAction.promoteChildren) {
        ref.read(categoriesProvider.notifier).deleteCategoryPromotingChildren(category.id);
      } else if (action == DeleteCategoryAction.deleteAll) {
        ref.read(categoriesProvider.notifier).deleteWithChildren(category.id);
      }
    } else {
      final confirmed = await showSimpleDeleteConfirmationDialog(
        context: context,
        category: category,
      );

      if (confirmed == true) {
        ref.read(categoriesProvider.notifier).deleteCategory(category.id);
      }
    }
  }
}
