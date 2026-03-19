import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../categories/data/models/category.dart';
import '../../../categories/data/models/category_tree_node.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../../core/providers/async_value_extensions.dart';
import '../widgets/delete_category_dialog.dart';
import '../widgets/category_transactions_reassign_dialog.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';

/// Handles the full category deletion flow:
/// 1. If category has children, asks what to do with them
/// 2. If any affected categories have transactions, shows reassign dialog
/// 3. Shows final confirmation
/// 4. Executes transaction decisions and deletes categories
///
/// Returns normally after the operation completes or is cancelled.
Future<void> handleCategoryDelete({
  required BuildContext context,
  required WidgetRef ref,
  required Category category,
}) async {
  final hasChildren = ref.read(hasChildrenProvider(category.id));
  List<String> categoryIdsToDelete = [category.id];
  bool promoteChildren = false;

  // Step 1: If category has children, ask what to do with them
  if (hasChildren) {
    final childCount = ref.read(childCategoriesProvider(category.id)).length;
    final action = await showDeleteCategoryDialog(
      context: context,
      category: category,
      childCount: childCount,
    );

    if (action == null || action == DeleteCategoryAction.cancel) {
      return;
    }

    if (action == DeleteCategoryAction.promoteChildren) {
      promoteChildren = true;
      categoryIdsToDelete = [category.id];
    } else if (action == DeleteCategoryAction.deleteAll) {
      final categories = ref.read(categoriesProvider).valueOrEmpty;
      final descendantIds = CategoryTreeBuilder.getDescendantIds(categories, category.id);
      categoryIdsToDelete = [category.id, ...descendantIds];
    }
  }

  // Step 2: Find categories with transactions
  final categoriesWithTransactions = <Category>[];
  for (final id in categoryIdsToDelete) {
    final txCount = ref.read(transactionCountByCategoryProvider(id));
    if (txCount > 0) {
      final cat = ref.read(categoryByIdProvider(id));
      if (cat != null) {
        categoriesWithTransactions.add(cat);
      }
    }
  }

  // Step 3: If any have transactions, show reassign screen
  List<CategoryTransactionDecision>? decisions;
  if (categoriesWithTransactions.isNotEmpty) {
    if (!context.mounted) return;
    decisions = await showCategoryTransactionsReassignDialog(
      context: context,
      categoriesToDelete: categoriesWithTransactions,
      categoryType: category.type,
    );

    if (!context.mounted) return;
    if (decisions == null) return; // Cancelled
  }

  // Step 4: Show final confirmation (as last step)
  if (!context.mounted) return;
  final confirmed = await showSimpleDeleteConfirmationDialog(
    context: context,
    category: category,
  );

  if (!context.mounted) return;
  if (confirmed != true) return;

  // Step 5: Execute transaction decisions if any
  if (decisions != null) {
    for (final decision in decisions) {
      if (decision.targetCategoryId != null && decision.targetCategoryId!.isNotEmpty) {
        await ref.read(transactionsProvider.notifier)
            .moveTransactionsToCategory(decision.categoryId, decision.targetCategoryId!);
      } else {
        await ref.read(transactionsProvider.notifier)
            .deleteTransactionsForCategory(decision.categoryId);
      }
    }
  }

  // Step 6: Delete categories
  if (promoteChildren) {
    ref.read(categoriesProvider.notifier).deleteCategoryPromotingChildren(category.id);
  } else if (categoryIdsToDelete.length > 1) {
    ref.read(categoriesProvider.notifier).deleteWithChildren(category.id);
  } else {
    ref.read(categoriesProvider.notifier).deleteCategory(category.id);
  }
}
