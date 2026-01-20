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
  CategoryTreeNode? _draggedNode;
  String? _currentTargetParentId; // Parent ID where item will be placed
  String? _hoverTargetNodeId; // Node ID we're currently hovering over
  int? _currentHoverDepth; // Current depth when hovering
  final ValueNotifier<bool> _showDragPlaceholderNotifier = ValueNotifier(true);
  final ValueNotifier<int> _previewDepthNotifier = ValueNotifier(0);

  static const _scrollAreaHeight = 80.0;
  static const _scrollSpeed = 25.0;

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    _showDragPlaceholderNotifier.dispose();
    _previewDepthNotifier.dispose();
    super.dispose();
  }

  void _startDrag(CategoryTreeNode node) {
    _draggedNode = node;
    _showDragPlaceholderNotifier.value = true; // Show placeholder at start
    _previewDepthNotifier.value = node.depth; // Start with original depth
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _performAutoScroll();
    });
  }

  void _endDrag() {
    _draggedNode = null;
    _scrollTimer?.cancel();
    _scrollTimer = null;
    _lastDragPosition = null;
    _showDragPlaceholderNotifier.value = true; // Reset for next drag
    setState(() {
      _currentTargetParentId = null;
      _hoverTargetNodeId = null;
    });
  }

  void _handleHoverChanged(CategoryTreeNode targetNode, int depth) {
    String? parentId;
    String? hoverNodeId;

    if (depth < 0) {
      // Hover cleared - but if we're over the dragged item itself, show its current parent
      if (_draggedNode != null && targetNode.category.id == _draggedNode!.category.id) {
        // Still hovering over the dragged item, show its current parent
        parentId = _draggedNode!.category.parentId;
        hoverNodeId = targetNode.category.id;
        // Use the item's original depth for preview
        _currentHoverDepth = _draggedNode!.depth;
        _previewDepthNotifier.value = _draggedNode!.depth;
      } else {
        parentId = null;
        hoverNodeId = null;
        _currentHoverDepth = null;
      }
    } else {
      hoverNodeId = targetNode.category.id;
      _currentHoverDepth = depth;
      if (depth == targetNode.depth + 1) {
        // Inserting as child of target
        parentId = targetNode.category.id;
      } else {
        // Inserting as sibling - use existing logic
        parentId = _getParentForInsertionDepth(targetNode, depth);
      }
    }

    if (_currentTargetParentId != parentId || _hoverTargetNodeId != hoverNodeId) {
      setState(() {
        _currentTargetParentId = parentId;
        _hoverTargetNodeId = hoverNodeId;
      });
      // Update placeholder visibility and depth for the dragged item
      _updateDragPlaceholderVisibility();
    }

    // Update preview depth when hovering over the original item
    if (_draggedNode != null && hoverNodeId == _draggedNode!.category.id && depth >= 0) {
      _previewDepthNotifier.value = depth;
    }
  }

  void _updateDragPlaceholderVisibility() {
    if (_draggedNode == null) return;
    final show = _hoverTargetNodeId == null || _hoverTargetNodeId == _draggedNode!.category.id;
    _showDragPlaceholderNotifier.value = show;
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
      final linear = (1 - (localPosition.dy / _scrollAreaHeight)).clamp(0.0, 1.0);
      final intensity = linear * linear * linear; // Cubic easing
      final offset = _scrollController.offset - (_scrollSpeed * intensity);
      _scrollController.jumpTo(offset.clamp(0.0, _scrollController.position.maxScrollExtent));
    } else if (localPosition.dy > listHeight - _scrollAreaHeight) {
      // Near or below bottom of list - scroll down
      final linear = (1 - ((listHeight - localPosition.dy) / _scrollAreaHeight)).clamp(0.0, 1.0);
      final intensity = linear * linear * linear; // Cubic easing
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
                  final nodeIndex = index - 1;
                  final node = treeNodes[nodeIndex];
                  final prevNode = nodeIndex > 0 ? treeNodes[nodeIndex - 1] : null;
                  return _buildTreeItem(node, prevNode, intensity);
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
    final intensity = ref.watch(colorIntensityProvider);
    final isDragging = _draggedNode != null;
    final parentCategory = _currentTargetParentId != null
        ? ref.watch(categoryByIdProvider(_currentTargetParentId!))
        : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(
        top: AppSpacing.xs,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.sm,
        left: AppSpacing.md,
        right: AppSpacing.md,
      ),
      child: isDragging && parentCategory != null
          ? _buildParentIndicator(parentCategory, intensity)
          : isDragging
              ? _buildRootLevelIndicator()
              : _buildDefaultHint(),
    );
  }

  Widget _buildDefaultHint() {
    return Row(
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
    );
  }

  Widget _buildRootLevelIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          LucideIcons.home,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          'Root level',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildParentIndicator(Category parent, ColorIntensity intensity) {
    final parentColor = parent.getColor(intensity);
    final bgOpacity = AppColors.getBgOpacity(intensity);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Inside',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: parentColor.withOpacity(bgOpacity),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: parentColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                parent.icon,
                size: 14,
                color: parentColor,
              ),
              const SizedBox(width: 6),
              Text(
                parent.name,
                style: AppTypography.labelSmall.copyWith(
                  color: parentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRootDropZone(ColorIntensity intensity) {
    return CategoryDropZone(
      label: 'Move to start',
      intensity: intensity,
      canAccept: (node) => true, // Accept any item
      onHoverChanged: (isHovering) {
        // Use a special marker to indicate hovering over root zone
        setState(() {
          _hoverTargetNodeId = isHovering ? '_root_drop_zone_' : null;
        });
        _updateDragPlaceholderVisibility();
      },
      onAccept: (node) {
        final categories = ref.read(categoriesProvider).valueOrNull ?? [];
        // Find the first root item to insert before
        final rootItems = categories
            .where((c) => c.parentId == null && c.type == node.category.type && c.id != node.category.id)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        final insertBeforeId = rootItems.isNotEmpty ? rootItems.first.id : null;

        ref.read(categoriesProvider.notifier).moveCategoryToPosition(
          node.category.id,
          null, // Root level
          insertBeforeId,
        );
      },
    );
  }

  /// Get the parent ID for inserting at a given depth.
  /// Uses prevNode to find the correct parent in the tree hierarchy.
  String? _getParentForInsertionDepth(CategoryTreeNode? prevNode, int depth) {
    if (depth == 0) return null;
    if (prevNode == null) return null;

    // If inserting deeper than prevNode, prevNode becomes the parent
    if (depth == prevNode.depth + 1) {
      return prevNode.category.id;
    }

    // If inserting at same level or shallower than prevNode,
    // find the ancestor at depth-1
    if (depth <= prevNode.depth) {
      // ancestors is ordered [root, grandparent, ..., parent]
      // The ancestor at depth D is at index D (root at 0, etc.)
      // We want the parent for depth, which is at depth-1
      final ancestors = ref.read(categoryAncestorsProvider(prevNode.category.id));
      final ancestorIndex = depth - 1;
      if (ancestorIndex >= 0 && ancestorIndex < ancestors.length) {
        return ancestors[ancestorIndex].id;
      }
    }

    return null;
  }

  Widget _buildTreeItem(CategoryTreeNode node, CategoryTreeNode? prevNode, ColorIntensity intensity) {
    final isExpanded = _expandedIds.contains(node.category.id);
    final shouldShow = _shouldShowNode(node);

    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    final categoryColor = _draggedNode?.category.getColor(intensity) ??
                          node.category.getColor(intensity);

    final isThisTargetParent = _currentTargetParentId != null &&
        _currentTargetParentId == node.category.id;
    final draggedCategory = _draggedNode?.category;
    final targetColor = draggedCategory?.getColor(intensity);

    // Suppress placeholder on the dragged item (childWhenDragging shows it instead)
    final isDraggedNode = _draggedNode?.category.id == node.category.id;

    return CategoryItemDropTarget(
      targetNode: node,
      highlightColor: categoryColor,
      onHoverChanged: _handleHoverChanged,
      suppressPlaceholder: isDraggedNode,
      canAccept: (dragged, target, depth) {
        // Allow dropping on same item (to cancel move or change parent)
        if (dragged.category.id == target.category.id) {
          if (depth == target.depth + 1) {
            // Can't be child of itself
            return false;
          }
          // Allow drop (will check in onAccept if parent actually changes)
          return true;
        }
        // If inserting as child, check if that's allowed
        if (depth == target.depth + 1) {
          if (dragged.category.parentId == target.category.id) return false;
          final descendants = CategoryTreeBuilder.getDescendantIds(
            ref.read(categoriesProvider).valueOrNull ?? [],
            dragged.category.id,
          );
          if (descendants.contains(target.category.id)) return false;
        }
        return true;
      },
      onAccept: (dragged, target, depth) {
        final categories = ref.read(categoriesProvider).valueOrNull ?? [];

        // Handle dropping on same item (changing parent only, or cancel move)
        if (dragged.category.id == target.category.id) {
          String? newParentId;
          if (depth == target.depth) {
            newParentId = target.category.parentId;
          } else {
            newParentId = _getParentForInsertionDepth(target, depth);
          }
          // Only update if parent would actually change
          if (newParentId != dragged.category.parentId) {
            // Find the correct position - should be after current parent
            final currentParentId = dragged.category.parentId;
            String? insertBeforeId;

            if (currentParentId != null && newParentId == null) {
              // Moving from child to root level - place after current parent
              final siblings = categories
                  .where((c) => c.parentId == null && c.type == dragged.category.type && c.id != dragged.category.id)
                  .toList()
                ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
              final parentIndex = siblings.indexWhere((c) => c.id == currentParentId);
              if (parentIndex >= 0 && parentIndex < siblings.length - 1) {
                insertBeforeId = siblings[parentIndex + 1].id;
              }
            } else if (newParentId != null) {
              // Moving to a different parent - place at the start of new parent's children
              final newSiblings = categories
                  .where((c) => c.parentId == newParentId && c.type == dragged.category.type && c.id != dragged.category.id)
                  .toList()
                ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
              if (newSiblings.isNotEmpty) {
                insertBeforeId = newSiblings.first.id;
              }
            }

            ref.read(categoriesProvider.notifier).moveCategoryToPosition(
              dragged.category.id,
              newParentId,
              insertBeforeId,
            );
          }
          // If parent is the same, do nothing (cancel move)
          return;
        }

        if (depth == target.depth + 1) {
          // Insert as FIRST child of target (placeholder shows right after target)
          final existingChildren = categories
              .where((c) => c.parentId == target.category.id && c.type == dragged.category.type)
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          // Insert before the first existing child to become the new first child
          final insertBeforeId = existingChildren.isNotEmpty ? existingChildren.first.id : null;

          ref.read(categoriesProvider.notifier).moveCategoryToPosition(
            dragged.category.id,
            target.category.id,
            insertBeforeId,
          );
          setState(() {
            _expandedIds.add(target.category.id);
          });
        } else {
          // Insert as sibling at the specified depth, AFTER the target (or target's ancestor)
          String? insertAfterCategoryId;
          String? parentId;

          if (depth == target.depth) {
            // Same level as target - insert right after target
            insertAfterCategoryId = target.category.id;
            parentId = target.category.parentId;
          } else {
            // Shallower level - find target's ancestor at that depth and insert after it
            final ancestors = ref.read(categoryAncestorsProvider(target.category.id));
            // ancestors is [parent, grandparent, ..., root] with depths [target.depth-1, ..., 0]
            if (depth == 0) {
              // Insert at root level after the root ancestor
              if (ancestors.isNotEmpty) {
                insertAfterCategoryId = ancestors.last.id;
              } else {
                insertAfterCategoryId = target.category.id;
              }
              parentId = null;
            } else {
              // Find ancestor at the target depth
              // Ancestor at depth D is at index (target.depth - D - 1)
              final ancestorIndex = target.depth - depth - 1;
              if (ancestorIndex >= 0 && ancestorIndex < ancestors.length) {
                insertAfterCategoryId = ancestors[ancestorIndex].id;
                parentId = ancestors[ancestorIndex].parentId;
              } else {
                // Fallback
                parentId = _getParentForInsertionDepth(target, depth);
                insertAfterCategoryId = target.category.id;
              }
            }
          }

          // Find the sibling that comes after insertAfterCategoryId to get insertBeforeId
          // Exclude the dragged item from siblings list to avoid incorrect calculations
          final siblings = categories
              .where((c) => c.parentId == parentId && c.type == dragged.category.type && c.id != dragged.category.id)
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          String? insertBeforeId;
          final afterIndex = siblings.indexWhere((c) => c.id == insertAfterCategoryId);
          if (afterIndex >= 0 && afterIndex < siblings.length - 1) {
            insertBeforeId = siblings[afterIndex + 1].id;
          }

          ref.read(categoriesProvider.notifier).moveCategoryToPosition(
            dragged.category.id,
            parentId,
            insertBeforeId,
          );
        }
      },
      child: DraggableCategoryTreeTile(
        node: node,
        intensity: intensity,
        isExpanded: isExpanded,
        isTargetParent: isThisTargetParent,
        targetParentColor: targetColor,
        showDragPlaceholderNotifier: _showDragPlaceholderNotifier,
        previewDepthNotifier: _previewDepthNotifier,
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
        onDragStarted: () => _startDrag(node),
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

    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
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
            final categories = ref.read(categoriesProvider).valueOrNull ?? [];
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
            final hasChildren = ref.read(hasChildrenProvider(category.id));

            if (hasChildren) {
              // Show dialog to choose what to do with children
              await _handleDelete(category);
            } else {
              // Confirmation was already shown in the form modal
              ref.read(categoriesProvider.notifier).deleteCategory(category.id);
            }
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
            final categories = ref.read(categoriesProvider).valueOrNull ?? [];
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
