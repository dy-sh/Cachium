import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/buttons/primary_button.dart';
import '../../../../design_system/components/feedback/confirmation_dialog.dart';
import '../../../../design_system/components/inputs/input_field.dart';
import '../../../../design_system/components/layout/form_header.dart';
import '../../../../design_system/components/layout/unsaved_work_pop_scope.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/widgets/color_picker_grid.dart';
import '../../../settings/presentation/widgets/icon_picker_grid.dart';
import '../../data/models/asset_category.dart';
import '../providers/asset_categories_provider.dart';

class AssetCategoryFormModal extends ConsumerStatefulWidget {
  final AssetCategory? category;
  final void Function(String name, IconData icon, int colorIndex) onSave;
  final VoidCallback? onDelete;

  const AssetCategoryFormModal({
    super.key,
    this.category,
    required this.onSave,
    this.onDelete,
  });

  @override
  ConsumerState<AssetCategoryFormModal> createState() => _AssetCategoryFormModalState();
}

class _AssetCategoryFormModalState extends ConsumerState<AssetCategoryFormModal> {
  late TextEditingController _nameController;
  late IconData _selectedIcon;
  late int _selectedColorIndex;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedIcon = widget.category?.icon ?? LucideIcons.box;
    _selectedColorIndex = widget.category?.colorIndex ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isValid => _nameController.text.trim().isNotEmpty;

  bool get _hasChanges {
    if (!_isEditing) return true;
    final cat = widget.category!;
    return _nameController.text.trim() != cat.name ||
        _selectedIcon != cat.icon ||
        _selectedColorIndex != cat.colorIndex;
  }

  @override
  Widget build(BuildContext context) {
    final intensity = ref.watch(colorIntensityProvider);
    final accentColors = AppColors.getAccentOptions(intensity);
    final selectedColor = accentColors[_selectedColorIndex.clamp(0, accentColors.length - 1)];
    final categoryName = _nameController.text.trim();

    final isDuplicateName = categoryName.isNotEmpty && ref.watch(
      assetCategoryNameExistsProvider((name: categoryName, excludeId: widget.category?.id)),
    );

    return UnsavedWorkPopScope(
      hasUnsavedWork: _hasChanges,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              FormHeader(
                title: _isEditing ? 'Edit Category' : 'New Category',
                onClose: () {
                  if (_hasChanges) {
                    showConfirmationDialog(
                      context: context,
                      title: 'Discard changes?',
                      message: 'You have unsaved changes that will be lost.',
                      confirmLabel: 'Discard',
                      isDestructive: true,
                    ).then((confirmed) {
                      if (confirmed == true && context.mounted) {
                        Navigator.pop(context);
                      }
                    });
                  } else {
                    Navigator.pop(context);
                  }
                },
                trailing: _isEditing && widget.onDelete != null
                    ? GestureDetector(
                        onTap: () async {
                          final confirmed = await showConfirmationDialog(
                            context: context,
                            title: 'Delete category?',
                            message: 'This will permanently delete "${widget.category!.name}". Assets using this category will become uncategorized.',
                            confirmLabel: 'Delete',
                            isDestructive: true,
                          );
                          if (confirmed == true) {
                            widget.onDelete?.call();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.expense.withValues(alpha: 0.1),
                            borderRadius: AppRadius.smAll,
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

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preview
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: selectedColor.withValues(alpha: 0.15),
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
                            child: Text(
                              categoryName.isEmpty ? 'Category name' : categoryName,
                              style: AppTypography.h2.copyWith(
                                color: categoryName.isEmpty
                                    ? AppColors.textTertiary
                                    : selectedColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Name field
                      InputField(
                        label: 'Name',
                        hint: 'e.g. Vehicle, Property...',
                        controller: _nameController,
                        autofocus: !_isEditing,
                        onChanged: (_) => setState(() {}),
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

                      // Color picker
                      Text('Color', style: AppTypography.labelMedium),
                      const SizedBox(height: AppSpacing.sm),
                      ColorPickerGrid(
                        colors: accentColors,
                        selectedColor: selectedColor,
                        crossAxisCount: 8,
                        itemSize: 36,
                        onColorSelected: (color) {
                          final index = accentColors.indexOf(color);
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
                    child: PrimaryButton(
                      label: _isEditing ? 'Save Changes' : 'Create Category',
                      onPressed: _isValid && !isDuplicateName && _hasChanges
                          ? () {
                              widget.onSave(
                                _nameController.text.trim(),
                                _selectedIcon,
                                _selectedColorIndex,
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
      ),
    );
  }
}
