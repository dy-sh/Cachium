import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../categories/data/models/category.dart';

enum DeleteCategoryAction {
  promoteChildren,
  deleteAll,
  cancel,
}

class DeleteCategoryDialog extends StatelessWidget {
  final Category category;
  final int childCount;

  const DeleteCategoryDialog({
    super.key,
    required this.category,
    required this.childCount,
  });

  @override
  Widget build(BuildContext context) {
    final subcategoryText = childCount == 1 ? 'subcategory' : 'subcategories';

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Delete "${category.name}"?',
        style: AppTypography.h4,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This category has $childCount $subcategoryText. Choose what to do with them:',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Option 1: Keep subcategories
          _buildOption(
            context: context,
            icon: LucideIcons.arrowUp,
            iconColor: AppColors.accentPrimary,
            title: 'Keep Subcategories',
            description: 'Move $subcategoryText up one level and delete only "${category.name}"',
            action: DeleteCategoryAction.promoteChildren,
          ),

          const SizedBox(height: AppSpacing.md),

          // Option 2: Delete all
          _buildOption(
            context: context,
            icon: LucideIcons.trash2,
            iconColor: AppColors.expense,
            title: 'Delete Everything',
            description: 'Remove "${category.name}" and all its $subcategoryText',
            action: DeleteCategoryAction.deleteAll,
            isDanger: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, DeleteCategoryAction.cancel),
          child: Text(
            'Cancel',
            style: AppTypography.button.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required DeleteCategoryAction action,
    bool isDanger = false,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, action),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDanger
                ? AppColors.expense.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDanger ? AppColors.expense : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<DeleteCategoryAction?> showDeleteCategoryDialog({
  required BuildContext context,
  required Category category,
  required int childCount,
}) {
  return showDialog<DeleteCategoryAction>(
    context: context,
    builder: (context) => DeleteCategoryDialog(
      category: category,
      childCount: childCount,
    ),
  );
}

class SimpleDeleteConfirmationDialog extends StatelessWidget {
  final Category category;

  const SimpleDeleteConfirmationDialog({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Delete Category',
        style: AppTypography.h4,
      ),
      content: Text(
        'Are you sure you want to delete "${category.name}"? This action cannot be undone.',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: AppTypography.button.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            'Delete',
            style: AppTypography.button.copyWith(
              color: AppColors.expense,
            ),
          ),
        ),
      ],
    );
  }
}

Future<bool?> showSimpleDeleteConfirmationDialog({
  required BuildContext context,
  required Category category,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => SimpleDeleteConfirmationDialog(category: category),
  );
}
