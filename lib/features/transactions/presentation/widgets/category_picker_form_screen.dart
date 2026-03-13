import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../categories/data/models/category.dart';
import '../../../categories/presentation/providers/categories_provider.dart';
import '../../../settings/presentation/widgets/category_form_modal.dart';

/// A screen that wraps CategoryFormModal for picker mode.
class CategoryPickerFormScreen extends ConsumerWidget {
  final CategoryType type;
  final String? initialParentId;
  final ValueChanged<String> onCategoryCreated;

  const CategoryPickerFormScreen({
    super.key,
    required this.type,
    this.initialParentId,
    required this.onCategoryCreated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CategoryFormModal(
      type: type,
      initialParentId: initialParentId,
      onSave: (name, icon, colorIndex, parentId, showAssets) async {
        final uuid = const Uuid();
        final newId = uuid.v4();

        final category = Category(
          id: newId,
          name: name,
          icon: icon,
          colorIndex: colorIndex,
          type: type,
          parentId: parentId,
          isCustom: true,
          sortOrder: 0,
          showAssets: showAssets,
        );

        await ref.read(categoriesProvider.notifier).addCategory(category);
        onCategoryCreated(newId);
      },
    );
  }
}
