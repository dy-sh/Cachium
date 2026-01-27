import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/budget.dart';

class BudgetFormState {
  final String? categoryId;
  final double amount;
  final int year;
  final int month;
  final String? editingBudgetId;

  const BudgetFormState({
    this.categoryId,
    this.amount = 0,
    required this.year,
    required this.month,
    this.editingBudgetId,
  });

  bool get isValid => categoryId != null && amount > 0;
  bool get isEditing => editingBudgetId != null;

  BudgetFormState copyWith({
    String? categoryId,
    double? amount,
    int? year,
    int? month,
    String? editingBudgetId,
  }) {
    return BudgetFormState(
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      year: year ?? this.year,
      month: month ?? this.month,
      editingBudgetId: editingBudgetId ?? this.editingBudgetId,
    );
  }
}

class BudgetFormNotifier extends AutoDisposeNotifier<BudgetFormState> {
  @override
  BudgetFormState build() {
    final now = DateTime.now();
    return BudgetFormState(year: now.year, month: now.month);
  }

  void setCategoryId(String? id) => state = state.copyWith(categoryId: id);
  void setAmount(double amount) => state = state.copyWith(amount: amount);
  void setYear(int year) => state = state.copyWith(year: year);
  void setMonth(int month) => state = state.copyWith(month: month);

  void initForEdit(Budget budget) {
    state = BudgetFormState(
      categoryId: budget.categoryId,
      amount: budget.amount,
      year: budget.year,
      month: budget.month,
      editingBudgetId: budget.id,
    );
  }

  void reset() {
    final now = DateTime.now();
    state = BudgetFormState(year: now.year, month: now.month);
  }
}

final budgetFormProvider =
    AutoDisposeNotifierProvider<BudgetFormNotifier, BudgetFormState>(() {
  return BudgetFormNotifier();
});
