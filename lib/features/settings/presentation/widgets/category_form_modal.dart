import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/buttons/fm_primary_button.dart';
import '../../../../design_system/components/inputs/fm_text_field.dart';
import '../../../categories/data/models/category.dart';
import '../providers/settings_provider.dart';
import 'color_picker_grid.dart';
import 'icon_picker_grid.dart';

class CategoryFormModal extends ConsumerStatefulWidget {
  final Category? category;
  final CategoryType type;
  final void Function(String name, IconData icon, int colorIndex) onSave;
  final VoidCallback? onDelete;

  const CategoryFormModal({
    super.key,
    this.category,
    required this.type,
    required this.onSave,
    this.onDelete,
  });

  @override
  ConsumerState<CategoryFormModal> createState() => _CategoryFormModalState();
}

class _CategoryFormModalState extends ConsumerState<CategoryFormModal> {
  late TextEditingController _nameController;
  late IconData _selectedIcon;
  late int _selectedColorIndex;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedIcon = widget.category?.icon ?? LucideIcons.tag;
    _selectedColorIndex = widget.category?.colorIndex ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isValid => _nameController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final intensity = ref.watch(colorIntensityProvider);
    final categoryColors = AppColors.getCategoryColors(intensity);
    final selectedColor = categoryColors[_selectedColorIndex.clamp(0, categoryColors.length - 1)];

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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isEditing ? 'Edit Category' : 'New Category',
                        style: AppTypography.h4,
                      ),
                    ),
                    if (isEditing && widget.onDelete != null)
                      GestureDetector(
                        onTap: () {
                          _showDeleteConfirmation(context);
                        },
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
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: bottomPadding + AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: selectedColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: selectedColor, width: 1.5),
                      ),
                      child: Icon(
                        _selectedIcon,
                        size: 28,
                        color: selectedColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Name input
                  FMTextField(
                    label: 'Name',
                    hint: 'Category name',
                    controller: _nameController,
                    onChanged: (_) => setState(() {}),
                  ),
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
                  const SizedBox(height: AppSpacing.xxl),

                  // Save button
                  FMPrimaryButton(
                    label: isEditing ? 'Save Changes' : 'Create Category',
                    onPressed: _isValid
                        ? () {
                            widget.onSave(
                              _nameController.text.trim(),
                              _selectedIcon,
                              _selectedColorIndex,
                            );
                          }
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ],
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
}
