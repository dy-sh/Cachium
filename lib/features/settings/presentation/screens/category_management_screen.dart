import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/providers/async_value_extensions.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/buttons/icon_btn.dart';
import '../../../../design_system/components/chips/toggle_chip.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/data/models/category_tree_node.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/category_form_modal.dart';
import 'category_list_section.dart';
import 'category_reassign_dialog.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends ConsumerState<CategoryManagementScreen> {
  final _uuid = const Uuid();
  int _selectedTypeIndex = 1; // 0 = Income, 1 = Expense
  final Set<String> _expandedIds = {};
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listKey = GlobalKey();
  Offset? _lastDragPosition;
  Timer? _scrollTimer;
  CategoryTreeNode? _draggedNode;
  String? _currentTargetParentId; // Parent ID where item will be placed
  String? _hoverTargetNodeId; // Node ID we're currently hovering over
  // ignore: unused_field
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
                      IconBtn(
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
                  const SizedBox(height: AppSpacing.xl),
                  // Type toggle
                  Center(
                    child: ToggleChip(
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
                    return CategoryRootDropZone(
                      intensity: intensity,
                      onHoverChanged: (isHovering) {
                        setState(() {
                          _hoverTargetNodeId = isHovering ? '_root_drop_zone_' : null;
                        });
                        _updateDragPlaceholderVisibility();
                      },
                      onAccept: (node) {
                        final categories = ref.read(categoriesProvider).valueOrEmpty;
                        final rootItems = categories
                            .where((c) => c.parentId == null && c.type == node.category.type && c.id != node.category.id)
                            .toList()
                          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

                        final insertBeforeId = rootItems.isNotEmpty ? rootItems.first.id : null;

                        ref.read(categoriesProvider.notifier).moveCategoryToPosition(
                          node.category.id,
                          null,
                          insertBeforeId,
                        );
                      },
                    );
                  }
                  if (index == treeNodes.length + 1) {
                    return AddCategoryTile(onTap: () => _showAddModal());
                  }
                  final nodeIndex = index - 1;
                  final node = treeNodes[nodeIndex];
                  final shouldShow = _shouldShowNode(node);

                  if (!shouldShow) {
                    return const SizedBox.shrink();
                  }

                  return CategoryTreeItem(
                    node: node,
                    draggedNode: _draggedNode,
                    intensity: intensity,
                    isExpanded: _expandedIds.contains(node.category.id),
                    currentTargetParentId: _currentTargetParentId,
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
                    onHoverChanged: _handleHoverChanged,
                    canAccept: (dragged, target, depth) {
                      // Allow dropping on same item (to cancel move or change parent)
                      if (dragged.category.id == target.category.id) {
                        if (depth == target.depth + 1) {
                          return false;
                        }
                        return true;
                      }
                      if (depth == target.depth + 1) {
                        if (dragged.category.parentId == target.category.id) return false;
                        final descendants = CategoryTreeBuilder.getDescendantIds(
                          ref.read(categoriesProvider).valueOrEmpty,
                          dragged.category.id,
                        );
                        if (descendants.contains(target.category.id)) return false;
                      }
                      return true;
                    },
                    onAccept: (dragged, target, depth) {
                      _handleTreeItemAccept(dragged, target, depth);
                    },
                  );
                },
              ),
            ),

            // Reorder hint
            CategoryReorderHint(
              draggedNode: _draggedNode,
              currentTargetParentId: _currentTargetParentId,
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _handleTreeItemAccept(CategoryTreeNode dragged, CategoryTreeNode target, int depth) {
    final categories = ref.read(categoriesProvider).valueOrEmpty;

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
        final currentParentId = dragged.category.parentId;
        String? insertBeforeId;

        if (currentParentId != null && newParentId == null) {
          final siblings = categories
              .where((c) => c.parentId == null && c.type == dragged.category.type && c.id != dragged.category.id)
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          final parentIndex = siblings.indexWhere((c) => c.id == currentParentId);
          if (parentIndex >= 0 && parentIndex < siblings.length - 1) {
            insertBeforeId = siblings[parentIndex + 1].id;
          }
        } else if (newParentId != null) {
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
      return;
    }

    if (depth == target.depth + 1) {
      final existingChildren = categories
          .where((c) => c.parentId == target.category.id && c.type == dragged.category.type)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

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
      String? insertAfterCategoryId;
      String? parentId;

      if (depth == target.depth) {
        insertAfterCategoryId = target.category.id;
        parentId = target.category.parentId;
      } else {
        final ancestors = ref.read(categoryAncestorsProvider(target.category.id));
        if (depth == 0) {
          if (ancestors.isNotEmpty) {
            insertAfterCategoryId = ancestors.last.id;
          } else {
            insertAfterCategoryId = target.category.id;
          }
          parentId = null;
        } else {
          final ancestorIndex = target.depth - depth - 1;
          if (ancestorIndex >= 0 && ancestorIndex < ancestors.length) {
            insertAfterCategoryId = ancestors[ancestorIndex].id;
            parentId = ancestors[ancestorIndex].parentId;
          } else {
            parentId = _getParentForInsertionDepth(target, depth);
            insertAfterCategoryId = target.category.id;
          }
        }
      }

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

  bool _shouldShowNode(CategoryTreeNode node) {
    if (node.depth == 0) return true;

    final categories = ref.read(categoriesProvider).valueOrEmpty;
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
          onSave: (name, icon, colorIndex, parentId, showAssets) {
            final categories = ref.read(categoriesProvider).valueOrEmpty;
            final siblings = categories
                .where((c) => c.parentId == parentId && c.type == _selectedType)
                .toList();
            final sortOrder = siblings.isEmpty
                ? 0
                : siblings.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

            final category = Category(
              id: _uuid.v4(),
              name: name,
              icon: icon,
              colorIndex: colorIndex,
              type: _selectedType,
              isCustom: true,
              parentId: parentId,
              sortOrder: sortOrder,
              showAssets: showAssets,
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
          onSave: (name, icon, colorIndex, parentId, showAssets) {
            final updated = category.copyWith(
              name: name,
              icon: icon,
              colorIndex: colorIndex,
              parentId: parentId,
              clearParentId: parentId == null,
              showAssets: showAssets,
            );
            ref.read(categoriesProvider.notifier).updateCategory(updated);
            Navigator.pop(context);
          },
          onDelete: () async {
            Navigator.pop(context);
            await handleCategoryDelete(
              context: context,
              ref: ref,
              category: category,
            );
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
          onSave: (name, icon, colorIndex, parentId, showAssets) {
            final categories = ref.read(categoriesProvider).valueOrEmpty;
            final effectiveParentId = parentId ?? parentCategory.id;
            final siblings = categories
                .where((c) => c.parentId == effectiveParentId && c.type == parentCategory.type)
                .toList();
            final sortOrder = siblings.isEmpty
                ? 0
                : siblings.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

            final category = Category(
              id: _uuid.v4(),
              name: name,
              icon: icon,
              colorIndex: colorIndex,
              type: parentCategory.type,
              isCustom: true,
              parentId: effectiveParentId,
              sortOrder: sortOrder,
              showAssets: showAssets,
            );
            ref.read(categoriesProvider.notifier).addCategory(category);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}
