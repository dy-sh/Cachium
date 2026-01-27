import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_radius.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../categories/data/models/category.dart';
import '../../../../settings/data/models/app_settings.dart';
import '../../../../categories/presentation/providers/categories_provider.dart';
import '../../../../settings/presentation/providers/settings_provider.dart';
import '../../providers/analytics_filter_provider.dart';

class CategoryFilterPopup extends ConsumerWidget {
  const CategoryFilterPopup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(analyticsFilterProvider);
    final accentColor = ref.watch(accentColorProvider);

    final hasFilter = filter.hasCategoryFilter;
    final count = filter.selectedCategoryIds.length;

    return GestureDetector(
      onTap: () => _showCategoryFilterSheet(context),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: hasFilter ? accentColor.withOpacity(0.1) : AppColors.surface,
          borderRadius: AppRadius.chip,
          border: Border.all(
            color: hasFilter ? accentColor : AppColors.border,
            width: hasFilter ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.filter,
              size: 14,
              color: hasFilter ? accentColor : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              hasFilter ? 'Categories ($count)' : 'Categories',
              style: AppTypography.labelMedium.copyWith(
                color: hasFilter ? accentColor : AppColors.textPrimary,
                fontWeight: hasFilter ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (hasFilter) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(
                LucideIcons.x,
                size: 12,
                color: accentColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCategoryFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CategoryFilterSheet(),
    );
  }
}

class _CategoryFilterSheet extends ConsumerStatefulWidget {
  const _CategoryFilterSheet();

  @override
  ConsumerState<_CategoryFilterSheet> createState() =>
      _CategoryFilterSheetState();
}

class _CategoryFilterSheetState extends ConsumerState<_CategoryFilterSheet> {
  late Set<String> _selectedIds;
  final Set<String> _expandedParents = {};

  @override
  void initState() {
    super.initState();
    _selectedIds =
        Set.from(ref.read(analyticsFilterProvider).selectedCategoryIds);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final colorIntensity = ref.watch(colorIntensityProvider);
    final accentColor = ref.watch(accentColorProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xl),
          topRight: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: AppRadius.fullAll,
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filter Categories', style: AppTypography.h4),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        final categories =
                            categoriesAsync.valueOrNull ?? [];
                        setState(() {
                          _selectedIds =
                              categories.map((c) => c.id).toSet();
                        });
                      },
                      child: Text(
                        'All',
                        style: AppTypography.labelLarge.copyWith(
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    GestureDetector(
                      onTap: () => setState(() => _selectedIds.clear()),
                      child: Text(
                        'Clear',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Category list
          Flexible(
            child: categoriesAsync.when(
              data: (categories) {
                final roots = categories
                    .where((c) => c.parentId == null)
                    .toList()
                  ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

                return ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  itemCount: roots.length,
                  itemBuilder: (context, index) {
                    final parent = roots[index];
                    final children = categories
                        .where((c) => c.parentId == parent.id)
                        .toList()
                      ..sort(
                          (a, b) => a.sortOrder.compareTo(b.sortOrder));
                    final isExpanded =
                        _expandedParents.contains(parent.id);

                    return _buildParentTile(
                      parent,
                      children,
                      isExpanded,
                      categories,
                      colorIntensity,
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
          // Done button
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg + MediaQuery.of(context).padding.bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: ElevatedButton(
                onPressed: () {
                  ref
                      .read(analyticsFilterProvider.notifier)
                      .setCategories(_selectedIds);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.button,
                  ),
                ),
                child: Text(
                  _selectedIds.isEmpty
                      ? 'Show All'
                      : 'Apply (${_selectedIds.length} selected)',
                  style: AppTypography.button.copyWith(
                    color: AppColors.background,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentTile(
    Category parent,
    List<Category> children,
    bool isExpanded,
    List<Category> allCategories,
    ColorIntensity colorIntensity,
  ) {
    final parentColor = parent.getColor(colorIntensity);
    final allIds = [parent.id, ...children.map((c) => c.id)];
    final allSelected = allIds.every(_selectedIds.contains);
    final someSelected =
        !allSelected && allIds.any(_selectedIds.contains);

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              if (allSelected) {
                _selectedIds.removeAll(allIds);
              } else {
                _selectedIds.addAll(allIds);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                _Checkbox(
                  isChecked: allSelected,
                  isPartial: someSelected,
                  color: parentColor,
                ),
                const SizedBox(width: AppSpacing.md),
                Icon(parent.icon, size: 18, color: parentColor),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    parent.name,
                    style: AppTypography.bodyMedium,
                  ),
                ),
                if (children.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedParents.remove(parent.id);
                        } else {
                          _expandedParents.add(parent.id);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Icon(
                        isExpanded
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (isExpanded && children.isNotEmpty)
          ...children.map((child) => _buildChildTile(child, colorIntensity)),
      ],
    );
  }

  Widget _buildChildTile(Category child, ColorIntensity colorIntensity) {
    final childColor = child.getColor(colorIntensity);
    final isSelected = _selectedIds.contains(child.id);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedIds.remove(child.id);
          } else {
            _selectedIds.add(child.id);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 36),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              _Checkbox(isChecked: isSelected, color: childColor),
              const SizedBox(width: AppSpacing.md),
              Icon(child.icon, size: 16, color: childColor),
              const SizedBox(width: AppSpacing.sm),
              Text(
                child.name,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  final bool isChecked;
  final bool isPartial;
  final Color color;

  const _Checkbox({
    required this.isChecked,
    this.isPartial = false,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: isChecked ? color.withOpacity(0.2) : Colors.transparent,
        borderRadius: AppRadius.xsAll,
        border: Border.all(
          color: isChecked || isPartial ? color : AppColors.border,
          width: 1.5,
        ),
      ),
      child: isChecked
          ? Icon(LucideIcons.check, size: 14, color: color)
          : isPartial
              ? Icon(LucideIcons.minus, size: 14, color: color)
              : null,
    );
  }
}
