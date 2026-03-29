import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/async_value_extensions.dart';
import '../../../../design_system/components/buttons/icon_btn.dart';
import '../../../../design_system/components/feedback/notification.dart';
import '../../../../design_system/components/layout/form_header.dart';
import '../../../../navigation/app_router.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/models/tag.dart';
import '../providers/tags_provider.dart';
class TagManagementScreen extends ConsumerStatefulWidget {
  const TagManagementScreen({super.key});

  @override
  ConsumerState<TagManagementScreen> createState() =>
      _TagManagementScreenState();
}

class _TagManagementScreenState extends ConsumerState<TagManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(tagsProvider);
    final tags = tagsAsync.valueOrEmpty;
    final intensity = ref.watch(colorIntensityProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            FormHeader(
              title: 'Tags',
              onClose: () => context.pop(),
              trailing: IconBtn(
                icon: LucideIcons.plus,
                onPressed: () => context.push(AppRoutes.tagForm),
              ),
            ),
            Expanded(
              child: tags.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.tag,
                            size: 48,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No tags yet',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.textTertiary),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Add tags to classify transactions',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding),
                      itemCount: tags.length,
                      onReorder: _onReorder,
                      proxyDecorator: (child, index, animation) {
                        return Material(
                          color: Colors.transparent,
                          child: child,
                        );
                      },
                      itemBuilder: (context, index) {
                        final tag = tags[index];
                        final color = tag.getColor(intensity);
                        final bgOpacity = AppColors.getBgOpacity(intensity);

                        return Container(
                          key: ValueKey(tag.id),
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadius.mdAll,
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: bgOpacity),
                                borderRadius: AppRadius.smAll,
                              ),
                              child: Icon(tag.icon, size: 18, color: color),
                            ),
                            title: Text(
                              tag.name,
                              style: AppTypography.bodyMedium,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconBtn(
                                  icon: LucideIcons.pencil,
                                  size: 16,
                                  onPressed: () => context
                                      .push(AppRoutes.tagEditPath(tag.id)),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                ReorderableDragStartListener(
                                  index: index,
                                  child: Icon(
                                    LucideIcons.gripVertical,
                                    size: 18,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    final tagsAsync = ref.read(tagsProvider);
    final tags = tagsAsync.valueOrNull;
    if (tags == null) return;

    if (newIndex > oldIndex) newIndex--;

    final reordered = List<Tag>.from(tags);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    try {
      final notifier = ref.read(tagsProvider.notifier);
      for (int i = 0; i < reordered.length; i++) {
        if (reordered[i].sortOrder != i) {
          await notifier.reorderTag(reordered[i].id, i);
        }
      }
    } catch (e) {
      if (mounted) {
        context.showErrorNotification('Failed to reorder tags');
      }
    }
  }
}
