import 'package:flutter/material.dart';

class FlowNode {
  final String id;
  final String label;
  final IconData? icon;
  final Color color;
  final double amount;
  final double percentage;

  const FlowNode({
    required this.id,
    required this.label,
    this.icon,
    required this.color,
    required this.amount,
    required this.percentage,
  });
}

class FlowConnection {
  final String sourceId;
  final String targetId;
  final double amount;

  const FlowConnection({
    required this.sourceId,
    required this.targetId,
    required this.amount,
  });
}

class AccountFlowData {
  final List<FlowNode> incomeNodes;
  final List<FlowNode> expenseNodes;
  final double totalIncome;
  final double totalExpense;

  const AccountFlowData({
    required this.incomeNodes,
    required this.expenseNodes,
    required this.totalIncome,
    required this.totalExpense,
  });

  bool get isEmpty => incomeNodes.isEmpty && expenseNodes.isEmpty;
}
