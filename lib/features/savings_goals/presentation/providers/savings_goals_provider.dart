import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

import '../../../../core/providers/database_providers.dart';
import '../../data/models/savings_goal.dart';

class SavingsGoalsNotifier extends AsyncNotifier<List<SavingsGoal>> {
  final _uuid = const Uuid();

  @override
  Future<List<SavingsGoal>> build() async {
    final repository = ref.watch(savingsGoalRepositoryProvider);
    return repository.getAllGoals();
  }

  Future<String> addGoal({
    required String name,
    required double targetAmount,
    double currentAmount = 0,
    required int colorIndex,
    IconData? icon,
    String? linkedAccountId,
    DateTime? targetDate,
    String? note,
  }) async {
    final repository = ref.read(savingsGoalRepositoryProvider);
    final id = _uuid.v4();

    final goal = SavingsGoal(
      id: id,
      name: name,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      colorIndex: colorIndex,
      icon: icon ?? const IconData(0xe4a5, fontFamily: 'lucide', fontPackage: 'lucide_icons'),
      linkedAccountId: linkedAccountId,
      targetDate: targetDate,
      note: note,
      createdAt: DateTime.now(),
    );

    await repository.createGoal(goal);
    ref.invalidateSelf();
    return id;
  }

  Future<void> updateGoal(SavingsGoal goal) async {
    final repository = ref.read(savingsGoalRepositoryProvider);
    await repository.updateGoal(goal);
    ref.invalidateSelf();
  }

  Future<void> deleteGoal(String id) async {
    final repository = ref.read(savingsGoalRepositoryProvider);
    await repository.deleteGoal(id);
    ref.invalidateSelf();
  }

  Future<void> contribute(String id, double amount) async {
    final goals = state.valueOrNull ?? [];
    final goal = goals.firstWhere((g) => g.id == id);
    await updateGoal(goal.copyWith(
      currentAmount: goal.currentAmount + amount,
    ));
  }
}

final savingsGoalsProvider =
    AsyncNotifierProvider<SavingsGoalsNotifier, List<SavingsGoal>>(
  SavingsGoalsNotifier.new,
);

/// Provider for a single goal by ID.
final savingsGoalByIdProvider =
    Provider.family<SavingsGoal?, String>((ref, id) {
  final goals = ref.watch(savingsGoalsProvider).valueOrNull ?? [];
  return goals.where((g) => g.id == id).firstOrNull;
});

/// Count of active (incomplete) savings goals.
final activeSavingsGoalsCountProvider = Provider<int>((ref) {
  final goals = ref.watch(savingsGoalsProvider).valueOrNull ?? [];
  return goals.where((g) => !g.isCompleted).length;
});
