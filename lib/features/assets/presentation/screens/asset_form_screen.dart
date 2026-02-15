import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/buttons/primary_button.dart';
import '../../../../design_system/components/chips/toggle_chip.dart';
import '../../../../design_system/components/feedback/notification.dart';
import '../../../../design_system/components/inputs/input_field.dart';
import '../../../../design_system/components/layout/form_header.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../settings/presentation/widgets/color_picker_grid.dart';
import '../../../settings/presentation/widgets/icon_picker_grid.dart';
import '../../data/models/asset.dart';
import '../providers/asset_form_provider.dart';
import '../providers/assets_provider.dart';

class AssetFormScreen extends ConsumerStatefulWidget {
  final String? assetId;
  final bool pickerMode;

  const AssetFormScreen({super.key, this.assetId, this.pickerMode = false});

  @override
  ConsumerState<AssetFormScreen> createState() => _AssetFormScreenState();
}

class _AssetFormScreenState extends ConsumerState<AssetFormScreen> {
  bool _initialized = false;
  late TextEditingController _nameController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _noteController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.assetId == null) {
        ref.read(assetFormProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _initializeForEdit() {
    if (_initialized || widget.assetId == null) return;

    final asset = ref.read(assetByIdProvider(widget.assetId!));
    if (asset != null) {
      ref.read(assetFormProvider.notifier).initForEdit(asset);
      _nameController.text = asset.name;
      _noteController.text = asset.note ?? '';
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.assetId != null && !_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeForEdit();
        if (mounted) setState(() {});
      });
    }

    final formState = ref.watch(assetFormProvider);
    final isEditing = formState.isEditing;
    final intensity = ref.watch(colorIntensityProvider);
    final accentColors = AppColors.getAccentOptions(intensity);
    final selectedColor = accentColors[formState.colorIndex.clamp(0, accentColors.length - 1)];

    final assetName = formState.name.trim();
    final isDuplicateName = assetName.isNotEmpty && ref.watch(
      assetNameExistsProvider((name: assetName, excludeId: formState.editingAssetId)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: isEditing ? 'Edit Asset' : 'New Asset',
              onClose: () => context.pop(),
              trailing: isEditing
                  ? GestureDetector(
                      onTap: () => _deleteAsset(context),
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
                    InputField(
                      key: ValueKey('name_${formState.editingAssetId}'),
                      label: 'Asset Name',
                      hint: 'e.g. BMW X5, MacBook Pro...',
                      controller: _nameController,
                      autofocus: !isEditing,
                      onChanged: (value) {
                        ref.read(assetFormProvider.notifier).setName(value);
                      },
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

                    if (isEditing) ...[
                      Text('Status', style: AppTypography.labelMedium),
                      const SizedBox(height: AppSpacing.sm),
                      ToggleChip(
                        options: const ['Active', 'Sold'],
                        selectedIndex: formState.status == AssetStatus.active ? 0 : 1,
                        onChanged: (index) {
                          ref.read(assetFormProvider.notifier).setStatus(
                            index == 0 ? AssetStatus.active : AssetStatus.sold,
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],

                    Text('Icon', style: AppTypography.labelMedium),
                    const SizedBox(height: AppSpacing.sm),
                    IconPickerGrid(
                      selectedIcon: formState.icon,
                      selectedColor: selectedColor,
                      onIconSelected: (icon) {
                        ref.read(assetFormProvider.notifier).setIcon(icon);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),

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
                          ref.read(assetFormProvider.notifier).setColorIndex(index);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    InputField(
                      key: ValueKey('note_${formState.editingAssetId}'),
                      label: 'Note (optional)',
                      hint: 'Add a description...',
                      controller: _noteController,
                      onChanged: (value) {
                        ref.read(assetFormProvider.notifier).setNote(value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.screenPadding,
                right: AppSpacing.screenPadding,
                bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
              ),
              child: PrimaryButton(
                label: isEditing ? 'Save Changes' : 'Create Asset',
                onPressed: formState.canSave && !isDuplicateName
                    ? () async {
                        if (isEditing) {
                          final originalAsset = ref.read(
                            assetByIdProvider(formState.editingAssetId!),
                          );
                          if (originalAsset != null) {
                            final updatedAsset = originalAsset.copyWith(
                              name: formState.name,
                              icon: formState.icon,
                              colorIndex: formState.colorIndex,
                              status: formState.status,
                              note: formState.note,
                              clearNote: formState.note == null || formState.note!.isEmpty,
                            );
                            await ref.read(assetsProvider.notifier)
                                .updateAsset(updatedAsset);
                          }
                        } else {
                          final newAssetId = await ref.read(assetsProvider.notifier).addAsset(
                            name: formState.name,
                            icon: formState.icon,
                            colorIndex: formState.colorIndex,
                            note: formState.note,
                          );
                          ref.read(assetFormProvider.notifier).reset();
                          if (context.mounted) {
                            if (widget.pickerMode) {
                              Navigator.of(context).pop(newAssetId);
                            } else {
                              context.pop();
                              context.showSuccessNotification('Asset created');
                            }
                          }
                          return;
                        }
                        ref.read(assetFormProvider.notifier).reset();
                        if (context.mounted) {
                          context.pop();
                          context.showSuccessNotification('Asset updated');
                        }
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAsset(BuildContext context) async {
    final formState = ref.read(assetFormProvider);
    if (formState.editingAssetId == null) return;

    await ref.read(assetsProvider.notifier).deleteAsset(formState.editingAssetId!);
    ref.read(assetFormProvider.notifier).reset();

    if (mounted && context.mounted) {
      context.pop();
      context.showSuccessNotification('Asset deleted');
    }
  }
}
