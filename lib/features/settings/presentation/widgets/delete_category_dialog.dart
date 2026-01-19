import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
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
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Delete "${category.name}"',
        style: AppTypography.h4,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This category has $childCount ${childCount == 1 ? 'subcategory' : 'subcategories'}. What would you like to do?',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
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
        TextButton(
          onPressed: () =>
              Navigator.pop(context, DeleteCategoryAction.promoteChildren),
          child: Text(
            'Promote Children',
            style: AppTypography.button.copyWith(
              color: AppColors.accentPrimary,
            ),
          ),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, DeleteCategoryAction.deleteAll),
          child: Text(
            'Delete All',
            style: AppTypography.button.copyWith(
              color: AppColors.expense,
            ),
          ),
        ),
      ],
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
