import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../design_system/components/buttons/fm_icon_button.dart';
import '../../../../design_system/components/chips/fm_toggle_chip.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/category_form_modal.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends ConsumerState<CategoryManagementScreen> {
  int _selectedTypeIndex = 1; // 0 = Income, 1 = Expense

  CategoryType get _selectedType =>
      _selectedTypeIndex == 0 ? CategoryType.income : CategoryType.expense;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final filteredCategories = categories
        .where((c) => c.type == _selectedType)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                      FMIconButton(
                        icon: LucideIcons.arrowLeft,
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text('Categories', style: AppTypography.h2),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Type toggle
                  Center(
                    child: FMToggleChip(
                      options: const ['Income', 'Expense'],
                      selectedIndex: _selectedTypeIndex,
                      colors: const [AppColors.income, AppColors.expense],
                      onChanged: (index) {
                        setState(() => _selectedTypeIndex = index);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),

            // Categories list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                itemCount: filteredCategories.length + 1, // +1 for add button
                itemBuilder: (context, index) {
                  if (index == filteredCategories.length) {
                    return _buildAddCategoryTile();
                  }
                  return _buildCategoryTile(filteredCategories[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(Category category) {
    return GestureDetector(
      onTap: category.isCustom ? () => _showEditModal(category) : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                category.icon,
                size: 20,
                color: category.color,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: AppTypography.bodyMedium,
                  ),
                  if (!category.isCustom) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Default',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (category.isCustom)
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: AppColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCategoryTile() {
    return GestureDetector(
      onTap: () => _showAddModal(),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xxl),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
          ),
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
              'Add Category',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddModal() {
    final animationsEnabled = ref.read(settingsProvider).formAnimationsEnabled;
    final modalContent = DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => CategoryFormModal(
        type: _selectedType,
        onSave: (name, icon, color) {
          final category = Category(
            id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
            name: name,
            icon: icon,
            color: color,
            type: _selectedType,
            isCustom: true,
          );
          ref.read(categoriesProvider.notifier).addCategory(category);
          Navigator.pop(context);
        },
      ),
    );

    if (!animationsEnabled) {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: Material(color: Colors.transparent, child: modalContent),
            );
          },
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => modalContent,
      );
    }
  }

  void _showEditModal(Category category) {
    final animationsEnabled = ref.read(settingsProvider).formAnimationsEnabled;
    final modalContent = DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => CategoryFormModal(
        category: category,
        type: category.type,
        onSave: (name, icon, color) {
          final updated = category.copyWith(
            name: name,
            icon: icon,
            color: color,
          );
          ref.read(categoriesProvider.notifier).updateCategory(updated);
          Navigator.pop(context);
        },
        onDelete: () {
          ref.read(categoriesProvider.notifier).deleteCategory(category.id);
          Navigator.pop(context);
        },
      ),
    );

    if (!animationsEnabled) {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) {
            return Align(
              alignment: Alignment.bottomCenter,
              child: Material(color: Colors.transparent, child: modalContent),
            );
          },
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => modalContent,
      );
    }
  }
}
