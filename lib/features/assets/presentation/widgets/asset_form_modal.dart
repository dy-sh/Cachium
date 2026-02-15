import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/buttons/primary_button.dart';
import '../../../../design_system/components/inputs/input_field.dart';
import '../../../../design_system/components/layout/form_header.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/widgets/color_picker_grid.dart';
import '../../../settings/presentation/widgets/icon_picker_grid.dart';
import '../providers/assets_provider.dart';

class AssetFormModal extends ConsumerStatefulWidget {
  final void Function(String name, IconData icon, int colorIndex, String? note) onSave;

  const AssetFormModal({
    super.key,
    required this.onSave,
  });

  @override
  ConsumerState<AssetFormModal> createState() => _AssetFormModalState();
}

class _AssetFormModalState extends ConsumerState<AssetFormModal> {
  late TextEditingController _nameController;
  late TextEditingController _noteController;
  late FocusNode _nameFocusNode;
  late IconData _selectedIcon;
  late int _selectedColorIndex;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _noteController = TextEditingController();
    _nameFocusNode = FocusNode();
    _selectedIcon = LucideIcons.box;
    _selectedColorIndex = 0;
    _isEditingName = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _applyName() {
    setState(() => _isEditingName = false);
    _nameFocusNode.unfocus();
  }

  void _startEditingName() {
    setState(() => _isEditingName = true);
    _nameFocusNode.requestFocus();
  }

  bool get _isValid => _nameController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final intensity = ref.watch(colorIntensityProvider);
    final accentColors = AppColors.getAccentOptions(intensity);
    final selectedColor = accentColors[_selectedColorIndex.clamp(0, accentColors.length - 1)];
    final assetName = _nameController.text.trim();

    final isDuplicateName = assetName.isNotEmpty && ref.watch(
      assetNameExistsProvider((name: assetName, excludeId: null)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: 'New Asset',
              onClose: () => Navigator.pop(context),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview with inline name editing
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
                          child: _isEditingName
                              ? TextField(
                                  controller: _nameController,
                                  focusNode: _nameFocusNode,
                                  autofocus: true,
                                  onChanged: (_) => setState(() {}),
                                  onSubmitted: (_) => _applyName(),
                                  style: AppTypography.h2.copyWith(
                                    color: assetName.isEmpty
                                        ? AppColors.textTertiary
                                        : selectedColor,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Asset name',
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
                                    assetName.isEmpty ? 'Tap to name' : assetName,
                                    style: AppTypography.h2.copyWith(
                                      color: assetName.isEmpty
                                          ? AppColors.textTertiary
                                          : selectedColor,
                                    ),
                                  ),
                                ),
                        ),
                        if (_isEditingName)
                          GestureDetector(
                            onTap: assetName.isNotEmpty ? _applyName : null,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: assetName.isNotEmpty
                                    ? selectedColor.withValues(alpha: 0.15)
                                    : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                assetName.isNotEmpty ? LucideIcons.check : LucideIcons.x,
                                size: 16,
                                color: assetName.isNotEmpty ? selectedColor : AppColors.textTertiary,
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
                          'Asset with this name already exists',
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
                    const SizedBox(height: AppSpacing.xxl),

                    // Note field
                    InputField(
                      label: 'Note (optional)',
                      hint: 'Add a description...',
                      controller: _noteController,
                      onChanged: (_) => setState(() {}),
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
                    label: 'Create Asset',
                    onPressed: _isValid && !isDuplicateName
                        ? () {
                            final note = _noteController.text.trim();
                            widget.onSave(
                              _nameController.text.trim(),
                              _selectedIcon,
                              _selectedColorIndex,
                              note.isEmpty ? null : note,
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
}
