import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/buttons/destructive_button.dart';
import '../../../../design_system/components/buttons/primary_button.dart';
import '../../../../design_system/components/feedback/confirmation_dialog.dart';
import '../../../../design_system/components/feedback/notification.dart';
import '../../../../design_system/components/inputs/input_field.dart';
import '../../../../design_system/components/layout/form_header.dart';
import '../../../../design_system/components/layout/unsaved_work_pop_scope.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/widgets/color_picker_grid.dart';
import '../../../settings/presentation/widgets/icon_picker_grid.dart';
import '../../data/models/tag.dart';
import '../providers/tags_provider.dart';

class TagFormScreen extends ConsumerStatefulWidget {
  final String? tagId;

  const TagFormScreen({super.key, this.tagId});

  @override
  ConsumerState<TagFormScreen> createState() => _TagFormScreenState();
}

class _TagFormScreenState extends ConsumerState<TagFormScreen> {
  static const _uuid = Uuid();
  late TextEditingController _nameController;
  late IconData _selectedIcon;
  late int _selectedColorIndex;
  bool _isSaving = false;

  bool get _isEditing => widget.tagId != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _selectedIcon = LucideIcons.tag;
    _selectedColorIndex = 0;

    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final tag = ref.read(tagByIdProvider(widget.tagId!));
        if (tag != null) {
          _nameController.text = tag.name;
          setState(() {
            _selectedIcon = tag.icon;
            _selectedColorIndex = tag.colorIndex;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isValid => _nameController.text.trim().isNotEmpty;

  bool get _hasChanges {
    if (!_isEditing) return true;
    final tag = ref.read(tagByIdProvider(widget.tagId!));
    if (tag == null) return true;
    return _nameController.text.trim() != tag.name ||
        _selectedIcon != tag.icon ||
        _selectedColorIndex != tag.colorIndex;
  }

  Future<void> _save() async {
    if (!_isValid || _isSaving) return;

    final name = _nameController.text.trim();
    final isDuplicate = ref.read(
      tagNameExistsProvider((name: name, excludeId: widget.tagId)),
    );
    if (isDuplicate) {
      context.showWarningNotification('A tag with this name already exists');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(tagsProvider.notifier);

      if (_isEditing) {
        final existing = ref.read(tagByIdProvider(widget.tagId!));
        if (existing == null) {
          context.showErrorNotification('Tag not found');
          return;
        }
        await notifier.updateTag(existing.copyWith(
          name: name,
          icon: _selectedIcon,
          colorIndex: _selectedColorIndex,
        ));
        if (mounted) {
          context.showSuccessNotification('Tag updated');
          context.pop();
        }
      } else {
        final tags = ref.read(tagsProvider).valueOrNull ?? [];
        final maxSort = tags.isEmpty
            ? 0
            : tags.map((t) => t.sortOrder).reduce((a, b) => a > b ? a : b) + 1;

        await notifier.addTag(Tag(
          id: _uuid.v4(),
          name: name,
          icon: _selectedIcon,
          colorIndex: _selectedColorIndex,
          sortOrder: maxSort,
        ));
        if (mounted) {
          context.showSuccessNotification('Tag created');
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        context.showErrorNotification('Failed to save tag');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Delete Tag',
      message: 'This tag will be removed from all transactions.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(tagsProvider.notifier).deleteTag(widget.tagId!);
      if (mounted) {
        context.showSuccessNotification('Tag deleted');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        context.showErrorNotification('Failed to delete tag');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final intensity = ref.watch(colorIntensityProvider);
    final accentColors = AppColors.getAccentOptions(intensity);
    final selectedColor =
        accentColors[_selectedColorIndex.clamp(0, accentColors.length - 1)];

    return UnsavedWorkPopScope(
      hasUnsavedWork: _hasChanges,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              FormHeader(
                title: _isEditing ? 'Edit Tag' : 'New Tag',
                onClose: () => context.pop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preview
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: selectedColor.withValues(
                                alpha: AppColors.getBgOpacity(intensity)),
                            borderRadius: AppRadius.lgAll,
                          ),
                          child: Icon(
                            _selectedIcon,
                            size: 32,
                            color: selectedColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Name
                      InputField(
                        controller: _nameController,
                        label: 'Name',
                        hint: 'e.g., Tax Deductible',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Color picker
                      Text('Color',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textTertiary)),
                      const SizedBox(height: AppSpacing.sm),
                      ColorPickerGrid(
                        colors: accentColors,
                        selectedColor: selectedColor,
                        onColorSelected: (color) {
                          final index = accentColors.indexOf(color);
                          if (index >= 0) {
                            setState(() => _selectedColorIndex = index);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Icon picker
                      Text('Icon',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textTertiary)),
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
                      PrimaryButton(
                        label: _isEditing ? 'Save Changes' : 'Create Tag',
                        onPressed: (_isValid && _hasChanges && !_isSaving)
                            ? _save
                            : null,
                        isLoading: _isSaving,
                      ),

                      if (_isEditing) ...[
                        const SizedBox(height: AppSpacing.md),
                        DestructiveButton(
                          label: 'Delete Tag',
                          onPressed: _delete,
                          isOutlined: true,
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xxxl),
                    ],
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
