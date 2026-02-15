import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/buttons/primary_button.dart';
import '../../../../design_system/components/chips/toggle_chip.dart';
import '../../../../design_system/components/inputs/input_field.dart';
import '../../../../design_system/components/layout/form_header.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/widgets/color_picker_grid.dart';
import '../../../settings/presentation/widgets/icon_picker_grid.dart';
import '../../data/models/asset.dart';
import '../providers/assets_provider.dart';

class AssetFormModal extends ConsumerStatefulWidget {
  final Asset? asset;
  final void Function(String name, IconData icon, int colorIndex, AssetStatus status, String? note) onSave;
  final VoidCallback? onDelete;

  const AssetFormModal({
    super.key,
    this.asset,
    required this.onSave,
    this.onDelete,
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
  late AssetStatus _selectedStatus;
  bool _isEditingName = false;
  String _previousName = '';

  bool get _isEditing => widget.asset != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.asset?.name ?? '');
    _noteController = TextEditingController(text: widget.asset?.note ?? '');
    _nameFocusNode = FocusNode();
    _selectedIcon = widget.asset?.icon ?? LucideIcons.box;
    _selectedColorIndex = widget.asset?.colorIndex ?? 0;
    _selectedStatus = widget.asset?.status ?? AssetStatus.active;

    if (!_isEditing) {
      _isEditingName = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
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
    if (!_isEditing) return true;
    final asset = widget.asset!;
    return _nameController.text.trim() != asset.name ||
        _selectedIcon != asset.icon ||
        _selectedColorIndex != asset.colorIndex ||
        _selectedStatus != asset.status ||
        (_noteController.text.trim()) != (asset.note ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final intensity = ref.watch(colorIntensityProvider);
    final accentColors = AppColors.getAccentOptions(intensity);
    final selectedColor = accentColors[_selectedColorIndex.clamp(0, accentColors.length - 1)];
    final assetName = _nameController.text.trim();

    final isDuplicateName = assetName.isNotEmpty && ref.watch(
      assetNameExistsProvider((name: assetName, excludeId: widget.asset?.id)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: _isEditing ? 'Edit Asset' : 'New Asset',
              onClose: () => Navigator.pop(context),
              trailing: _isEditing && widget.onDelete != null
                  ? GestureDetector(
                      onTap: widget.onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.expense.withValues(alpha: 0.1),
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
                                  autofocus: !_isEditing,
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
                            onTap: assetName.isNotEmpty ? _applyName : _cancelEditingName,
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

                    // Status toggle (edit mode only)
                    if (_isEditing) ...[
                      Text('Status', style: AppTypography.labelMedium),
                      const SizedBox(height: AppSpacing.sm),
                      ToggleChip(
                        options: const ['Active', 'Sold'],
                        selectedIndex: _selectedStatus == AssetStatus.active ? 0 : 1,
                        onChanged: (index) {
                          setState(() {
                            _selectedStatus = index == 0 ? AssetStatus.active : AssetStatus.sold;
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],

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
                    label: _isEditing ? 'Save Changes' : 'Create Asset',
                    onPressed: _isValid && !isDuplicateName && _hasChanges
                        ? () {
                            final note = _noteController.text.trim();
                            widget.onSave(
                              _nameController.text.trim(),
                              _selectedIcon,
                              _selectedColorIndex,
                              _selectedStatus,
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
