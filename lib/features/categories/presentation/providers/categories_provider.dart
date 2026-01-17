import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/category.dart';

class CategoriesNotifier extends Notifier<List<Category>> {
  @override
  List<Category> build() {
    return DefaultCategories.all;
  }

  void addCategory(Category category) {
    state = [...state, category];
  }

  void updateCategory(Category category) {
    state = state.map((c) => c.id == category.id ? category : c).toList();
  }

  void deleteCategory(String id) {
    state = state.where((c) => c.id != id).toList();
  }

  Category? getById(String id) {
    try {
      return state.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
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
