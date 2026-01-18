import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/crud_notifier.dart';
import '../../data/models/category.dart';

class CategoriesNotifier extends CrudNotifier<Category> {
  @override
  String getId(Category item) => item.id;

  @override
  List<Category> build() {
    return DefaultCategories.all;
  }

  void addCategory(Category category) => add(category);

  void updateCategory(Category category) => update(category);

  void deleteCategory(String id) => delete(id);
}

final categoriesProvider = NotifierProvider<CategoriesNotifier, List<Category>>(() {
  return CategoriesNotifier();
});

final incomeCategoriesProvider = Provider<List<Category>>((ref) {
  final categories = ref.watch(categoriesProvider);
  return categories.where((c) => c.type == CategoryType.income).toList();
});

final expenseCategoriesProvider = Provider<List<Category>>((ref) {
  final categories = ref.watch(categoriesProvider);
  return categories.where((c) => c.type == CategoryType.expense).toList();
});

final categoryByIdProvider = Provider.family<Category?, String>((ref, id) {
  final categories = ref.watch(categoriesProvider);
  try {
    return categories.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
});
