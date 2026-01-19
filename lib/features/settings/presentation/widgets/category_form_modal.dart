import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/buttons/fm_primary_button.dart';
import '../../../../design_system/components/layout/fm_form_header.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../data/models/app_settings.dart';
import '../providers/settings_provider.dart';
import 'color_picker_grid.dart';
import 'icon_picker_grid.dart';
import 'parent_category_picker.dart';

class CategoryFormModal extends ConsumerStatefulWidget {
  final Category? category;
  final CategoryType type;
  final String? initialParentId;
  final void Function(String name, IconData icon, int colorIndex, String? parentId) onSave;
  final VoidCallback? onDelete;
  final VoidCallback? onAddChild;

  const CategoryFormModal({
    super.key,
    this.category,
    required this.type,
    this.initialParentId,
    required this.onSave,
    this.onDelete,
    this.onAddChild,
  });

  @override
  ConsumerState<CategoryFormModal> createState() => _CategoryFormModalState();
}

class _CategoryFormModalState extends ConsumerState<CategoryFormModal> {
  late TextEditingController _nameController;
  late FocusNode _nameFocusNode;
  late IconData _selectedIcon;
  late int _selectedColorIndex;
  String? _selectedParentId;
  bool _isEditingName = false;
  String _previousName = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _nameFocusNode = FocusNode();
    _selectedIcon = widget.category?.icon ?? LucideIcons.tag;
    _selectedColorIndex = widget.category?.colorIndex ?? 0;
    _selectedParentId = widget.category?.parentId ?? widget.initialParentId;

    // Start in edit mode if new category
    if (widget.category == null) {
      _isEditingName = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _startEditingName() {
    _previousName = _nameController.text;
    setState(() => _isEditingName = true);
    _nameFocusNode.requestFocus();
  }

  void _applyName() {
    setState(() => _isEditingName = false);
    _nameFocusNode.unfocus();
  }

  void _cancelEditingName() {
    _nameController.text = _previousName;
    setState(() => _isEditingName = false);
    _nameFocusNode.unfocus();
  }

  bool get _isValid => _nameController.text.trim().isNotEmpty;

  bool get _hasChanges {
    if (widget.category == null) return true;
    return _nameController.text.trim() != widget.category!.name ||
        _selectedIcon != widget.category!.icon ||
        _selectedColorIndex != widget.category!.colorIndex ||
        _selectedParentId != widget.category!.parentId;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;
    final intensity = ref.watch(colorIntensityProvider);
    final categoryColors = AppColors.getCategoryColors(intensity);
    final selectedColor = categoryColors[_selectedColorIndex.clamp(0, categoryColors.length - 1)];
    final categoryName = _nameController.text.trim();

    final isDuplicateName = categoryName.isNotEmpty && ref.watch(
      categoryNameExistsProvider((name: categoryName, excludeId: widget.category?.id)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            FMFormHeader(
              title: isEditing ? 'Edit Category' : 'New Category',
              onClose: () => Navigator.pop(context),
              trailing: isEditing && widget.onDelete != null
                  ? GestureDetector(
                      onTap: () => _showDeleteConfirmation(context),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.expense.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LucideIcons.trash2,
                          size: 18,
                          color: AppColors.expense,
                        ),
                      ),
                    )
                  : null,
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview with edit/preview mode for name
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: selectedColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: selectedColor, width: 1.5),
                          ),
                          child: Icon(
                            _selectedIcon,
                            size: 26,
                            color: selectedColor,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _isEditingName
                              ? TextField(
                                  controller: _nameController,
                                  focusNode: _nameFocusNode,
                                  autofocus: widget.category == null,
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: (_) => _applyName(),
                                  style: AppTypography.h2.copyWith(
                                    color: categoryName.isEmpty
                                        ? AppColors.textTertiary
                                        : selectedColor,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Category name',
                                    hintStyle: AppTypography.h2.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                )
                              : GestureDetector(
                                  onTap: _startEditingName,
                                  child: Text(
                                    categoryName.isEmpty ? 'Tap to name' : categoryName,
                                    style: AppTypography.h2.copyWith(
                                      color: categoryName.isEmpty
                                          ? AppColors.textTertiary
                                          : selectedColor,
                                    ),
                                  ),
                                ),
                        ),
                        if (_isEditingName)
                          GestureDetector(
                            onTap: categoryName.isNotEmpty ? _applyName : _cancelEditingName,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: categoryName.isNotEmpty
                                    ? selectedColor.withOpacity(0.15)
                                    : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                categoryName.isNotEmpty ? LucideIcons.check : LucideIcons.x,
                                size: 16,
                                color: categoryName.isNotEmpty ? selectedColor : AppColors.textTertiary,
                              ),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: _startEditingName,
                            child: Icon(
                              LucideIcons.pencil,
                              size: 18,
                              color: AppColors.textTertiary,
                            ),
                          ),
                      ],
                    ),
                    if (isDuplicateName)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          'Category with this name already exists',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.expense,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Parent category selector
                    _buildParentSelector(intensity),
                    const SizedBox(height: AppSpacing.xxl),

                    // Color picker
                    Text('Color', style: AppTypography.labelMedium),
                    const SizedBox(height: AppSpacing.sm),
                    ColorPickerGrid(
                      colors: categoryColors,
                      selectedColor: selectedColor,
                      crossAxisCount: 6,
                      itemSize: 40,
                      onColorSelected: (color) {
                        final index = categoryColors.indexOf(color);
                        if (index != -1) {
                          setState(() => _selectedColorIndex = index);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Icon picker
                    Text('Icon', style: AppTypography.labelMedium),
                    const SizedBox(height: AppSpacing.sm),
                    IconPickerGrid(
                      selectedIcon: _selectedIcon,
                      selectedColor: selectedColor,
                      onIconSelected: (icon) {
                        setState(() => _selectedIcon = icon);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),

            // Sticky bottom button
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.8),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.border.withOpacity(0.5),
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
                  child: isEditing && !_hasChanges && widget.onAddChild != null
                      ? GestureDetector(
                          onTap: widget.onAddChild,
                          child: Container(
                            height: AppSpacing.buttonHeight,
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
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Add Subcategory',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : FMPrimaryButton(
                          label: isEditing ? 'Save Changes' : 'Create Category',
                          onPressed: _isValid && !isDuplicateName
                              ? () {
                                  widget.onSave(
                                    _nameController.text.trim(),
                                    _selectedIcon,
                                    _selectedColorIndex,
                                    _selectedParentId,
                                  );
                                }
                              : null,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Category',
          style: AppTypography.h4,
        ),
        content: Text(
          'Are you sure you want to delete "${widget.category!.name}"? This action cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call();
            },
            child: Text(
              'Delete',
              style: AppTypography.button.copyWith(
                color: AppColors.expense,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentSelector(ColorIntensity intensity) {
    final parentCategory = _selectedParentId != null
        ? ref.watch(categoryByIdProvider(_selectedParentId!))
        : null;

    final parentColor = parentCategory?.getColor(intensity);
    final bgOpacity = AppColors.getBgOpacity(intensity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Parent Category', style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: () {
            showParentCategoryPicker(
              context: context,
              type: widget.type,
              currentCategoryId: widget.category?.id,
              selectedParentId: _selectedParentId,
              onSelected: (parentId) {
                setState(() => _selectedParentId = parentId);
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                if (parentCategory != null) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: parentColor!.withOpacity(bgOpacity),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      parentCategory.icon,
                      size: 16,
                      color: parentColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      parentCategory.name,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ] else ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      LucideIcons.folderRoot,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'None (Root Level)',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
